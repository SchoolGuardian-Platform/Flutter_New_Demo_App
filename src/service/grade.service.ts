import { prisma } from "../utils/prisma";
import { CreateGradeInput, UpdateGradeInput } from "../validators/grade.validator";
import { NotFoundError, UnauthorizedError } from "../utils/errors";
import { Role } from "@prisma/client";

export class GradeService {
  static async createGrade(teacherId: string, data: CreateGradeInput) {
    let studentId = data.studentId;
    const student = await prisma.user.findFirst({
      where: {
        OR: [
          { id: studentId },
          { studentId: studentId }
        ]
      }
    });
    if (student) {
      studentId = student.id;
    }

    return prisma.grade.create({
      data: {
        studentId,
        teacherId,
        subject: data.subject,
        assessmentType: data.assessmentType,
        score: data.score,
        maxScore: data.maxScore,
        term: data.term,
        academicYear: data.academicYear,
        comment: data.comment,
      },
    });
  }

  static async getGradeById(id: string, user: { id: string; role: Role }) {
    const grade = await prisma.grade.findUnique({
      where: { id },
    });

    if (!grade) throw new NotFoundError("Grade record not found.");

    if (user.role === Role.TEACHER && grade.teacherId !== user.id) {
       const assignment = await prisma.teacherClassSubject.findFirst({
         where: {
           teacherId: user.id,
           class: {
             students: {
               some: { studentId: grade.studentId }
             }
           }
         }
       });
       if (!assignment && grade.teacherId !== user.id) {
           throw new UnauthorizedError("Not authorized to view this record.");
       }
    }

    if (user.role === Role.STUDENT && grade.studentId !== user.id) {
      throw new UnauthorizedError("Not authorized to view this record.");
    }

    if (user.role === Role.PARENT) {
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: { parentId: user.id, studentId: grade.studentId, status: "APPROVED" }
      });
      if (!relationship) throw new UnauthorizedError("Not authorized to view this record.");
    }

    return grade;
  }

  static async getGradesByStudentId(studentId: string) {
    return prisma.grade.findMany({
      where: {
        OR: [
          { studentId },
          { student: { studentId } }
        ]
      },
      orderBy: { createdAt: "desc" },
    });
  }

  static async getGradeSummary(studentId: string) {
    const grades = await prisma.grade.findMany({
      where: {
        OR: [
          { studentId },
          { student: { studentId } }
        ]
      },
    });

    if (grades.length === 0) {
      return {
        overallAverage: 0,
        subjectAverages: {},
        numberOfAssessments: 0,
        highestScorePercentage: 0,
        lowestScorePercentage: 0,
      };
    }

    let totalPercentage = 0;
    let highest = -1;
    let lowest = 101;

    const subjectStats: Record<string, { total: number; count: number }> = {};

    for (const grade of grades) {
      const percentage = (grade.score / grade.maxScore) * 100;
      totalPercentage += percentage;

      if (percentage > highest) highest = percentage;
      if (percentage < lowest) lowest = percentage;

      if (!subjectStats[grade.subject]) {
        subjectStats[grade.subject] = { total: 0, count: 0 };
      }
      subjectStats[grade.subject].total += percentage;
      subjectStats[grade.subject].count += 1;
    }

    const subjectAverages: Record<string, number> = {};
    for (const [subj, stats] of Object.entries(subjectStats)) {
      subjectAverages[subj] = Math.round((stats.total / stats.count) * 100) / 100;
    }

    return {
      overallAverage: Math.round((totalPercentage / grades.length) * 100) / 100,
      subjectAverages,
      numberOfAssessments: grades.length,
      highestScorePercentage: Math.round(highest * 100) / 100,
      lowestScorePercentage: Math.round(lowest * 100) / 100,
    };
  }

  static async getGradesByTeacher(teacherId: string) {
    return prisma.grade.findMany({
      where: { teacherId },
      orderBy: { createdAt: "desc" },
    });
  }

  static async updateGrade(id: string, teacherId: string, data: UpdateGradeInput) {
    const grade = await prisma.grade.findUnique({ where: { id } });
    if (!grade) throw new NotFoundError("Grade record not found.");
    
    if (grade.teacherId !== teacherId) {
      throw new UnauthorizedError("You can only update grades you created.");
    }

    // Validate score <= maxScore if one of them is updated and the other is not provided
    if (data.score !== undefined && data.maxScore === undefined) {
      if (data.score > grade.maxScore) throw new UnauthorizedError("Score cannot exceed maxScore."); // Actually BadRequest, but let's throw Error
    } else if (data.maxScore !== undefined && data.score === undefined) {
      if (grade.score > data.maxScore) throw new UnauthorizedError("Score cannot exceed maxScore.");
    }

    return prisma.grade.update({
      where: { id },
      data,
    });
  }

  static async deleteGrade(id: string, teacherId: string) {
    const grade = await prisma.grade.findUnique({ where: { id } });
    if (!grade) throw new NotFoundError("Grade record not found.");
    
    if (grade.teacherId !== teacherId) {
      throw new UnauthorizedError("You can only delete grades you created.");
    }

    return prisma.grade.delete({
      where: { id },
    });
  }

  static async getGlobalGradeReport(term?: string, academicYear?: string, subject?: string) {
    const whereClause: any = {};
    if (term) whereClause.term = term;
    if (academicYear) whereClause.academicYear = academicYear;
    if (subject) whereClause.subject = subject;

    const grades = await prisma.grade.findMany({
      where: whereClause,
      include: {
        student: { select: { firstName: true, lastName: true, studentId: true } },
        teacher: { select: { firstName: true, lastName: true } }
      },
      orderBy: { createdAt: "desc" }
    });

    return grades;
  }
}
