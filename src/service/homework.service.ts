import { prisma } from "../utils/prisma";
import { CreateHomeworkInput, UpdateHomeworkInput } from "../validators/homework.validator";
import { NotFoundError, ForbiddenError, BadRequestError } from "../utils/errors";
import { Role, RelationshipStatus } from "@prisma/client";

export class HomeworkService {
  static async createHomework(teacherId: string, data: CreateHomeworkInput) {
    let targetClass = await prisma.class.findUnique({
      where: { id: data.classId },
    });

    if (!targetClass) {
      targetClass = await prisma.class.findFirst({
        where: {
          OR: [
            { id: data.classId },
            { section: data.classId }
          ]
        }
      });
    }

    if (!targetClass) {
      throw new BadRequestError("Target class does not exist.");
    }

    const classId = targetClass.id;

    const assignment = await prisma.teacherClassSubject.findFirst({
      where: {
        teacherId,
        classId,
      },
    });

    const teacherUser = await prisma.user.findUnique({
      where: { id: teacherId },
    });

    if (!assignment && teacherUser?.role !== Role.ADMIN && teacherUser?.role !== Role.TEACHER) {
      throw new ForbiddenError("You are not authorized to create homework for this class.");
    }

    return prisma.homework.create({
      data: {
        teacherId,
        classId,
        subject: data.subject,
        title: data.title,
        description: data.description,
        dueDate: new Date(data.dueDate),
      },
      include: {
        class: true,
      },
    });
  }

  static async getHomeworkById(id: string, user: { id: string; role: Role }) {
    const homework = await prisma.homework.findUnique({
      where: { id },
      include: { class: true },
    });

    if (!homework) {
      throw new NotFoundError("Homework not found.");
    }

    if (user.role === Role.STUDENT) {
      const isEnrolled = await prisma.studentClass.findFirst({
        where: { studentId: user.id, classId: homework.classId },
      });
      if (!isEnrolled) {
        throw new ForbiddenError("You can only view homework assigned to your classes.");
      }
    }

    if (user.role === Role.PARENT) {
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: {
          parentId: user.id,
          status: RelationshipStatus.APPROVED,
          student: {
            studentClasses: {
              some: { classId: homework.classId }
            }
          }
        },
      });

      if (!relationship) {
        throw new ForbiddenError("You are not authorized to view this homework.");
      }
    }

    return homework;
  }

  static async getHomeworksByStudentId(targetStudentId: string, user: { id: string; role: Role }) {
    // Find matching student by internal id or studentId code
    const student = await prisma.user.findFirst({
      where: {
        OR: [
          { id: targetStudentId },
          { studentId: targetStudentId }
        ]
      },
      select: { id: true }
    });

    const resolvedStudentId = student ? student.id : targetStudentId;

    // Get all class IDs where this student is enrolled
    const studentClasses = await prisma.studentClass.findMany({
      where: { studentId: resolvedStudentId },
      select: { classId: true }
    });

    const classIds = studentClasses.map(sc => sc.classId);

    return prisma.homework.findMany({
      where: {
        OR: [
          { classId: { in: classIds.length > 0 ? classIds : ["__none__"] } },
          { classId: targetStudentId }
        ]
      },
      include: {
        class: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  static async getHomeworksByClassId(classId: string) {
    return prisma.homework.findMany({
      where: { classId },
      include: {
        class: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  static async getHomeworksByTeacher(teacherId: string) {
    return prisma.homework.findMany({
      where: { teacherId },
      include: {
        class: true,
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Returns all homework for the classes a student is enrolled in.
   * Called by the student's own "GET /homework/student/me" endpoint.
   */
  static async getMyHomework(studentId: string) {
    // Find all class IDs where this student is enrolled
    const enrollments = await prisma.studentClass.findMany({
      where: { studentId },
      select: { classId: true },
    });

    const classIds = enrollments.map((e) => e.classId);

    if (classIds.length === 0) return [];

    return prisma.homework.findMany({
      where: { classId: { in: classIds } },
      include: { class: true },
      orderBy: { createdAt: "desc" },
    });
  }

  static async updateHomework(id: string, teacherId: string, data: UpdateHomeworkInput) {
    const homework = await prisma.homework.findUnique({
      where: { id },
    });

    if (!homework) {
      throw new NotFoundError("Homework not found.");
    }

    if (homework.teacherId !== teacherId) {
      throw new ForbiddenError("You can only update your own homework.");
    }

    const updateData: any = {};
    if (data.subject !== undefined) updateData.subject = data.subject;
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.dueDate !== undefined) updateData.dueDate = new Date(data.dueDate);

    return prisma.homework.update({
      where: { id },
      data: updateData,
      include: {
        class: true,
      },
    });
  }

  static async deleteHomework(id: string, teacherId: string) {
    const homework = await prisma.homework.findUnique({
      where: { id },
    });

    if (!homework) {
      throw new NotFoundError("Homework not found.");
    }

    if (homework.teacherId !== teacherId) {
      throw new ForbiddenError("You can only delete your own homework.");
    }

    return prisma.homework.delete({
      where: { id },
    });
  }
}
