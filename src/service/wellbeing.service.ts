import { prisma } from "../utils/prisma";
import { UploadUsageInput, UpdateLimitInput } from "../validators/wellbeing.validator";
import { NotFoundError, ForbiddenError, BadRequestError } from "../utils/errors";
import { Role, RelationshipStatus } from "@prisma/client";

export class WellbeingService {
  static async uploadUsage(studentId: string, data: UploadUsageInput) {
    const usageDate = new Date(data.date);

    // Upsert Daily Device Usage
    const deviceUsage = await prisma.deviceUsage.upsert({
      where: {
        studentId_date: {
          studentId,
          date: usageDate,
        },
      },
      update: {
        screenTimeMinutes: data.screenTimeMinutes,
      },
      create: {
        studentId,
        date: usageDate,
        screenTimeMinutes: data.screenTimeMinutes,
      },
    });

    // Upsert App Usages
    if (data.apps && data.apps.length > 0) {
      // Create a transaction to handle multiple upserts reliably
      await prisma.$transaction(
        data.apps.map((app) =>
          prisma.appUsage.upsert({
            where: {
              studentId_date_appName: {
                studentId,
                date: usageDate,
                appName: app.appName,
              },
            },
            update: {
              usageMinutes: app.usageMinutes,
              ...(app.packageName ? { packageName: app.packageName } : {}),
            },
            create: {
              studentId,
              date: usageDate,
              appName: app.appName,
              packageName: app.packageName || null,
              usageMinutes: app.usageMinutes,
            },
          })
        )
      );
    }

    // Check against limits
    const limit = await prisma.wellbeingLimit.findUnique({
      where: { studentId },
    });

    let limitExceeded = false;
    let dailyLimitMinutes: number | undefined;

    if (limit && limit.enabled) {
      dailyLimitMinutes = limit.dailyScreenTimeMinutes;
      if (data.screenTimeMinutes > limit.dailyScreenTimeMinutes) {
        limitExceeded = true;
      }
    }

    return {
      date: data.date,
      screenTimeMinutes: data.screenTimeMinutes,
      dailyLimitMinutes,
      limitExceeded,
    };
  }

  static async getWellbeingMe(studentId: string) {
    // Get the most recent records
    const recentDeviceUsage = await prisma.deviceUsage.findFirst({
      where: { studentId },
      orderBy: { date: "desc" },
    });

    if (!recentDeviceUsage) {
      return null;
    }

    const apps = await prisma.appUsage.findMany({
      where: {
        studentId,
        date: recentDeviceUsage.date,
      },
    });

    const totalAppUsageMinutes = apps.reduce((sum, app) => sum + app.usageMinutes, 0);

    return {
      date: recentDeviceUsage.date.toISOString().split("T")[0],
      screenTimeMinutes: recentDeviceUsage.screenTimeMinutes,
      totalAppUsageMinutes,
      apps: apps.map(app => ({
        appName: app.appName,
        usageMinutes: app.usageMinutes,
      })),
    };
  }

  static async getWellbeingDaily(targetStudentId: string, requestUser: { id: string; role: Role }, requestedDate?: string) {
    await this.verifyAccess(targetStudentId, requestUser);

    let dateQuery: Date;
    if (requestedDate) {
      dateQuery = new Date(requestedDate);
    } else {
      const latest = await prisma.deviceUsage.findFirst({
        where: { studentId: targetStudentId },
        orderBy: { date: "desc" },
      });
      if (!latest) return null;
      dateQuery = latest.date;
    }

    const deviceUsage = await prisma.deviceUsage.findUnique({
      where: {
        studentId_date: {
          studentId: targetStudentId,
          date: dateQuery,
        },
      },
    });

    if (!deviceUsage) return null;

    const apps = await prisma.appUsage.findMany({
      where: {
        studentId: targetStudentId,
        date: dateQuery,
      },
    });

    return {
      studentId: targetStudentId,
      date: dateQuery.toISOString().split("T")[0],
      screenTimeMinutes: deviceUsage.screenTimeMinutes,
      apps: apps.map(app => ({
        appName: app.appName,
        usageMinutes: app.usageMinutes,
      })),
    };
  }

