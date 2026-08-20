import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { Role } from "@prisma/client";
import { generateAccessToken } from "../src/utils/jwt";

describe("Teacher Notes API", () => {
  jest.setTimeout(30000);

  let teacherId: string;
  let otherTeacherId: string;
  let studentId: string;
  let unrelatedStudentId: string;
  let parentId: string;

  let teacherToken: string;
  let otherTeacherToken: string;
  let studentToken: string;
  let parentToken: string;

  let noteId: string;

  beforeAll(async () => {
    // Create Teacher
    const teacher = await prisma.user.create({
      data: {
        email: "tn_teacher@test.com",
        firstName: "Teacher",
        middleName: "A",
        lastName: "NoteOne",
        passwordHash: "hash",
        phoneNumber: "1111111111",
        gender: "FEMALE",
        role: Role.TEACHER,
        status: "ACTIVE",
      },
    });
    teacherId = teacher.id;
    teacherToken = generateAccessToken(teacher.id, Role.TEACHER);

    // Create Other Teacher
    const otherTeacher = await prisma.user.create({
      data: {
        email: "tn_other_teacher@test.com",
        firstName: "Teacher",
        middleName: "B",
        lastName: "NoteTwo",
        passwordHash: "hash",
        phoneNumber: "2222222222",
        gender: "MALE",
        role: Role.TEACHER,
        status: "ACTIVE",
      },
    });
    otherTeacherId = otherTeacher.id;
    otherTeacherToken = generateAccessToken(otherTeacher.id, Role.TEACHER);

    // Create Target Student
    const student = await prisma.user.create({
      data: {
        email: "tn_student@test.com",
        firstName: "Student",
        middleName: "C",
        lastName: "NoteTarget",
        passwordHash: "hash",
        phoneNumber: "3333333333",
        gender: "MALE",
        role: Role.STUDENT,
        status: "ACTIVE",
      },
    });
    studentId = student.id;
    studentToken = generateAccessToken(student.id, Role.STUDENT);

    // Create Unrelated Student
    const unrelatedStudent = await prisma.user.create({
      data: {
        email: "tn_unrelated_student@test.com",
        firstName: "Student",
        middleName: "D",
        lastName: "NoteUnrelated",
        passwordHash: "hash",
        phoneNumber: "4444444444",
        gender: "FEMALE",
        role: Role.STUDENT,
        status: "ACTIVE",
      },
    });
    unrelatedStudentId = unrelatedStudent.id;

    // Create Parent
    const parent = await prisma.user.create({
      data: {
        email: "tn_parent@test.com",
        firstName: "Parent",
        middleName: "E",
        lastName: "NoteParent",
        passwordHash: "hash",
        phoneNumber: "5555555555",
        gender: "MALE",
        role: Role.PARENT,
        status: "ACTIVE",
      },
    });
    parentId = parent.id;
    parentToken = generateAccessToken(parent.id, Role.PARENT);

    // Setup Parent-Student relationship (APPROVED) for studentId
    await prisma.parentStudentRelationship.create({
      data: {
        parentId,
        studentId,
        relationshipType: "MOTHER",
        status: "APPROVED",
      },
    });

    const cls = await prisma.class.create({ data: { grade: 9, section: "C" } });
    const subj = await prisma.subject.create({ data: { name: "Mathematics" } });
    
    await prisma.studentClass.create({ data: { studentId, classId: cls.id } });
    await prisma.teacherClassSubject.create({ data: { teacherId, classId: cls.id, subjectId: subj.id } });
  });

  afterAll(async () => {
    await prisma.teacherNote.deleteMany();
    await prisma.teacherClassSubject.deleteMany();
    await prisma.studentClass.deleteMany();
    await prisma.subject.deleteMany();
    await prisma.class.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany({
      where: {
        id: { in: [teacherId, otherTeacherId, studentId, unrelatedStudentId, parentId] },
      },
    });
  });

  // Test 9: Teacher creates note.
  it("9. Teacher creates note", async () => {
    const res = await request(app)
      .post("/teacher-notes")
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        studentId,
        title: "Behavioral Progress Note",
        content: "Student showed exceptional participation in class discussion today.",
      });

    expect(res.status).toBe(201);
    expect(res.body.note).toBeDefined();
    expect(res.body.note.title).toBe("Behavioral Progress Note");
    noteId = res.body.note.id;
  });

  // Test 10: Invalid note rejected.
  it("10. Invalid note rejected", async () => {
    const res = await request(app)
      .post("/teacher-notes")
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        studentId: "invalid-uuid",
        title: "",
        content: "",
      });

    expect(res.status).toBe(400);
  });

  // Test 11: Teacher updates note.
  it("11. Teacher updates note", async () => {
    const res = await request(app)
      .patch(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        title: "Updated Behavioral Progress Note",
        content: "Student showed exceptional leadership in the group project.",
      });

    expect(res.status).toBe(200);
    expect(res.body.note.title).toBe("Updated Behavioral Progress Note");
  });

  // Test 13: Student views note.
  it("13. Student views note written about them", async () => {
    const res = await request(app)
      .get(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.note.id).toBe(noteId);

    const listRes = await request(app)
      .get(`/teacher-notes/student/${studentId}`)
      .set("Authorization", `Bearer ${studentToken}`);

    expect(listRes.status).toBe(200);
    expect(listRes.body.notes).toBeInstanceOf(Array);
    expect(listRes.body.notes.length).toBeGreaterThan(0);
  });

  // Test 14: Verified parent views child's note.
  it("14. Verified parent views child's note", async () => {
    const res = await request(app)
      .get(`/teacher-notes/student/${studentId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.notes).toBeInstanceOf(Array);
    expect(res.body.notes.length).toBeGreaterThan(0);

    const singleRes = await request(app)
      .get(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(singleRes.status).toBe(200);
    expect(singleRes.body.note.id).toBe(noteId);
  });

  // Test 15: Parent cannot view unrelated student's note.
  it("15. Parent cannot view unrelated student's note", async () => {
    const res = await request(app)
      .get(`/teacher-notes/student/${unrelatedStudentId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.status).toBe(403);
  });

  // Test 16: Unauthorized access returns 403.
  it("16. Unauthorized access returns 403 when updating/deleting another teacher's note", async () => {
    const patchRes = await request(app)
      .patch(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${otherTeacherToken}`)
      .send({ title: "Hacked Note Title" });

    expect(patchRes.status).toBe(403);

    const deleteRes = await request(app)
      .delete(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${otherTeacherToken}`);

    expect(deleteRes.status).toBe(403);
  });

  // Test 12: Teacher deletes note.
  it("12. Teacher deletes note", async () => {
    const res = await request(app)
      .delete(`/teacher-notes/${noteId}`)
      .set("Authorization", `Bearer ${teacherToken}`);

    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Teacher note deleted successfully.");
  });
});
