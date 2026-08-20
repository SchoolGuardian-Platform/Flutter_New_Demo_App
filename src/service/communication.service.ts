import { prisma } from "../utils/prisma";
import { RelationshipStatus } from "@prisma/client";

export class CommunicationService {
  /**
   * Retrieves all teachers assigned to a specific student.
   * Useful for parents or the student to discover their teachers.
   */
  static async getStudentTeachers(studentId: string) {
    const classes = await prisma.studentClass.findMany({
      where: { studentId },
      include: {
        class: {
          include: {
            teachers: {
              include: {
                teacher: {
                  select: {
                    id: true,
                    firstName: true,
                    middleName: true,
                    lastName: true,
                    email: true,
                    role: true,
                  },
                },
                subject: {
                  select: {
                    id: true,
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    const teacherMap = new Map();
    for (const c of classes) {
      for (const t of c.class.teachers) {
        teacherMap.set(t.teacher.id, {
          ...t.teacher,
          subject: t.subject?.name ?? "Subject Teacher",
        });
      }
    }

    // Fallback: If no explicit TeacherClassSubject entries exist for student's classes, return all DB teachers
    if (teacherMap.size === 0) {
      const allTeachers = await prisma.user.findMany({
        where: { role: "TEACHER" },
        select: {
          id: true,
          firstName: true,
          middleName: true,
          lastName: true,
          email: true,
          role: true,
        },
      });
      for (const t of allTeachers) {
        teacherMap.set(t.id, {
          ...t,
          subject: "Subject Teacher",
        });
      }
    }

    return Array.from(teacherMap.values());
  }

  /**
   * Resolves a student's record by school studentId, internal UUID, or name.
   * Flexible lookup for teachers to find student and linked parents.
   */
  static async lookupStudentBySchoolId(query: string) {
    const trimmed = query.trim();
    const student = await prisma.user.findFirst({
      where: {
        OR: [
          { studentId: { equals: trimmed, mode: "insensitive" } },
          { id: trimmed },
          { firstName: { contains: trimmed, mode: "insensitive" } },
          { lastName: { contains: trimmed, mode: "insensitive" } },
        ],
      },
      select: {
        id: true,
        studentId: true,
        firstName: true,
        middleName: true,
        lastName: true,
        email: true,
        role: true,
      },
    });
    return student;
  }

  /**
   * Retrieves all approved parents/guardians linked to a specific student.
   * Useful for teachers to discover parent contact information.
   */
  static async getStudentParents(studentId: string) {
    const relationships = await prisma.parentStudentRelationship.findMany({
      where: {
        studentId,
        status: RelationshipStatus.APPROVED,
      },
      include: {
        parent: {
          select: {
            id: true,
            firstName: true,
            middleName: true,
            lastName: true,
            email: true,
            role: true,
            fcmToken: true,
          },
        },
      },
    });

    return relationships.map(r => ({
      ...r.parent,
      relationshipType: r.relationshipType,
    }));
  }

  /**
   * Retrieves all students in classes the given teacher teaches.
   * Uses teacher's assigned classes, or fallbacks to all DB students if no class links exist.
   * Optionally filters by a search query (matches studentId, firstName, lastName).
   */
  static async getTeacherStudents(teacherId: string, query?: string) {
    const teacherClasses = await prisma.teacherClassSubject.findMany({
      where: { teacherId },
      select: { classId: true },
    });

    const classIds = [...new Set(teacherClasses.map(tc => tc.classId))];

    let studentClasses: any[] = [];
    if (classIds.length > 0) {
      studentClasses = await prisma.studentClass.findMany({
        where: { classId: { in: classIds } },
        include: {
          student: {
            select: {
              id: true,
              studentId: true,
              firstName: true,
              middleName: true,
              lastName: true,
              email: true,
            },
          },
          class: {
            select: { grade: true, section: true },
          },
        },
      });
    }

    const studentMap = new Map<string, any>();
    for (const sc of studentClasses) {
      if (sc.student && !studentMap.has(sc.student.id)) {
        studentMap.set(sc.student.id, {
          ...sc.student,
          className: `Grade ${sc.class?.grade ?? ''} - ${sc.class?.section ?? ''}`,
        });
      }
    }

    // Fallback: If teacher has no specific class assignment records in DB yet, fetch all enrolled students
    if (studentMap.size === 0) {
      const allStudents = await prisma.user.findMany({
        where: { role: "STUDENT" },
        select: {
          id: true,
          studentId: true,
          firstName: true,
          middleName: true,
          lastName: true,
          email: true,
          studentClasses: {
            include: {
              class: { select: { grade: true, section: true } },
            },
          },
        },
      });

      for (const s of allStudents) {
        const clsName = s.studentClasses && s.studentClasses.length > 0
          ? `Grade ${s.studentClasses[0].class.grade} - ${s.studentClasses[0].class.section}`
          : "Enrolled";
        studentMap.set(s.id, {
          id: s.id,
          studentId: s.studentId,
          firstName: s.firstName,
          middleName: s.middleName,
          lastName: s.lastName,
          email: s.email,
          className: clsName,
        });
      }
    }

    let students = Array.from(studentMap.values());

    if (query && query.trim().length > 0) {
      const q = query.trim().toLowerCase();
      students = students.filter(s =>
        (s.studentId ?? "").toLowerCase().includes(q) ||
        s.firstName.toLowerCase().includes(q) ||
        s.lastName.toLowerCase().includes(q)
      );
    }

    return students;
  }
}