  static async getWellbeingWeekly(targetStudentId: string, requestUser: { id: string; role: Role }, startDateStr?: string, endDateStr?: string) {
    await this.verifyAccess(targetStudentId, requestUser);

    let endDate = endDateStr ? new Date(endDateStr) : new Date();
    let startDate = startDateStr ? new Date(startDateStr) : new Date(endDate.getTime() - 6 * 24 * 60 * 60 * 1000); // Default to last 7 days

    const deviceUsages = await prisma.deviceUsage.findMany({
      where: {
        studentId: targetStudentId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
    });

    if (deviceUsages.length === 0) return null;

    const totalScreenTimeMinutes = deviceUsages.reduce((sum, d) => sum + d.screenTimeMinutes, 0);
    const averageDailyScreenTimeMinutes = Math.round(totalScreenTimeMinutes / deviceUsages.length);

    const apps = await prisma.appUsage.findMany({
      where: {
        studentId: targetStudentId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
    });

    const appUsageMap: Record<string, number> = {};
    for (const app of apps) {
      if (!appUsageMap[app.appName]) appUsageMap[app.appName] = 0;
      appUsageMap[app.appName] += app.usageMinutes;
    }

    const topApps = Object.entries(appUsageMap)
      .map(([appName, usageMinutes]) => ({ appName, usageMinutes }))
      .sort((a, b) => b.usageMinutes - a.usageMinutes)
      .slice(0, 5); // Top 5 apps

    return {
      studentId: targetStudentId,
      totalScreenTimeMinutes,
      averageDailyScreenTimeMinutes,
      daysReported: deviceUsages.length,
      topApps,
    };
  }

  static async updateLimit(targetStudentId: string, parentId: string, data: UpdateLimitInput) {
    // Only PARENT role can access this, so parentId is the user ID.
    const relationship = await prisma.parentStudentRelationship.findFirst({
      where: {
        parentId,
        studentId: targetStudentId,
        status: RelationshipStatus.APPROVED,
      },
    });

    if (!relationship) {
      throw new ForbiddenError("You are not authorized to set limits for this student.");
    }

    return prisma.wellbeingLimit.upsert({
      where: { studentId: targetStudentId },
      update: {
        dailyScreenTimeMinutes: data.dailyScreenTimeMinutes,
        ...(data.enabled !== undefined ? { enabled: data.enabled } : {}),
      },
      create: {
        studentId: targetStudentId,
        dailyScreenTimeMinutes: data.dailyScreenTimeMinutes,
        enabled: data.enabled ?? true,
      },
    });
  }

  static async getLimit(targetStudentId: string, requestUser: { id: string; role: Role }) {
    await this.verifyAccess(targetStudentId, requestUser);

    const limit = await prisma.wellbeingLimit.findUnique({
      where: { studentId: targetStudentId },
    });

    if (!limit) return null;

    return {
      studentId: limit.studentId,
      dailyScreenTimeMinutes: limit.dailyScreenTimeMinutes,
      enabled: limit.enabled,
    };
  }

  private static async verifyAccess(targetStudentId: string, user: { id: string; role: Role }) {
    if (user.role === Role.ADMIN) return true;

    if (user.role === Role.STUDENT) {
      if (user.id !== targetStudentId) {
        throw new ForbiddenError("You can only view your own wellbeing data.");
      }
      return true;
    }

    if (user.role === Role.PARENT) {
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: {
          parentId: user.id,
          studentId: targetStudentId,
          status: RelationshipStatus.APPROVED,
        },
      });

      if (!relationship) {
        throw new ForbiddenError("You are not authorized to view wellbeing data for this student.");
      }
      return true;
    }

    // Default deny for teachers or others
    throw new ForbiddenError("You are not authorized to access wellbeing data.");
  }
}
