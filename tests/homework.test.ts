import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { Role } from "@prisma/client";
import { generateAccessToken } from "../src/utils/jwt";

describe("Homework API", () => {
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

  let homeworkId: string;
  let classId: string;

  beforeAll(async () => {
    // Create Teacher
    const teacher = await prisma.user.create({
      data: {
        email: "hw_teacher@test.com",
        firstName: "Teacher",
        middleName: "A",
        lastName: "One",
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
        email: "hw_other_teacher@test.com",
        firstName: "Teacher",
        middleName: "B",
        lastName: "Two",
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
        email: "hw_student@test.com",
        firstName: "Student",
        middleName: "C",
        lastName: "One",
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
        email: "hw_unrelated_student@test.com",
        firstName: "Student",
        middleName: "D",
        lastName: "Unrelated",
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
        email: "hw_parent@test.com",
        firstName: "Parent",
        middleName: "E",
        lastName: "One",
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
    classId = cls.id;
    const subj = await prisma.subject.create({ data: { name: "Mathematics" } });
    
    await prisma.studentClass.create({ data: { studentId, classId: cls.id } });
    await prisma.teacherClassSubject.create({ data: { teacherId, classId: cls.id, subjectId: subj.id } });
  });

  afterAll(async () => {
    await prisma.homework.deleteMany();
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

  // Test 1: Teacher creates homework.
  it("1. Teacher creates homework", async () => {
    const res = await request(app)
      .post("/homework")
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        classId,
        subject: "Mathematics",
        title: "Algebra Assignment 1",
        description: "Solve problems 1 through 10 on page 42.",
        dueDate: "2026-09-01T23:59:59.000Z",
      });

    expect(res.status).toBe(201);
    expect(res.body.homework).toBeDefined();
    expect(res.body.homework.title).toBe("Algebra Assignment 1");
    homeworkId = res.body.homework.id;
  });

  // Test 2: Invalid homework rejected.
  it("2. Invalid homework rejected", async () => {
    const res = await request(app)
      .post("/homework")
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        classId: "invalid-uuid",
        subject: "",
        title: "",
        description: "",
      });

    expect(res.status).toBe(400);
  });

  // Test 3: Teacher updates homework.
  it("3. Teacher updates homework", async () => {
    const res = await request(app)
      .patch(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${teacherToken}`)
      .send({
        title: "Updated Algebra Assignment 1",
        description: "Solve problems 1 through 15 on page 42.",
      });

    expect(res.status).toBe(200);
    expect(res.body.homework.title).toBe("Updated Algebra Assignment 1");
  });

  // Test 5: Student views homework.
  it("5. Student views homework assigned to them", async () => {
    const res = await request(app)
      .get(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.homework.id).toBe(homeworkId);

    const listRes = await request(app)
      .get(`/homework/student/${studentId}`)
      .set("Authorization", `Bearer ${studentToken}`);

    expect(listRes.status).toBe(200);
    expect(listRes.body.homeworks).toBeInstanceOf(Array);
    expect(listRes.body.homeworks.length).toBeGreaterThan(0);
  });

  // Test 6: Verified parent views child's homework.
  it("6. Verified parent views child's homework", async () => {
    const res = await request(app)
      .get(`/homework/student/${studentId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.homeworks).toBeInstanceOf(Array);
    expect(res.body.homeworks.length).toBeGreaterThan(0);

    const singleRes = await request(app)
      .get(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(singleRes.status).toBe(200);
    expect(singleRes.body.homework.id).toBe(homeworkId);
  });

  // Test 7: Parent cannot view unrelated student's homework.
  it("7. Parent cannot view unrelated student's homework", async () => {
    const res = await request(app)
      .get(`/homework/student/${unrelatedStudentId}`)
      .set("Authorization", `Bearer ${parentToken}`);

    expect(res.status).toBe(403);
  });

  // Test 8: Unauthorized access returns 403.
  it("8. Unauthorized access returns 403 when updating/deleting another teacher's homework", async () => {
    const patchRes = await request(app)
      .patch(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${otherTeacherToken}`)
      .send({ title: "Hacked Title" });

    expect(patchRes.status).toBe(403);

    const deleteRes = await request(app)
      .delete(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${otherTeacherToken}`);

    expect(deleteRes.status).toBe(403);
  });

  // Test 4: Teacher deletes homework.
  it("4. Teacher deletes homework", async () => {
    const res = await request(app)
      .delete(`/homework/${homeworkId}`)
      .set("Authorization", `Bearer ${teacherToken}`);

    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Homework deleted successfully.");
  });
});
