import { prisma } from "../utils/prisma";
import { CreateClassInput, CreateSubjectInput, AssignStudentInput, AssignTeacherInput } from "../validators/schoolManagement.validator";
import { BadRequestError, NotFoundError } from "../utils/errors";
import { Role } from "@prisma/client";

export class SchoolManagementService {
  static async getClasses() {
    return prisma.class.findMany({
      include: {
        students: {
          include: {
            student: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                studentId: true,
              },
            },
          },
        },
        teachers: {
          include: {
            teacher: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
              },
            },
            subject: true,
          },
        },
      },
      orderBy: [{ grade: "asc" }, { section: "asc" }],
    });
  }

  static async getSubjects() {
    return prisma.subject.findMany({
      orderBy: { name: "asc" },
    });
  }

  static async createClass(data: CreateClassInput) {
    const existingClass = await prisma.class.findUnique({
      where: {
        grade_section: {
          grade: data.grade,
          section: data.section,
        },
      },
    });

    if (existingClass) {
      return existingClass;
    }

    return prisma.class.create({
      data: {
        grade: data.grade,
        section: data.section,
      },
    });
  }

  static async createSubject(data: CreateSubjectInput) {
    const existingSubject = await prisma.subject.findUnique({
      where: {
        name: data.name,
      },
    });

    if (existingSubject) {
      return existingSubject;
    }

    return prisma.subject.create({
      data: {
        name: data.name,
      },
    });
  }

  static async deleteClass(id: string) {
    const cls = await prisma.class.findUnique({ where: { id } });
    if (!cls) {
      throw new NotFoundError("Class not found.");
    }
    return prisma.class.delete({ where: { id } });
  }

  static async deleteSubject(id: string) {
    const subject = await prisma.subject.findUnique({ where: { id } });
    if (!subject) {
      throw new NotFoundError("Subject not found.");
    }
    return prisma.subject.delete({ where: { id } });
  }

  static async assignStudentToClass(data: AssignStudentInput) {
    const student = await prisma.user.findFirst({
      where: {
        OR: [
          { id: data.studentId },
          { studentId: data.studentId },
          { email: data.studentId }
        ]
      }
    });
    if (!student || student.role !== Role.STUDENT) {
      throw new BadRequestError("Invalid student.");
    }

    const cls = await prisma.class.findUnique({
      where: { id: data.classId },
    });
    if (!cls) {
      throw new NotFoundError("Class not found.");
    }

    // Check if already assigned
    const existingAssignment = await prisma.studentClass.findUnique({
      where: {
        studentId_classId: {
          studentId: student.id,
          classId: data.classId,
        },
      },
    });

    if (existingAssignment) {
      return existingAssignment;
    }

    return prisma.studentClass.create({
      data: {
        studentId: student.id,
        classId: data.classId,
        academicYear: data.academicYear,
      },
      include: {
        class: true,
        student: { select: { id: true, firstName: true, lastName: true, studentId: true } },
      },
    });
  }

  static async deleteStudentAssignment(id: string) {
    let assignment = await prisma.studentClass.findUnique({ where: { id } });
    if (!assignment) {
      assignment = await prisma.studentClass.findFirst({
        where: {
          OR: [
            { studentId: id },
            { student: { studentId: id } }
          ]
        }
      });
    }
    if (!assignment) {
      throw new NotFoundError("Student assignment not found.");
    }
    return prisma.studentClass.delete({ where: { id: assignment.id } });
  }

  static async assignTeacherToClass(data: AssignTeacherInput) {
    let teacher = await prisma.user.findUnique({
      where: { id: data.teacherId },
    });
    if (!teacher) {
      teacher = await prisma.user.findFirst({
        where: {
          OR: [
            { email: data.teacherId },
            { id: data.teacherId }
          ]
        }
      });
    }
    if (!teacher || teacher.role !== Role.TEACHER) {
      throw new BadRequestError("Invalid teacher.");
    }

    const cls = await prisma.class.findUnique({
      where: { id: data.classId },
    });
    if (!cls) {
      throw new NotFoundError("Class not found.");
    }

    const subject = await prisma.subject.findUnique({
      where: { id: data.subjectId },
    });
    if (!subject) {
      throw new NotFoundError("Subject not found.");
    }

    // Check if already assigned
    const existingAssignment = await prisma.teacherClassSubject.findUnique({
      where: {
        teacherId_classId_subjectId: {
          teacherId: teacher.id,
          classId: data.classId,
          subjectId: data.subjectId,
        },
      },
    });

    if (existingAssignment) {
      return existingAssignment;
    }

    return prisma.teacherClassSubject.create({
      data: {
        teacherId: teacher.id,
        classId: data.classId,
        subjectId: data.subjectId,
        academicYear: data.academicYear,
      },
      include: {
        class: true,
        subject: true,
        teacher: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  static async deleteTeacherAssignment(id: string) {
    let assignment = await prisma.teacherClassSubject.findUnique({ where: { id } });
    if (!assignment) {
      assignment = await prisma.teacherClassSubject.findFirst({
        where: {
          OR: [
            { teacherId: id },
            { subjectId: id },
            { classId: id }
          ]
        }
      });
    }
    if (!assignment) {
      throw new NotFoundError("Teacher assignment not found.");
    }
    return prisma.teacherClassSubject.delete({ where: { id: assignment.id } });
  }
}
