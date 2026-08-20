import { prisma } from "../utils/prisma";
import { CreateAttendanceInput, UpdateAttendanceInput } from "../validators/attendance.validator";
import { NotFoundError, UnauthorizedError, BadRequestError } from "../utils/errors";
import { Role } from "@prisma/client";

export class AttendanceService {
  static async createAttendance(teacherId: string, data: CreateAttendanceInput) {
    const dateObj = new Date(data.date);
    if (isNaN(dateObj.getTime())) {
      throw new BadRequestError("Invalid date.");
    }

    // Check if attendance already exists for this student on this date
    const existing = await prisma.attendance.findUnique({
      where: {
        studentId_date: {
          studentId: data.studentId,
          date: dateObj,
        },
      },
    });

    if (existing) {
      throw new BadRequestError("Attendance already recorded for this student on this date.");
    }

    return prisma.attendance.create({
      data: {
        studentId: data.studentId,
        teacherId,
        date: dateObj,
        status: data.status,
        note: data.note,
      },
    });
  }

  static async getAttendanceById(id: string, user: { id: string; role: Role }) {
    const attendance = await prisma.attendance.findUnique({
      where: { id },
    });

    if (!attendance) {
      throw new NotFoundError("Attendance record not found.");
    }

    // Role checks for single record
    if (user.role === Role.TEACHER && attendance.teacherId !== user.id) {
       // Is the teacher allowed if they didn't create it? 
       // Requirement: "Teachers can update/delete their own attendance records" but doesn't explicitly restrict viewing.
       // However, we can restrict viewing to only their own for safety, or rely on Class mapping.
       const assignment = await prisma.teacherClassSubject.findFirst({
         where: {
           teacherId: user.id,
           class: {
             students: {
               some: { studentId: attendance.studentId }
             }
           }
         }
       });
       if (!assignment && attendance.teacherId !== user.id) {
           throw new UnauthorizedError("Not authorized to view this record.");
       }
    }

    if (user.role === Role.STUDENT && attendance.studentId !== user.id) {
      throw new UnauthorizedError("Not authorized to view this record.");
    }

    if (user.role === Role.PARENT) {
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: { parentId: user.id, studentId: attendance.studentId, status: "APPROVED" }
      });
      if (!relationship) throw new UnauthorizedError("Not authorized to view this record.");
    }

    return attendance;
  }

  static async getAttendanceByStudentId(studentId: string) {
    return prisma.attendance.findMany({
      where: {
        OR: [
          { studentId },
          { student: { studentId } }
        ]
      },
      orderBy: { date: "desc" },
    });
  }

  static async getAttendanceSummary(studentId: string) {
    const records = await prisma.attendance.findMany({
      where: {
        OR: [
          { studentId },
          { student: { studentId } }
        ]
      },
    });

    const totalDays = records.length;
    let present = 0;
    let absent = 0;
    let late = 0;
    let excused = 0;

    for (const record of records) {
      switch (record.status) {
        case "PRESENT": present++; break;
        case "ABSENT": absent++; break;
        case "LATE": late++; break;
        case "EXCUSED": excused++; break;
      }
    }

    const attendancePercentage = totalDays === 0 ? 0 : ((present + late) / totalDays) * 100;

    return {
      totalDays,
      present,
      absent,
      late,
      excused,
      attendancePercentage: Math.round(attendancePercentage * 100) / 100,
    };
  }

  static async getAttendanceByTeacher(teacherId: string) {
    return prisma.attendance.findMany({
      where: { teacherId },
      orderBy: { date: "desc" },
    });
  }

  static async updateAttendance(id: string, teacherId: string, data: UpdateAttendanceInput) {
    const attendance = await prisma.attendance.findUnique({ where: { id } });
    if (!attendance) throw new NotFoundError("Attendance record not found.");
    
    if (attendance.teacherId !== teacherId) {
      throw new UnauthorizedError("You can only update attendance records you created.");
    }

    return prisma.attendance.update({
      where: { id },
      data,
    });
  }

  static async deleteAttendance(id: string, teacherId: string) {
    const attendance = await prisma.attendance.findUnique({ where: { id } });
    if (!attendance) throw new NotFoundError("Attendance record not found.");
    
    if (attendance.teacherId !== teacherId) {
      throw new UnauthorizedError("You can only delete attendance records you created.");
    }

    return prisma.attendance.delete({
      where: { id },
    });
  }

  static async getGlobalAttendanceReport(startDate?: string, endDate?: string) {
    const whereClause: any = {};
    if (startDate && endDate) {
      whereClause.date = {
        gte: new Date(startDate),
        lte: new Date(endDate),
      };
    } else if (startDate) {
      whereClause.date = { gte: new Date(startDate) };
    } else if (endDate) {
      whereClause.date = { lte: new Date(endDate) };
    }

    const records = await prisma.attendance.findMany({
      where: whereClause,
      include: {
        student: {
          select: { firstName: true, lastName: true, studentId: true }
        },
        teacher: {
          select: { firstName: true, lastName: true }
        }
      },
      orderBy: { date: "desc" }
    });

    return records;
  }
}
