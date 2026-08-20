import { prisma } from "../utils/prisma";
import { CreateTeacherNoteInput, UpdateTeacherNoteInput } from "../validators/teacherNote.validator";
import { NotFoundError, ForbiddenError, BadRequestError } from "../utils/errors";
import { Role, RelationshipStatus } from "@prisma/client";

export class TeacherNoteService {
  static async createTeacherNote(teacherId: string, data: CreateTeacherNoteInput) {
    const student = await prisma.user.findUnique({
      where: { id: data.studentId },
    });

    if (!student || student.role !== Role.STUDENT) {
      throw new BadRequestError("Target user is not a valid student.");
    }

    const assignment = await prisma.teacherClassSubject.findFirst({
      where: {
        teacherId,
        class: {
          students: {
            some: { studentId: data.studentId }
          }
        }
      },
    });

    if (!assignment) {
      throw new ForbiddenError("You are not assigned to teach this student.");
    }

    return prisma.teacherNote.create({
      data: {
        teacherId,
        studentId: data.studentId,
        title: data.title,
        content: data.content,
      },
    });
  }

  static async getTeacherNoteById(id: string, user: { id: string; role: Role }) {
    const note = await prisma.teacherNote.findUnique({
      where: { id },
    });

    if (!note) {
      throw new NotFoundError("Teacher note not found.");
    }

    if (user.role === Role.STUDENT && note.studentId !== user.id) {
      throw new ForbiddenError("You can only view notes written about you.");
    }

    if (user.role === Role.PARENT) {
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: {
          parentId: user.id,
          studentId: note.studentId,
          status: RelationshipStatus.APPROVED,
        },
      });

      if (!relationship) {
        throw new ForbiddenError("You are not authorized to view notes for this student.");
      }
    }

    return note;
  }

  static async getTeacherNotesByStudentId(targetStudentId: string, user: { id: string; role: Role }) {
    if (user.role === Role.STUDENT && user.id !== targetStudentId) {
      throw new ForbiddenError("You can only view notes written about you.");
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
        throw new ForbiddenError("You are not authorized to view notes for this student.");
      }
    }

    return prisma.teacherNote.findMany({
      where: { studentId: targetStudentId },
      orderBy: { createdAt: "desc" },
    });
  }

  static async getTeacherNotesByTeacher(teacherId: string) {
    return prisma.teacherNote.findMany({
      where: { teacherId },
      orderBy: { createdAt: "desc" },
    });
  }

  static async updateTeacherNote(id: string, teacherId: string, data: UpdateTeacherNoteInput) {
    const note = await prisma.teacherNote.findUnique({
      where: { id },
    });

    if (!note) {
      throw new NotFoundError("Teacher note not found.");
    }

    if (note.teacherId !== teacherId) {
      throw new ForbiddenError("You can only update your own notes.");
    }

    const updateData: any = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.content !== undefined) updateData.content = data.content;

    return prisma.teacherNote.update({
      where: { id },
      data: updateData,
    });
  }

  static async deleteTeacherNote(id: string, teacherId: string) {
    const note = await prisma.teacherNote.findUnique({
      where: { id },
    });

    if (!note) {
      throw new NotFoundError("Teacher note not found.");
    }

    if (note.teacherId !== teacherId) {
      throw new ForbiddenError("You can only delete your own notes.");
    }

    return prisma.teacherNote.delete({
      where: { id },
    });
  }
}
