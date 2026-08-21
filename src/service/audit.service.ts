import { AuditAction } from "@prisma/client";

import { prisma } from "../utils/prisma";
export interface LogAuditParams{
    userId?: string;
    action: AuditAction;
    ipAddress?: string;
    userAgent?: string;
    details?: string;
}

export async function createAuditLog(params: LogAuditParams): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        userId: params.userId || null,
        action: params.action,
        ipAddress: params.ipAddress || null,
        userAgent: params.userAgent || null,
        details: params.details || null,
      },
    });
  } catch (error) {
    // We catch audit logging errors so database audit failures do not crash main requests
    console.error("Failed to write audit log:", error);
  }
}

export async function getAuditLogs(limit: number = 50, offset: number = 0, action?: AuditAction, userId?: string) {
  const whereClause: any = {};
  if (action) whereClause.action = action;
  if (userId) whereClause.userId = userId;

  const logs = await prisma.auditLog.findMany({
    where: whereClause,
    orderBy: { createdAt: "desc" },
    take: limit,
    skip: offset,
    include: {
      user: {
        select: {
          email: true,
          firstName: true,
          lastName: true,
          role: true,
        }
      }
    }
  });

  const total = await prisma.auditLog.count({ where: whereClause });

  return {
    data: logs,
    meta: {
      total,
      limit,
      offset,
    }
  };
}