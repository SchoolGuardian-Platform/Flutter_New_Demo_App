import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { Role } from "@prisma/client";
import { generateAccessToken } from "../src/utils/jwt";

describe("Grade API", () => {
  let teacherId: string;
  let studentId: string;
  let parentId: string;
  let teacherToken: string;
  let studentToken: string;
  let parentToken: string;
  let gradeId: string;
  
  beforeAll(async () => {
    await prisma.grade.deleteMany();
    await prisma.teacherClassSubject.deleteMany();
    await prisma.studentClass.deleteMany();
    await prisma.subject.deleteMany();
    await prisma.class.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();
    const teacher = await prisma.user.create({
      data: {
        email: "teacher@test.com",
        firstName: "TFirst",
        middleName: "M",
        lastName: "TLast",
        passwordHash: "hash",
        phoneNumber: "1234567890",
        gender: "MALE",
        role: Role.TEACHER,
        status: "ACTIVE",
      }
    });
    teacherId = teacher.id;
    teacherToken = generateAccessToken(teacher.id, Role.TEACHER);

    const student = await prisma.user.create({
      data: {
        email: "student@test.com",
        firstName: "SFirst",
        middleName: "M",
        lastName: "SLast",
        passwordHash: "hash",
        phoneNumber: "0987654321",
        gender: "FEMALE",
        role: Role.STUDENT,
        status: "ACTIVE",
      }
    });
    studentId = student.id;
    studentToken = generateAccessToken(student.id, Role.STUDENT);

    const parent = await prisma.user.create({
      data: {
        email: "parent@test.com",
        firstName: "PFirst",
        middleName: "M",
        lastName: "PLast",
        passwordHash: "hash",
        phoneNumber: "1122334455",
        gender: "FEMALE",
        role: Role.PARENT,
        status: "ACTIVE",
      }
    });
    parentId = parent.id;
    parentToken = generateAccessToken(parent.id, Role.PARENT);

    // Setup Class and Subjects
    const cls = await prisma.class.create({
      data: { grade: 8, section: "B" }
    });
    const subj = await prisma.subject.create({
      data: { name: "Science" }
    });

    await prisma.studentClass.create({
      data: { studentId, classId: cls.id }
    });

    await prisma.teacherClassSubject.create({
      data: { teacherId, classId: cls.id, subjectId: subj.id }
    });

    // Setup ParentStudent relationship
    await prisma.parentStudentRelationship.create({
      data: { parentId, studentId, relationshipType: "MOTHER", status: "APPROVED" }
    });
  });

  afterAll(async () => {
    await prisma.teacherClassSubject.deleteMany();
    await prisma.studentClass.deleteMany();
    await prisma.subject.deleteMany();
    await prisma.class.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.grade.deleteMany();
    await prisma.user.deleteMany();
  });

  describe("POST /grades", () => {
    it("should allow teacher to create a grade", async () => {
      const res = await request(app)
        .post("/grades")
        .set("Authorization", `Bearer ${teacherToken}`)
        .send({
          studentId,
          subject: "Science",
          assessmentType: "QUIZ",
          score: 85,
          maxScore: 100
        });
      
      console.log(res.body);
      expect(res.status).toBe(201);
      gradeId = res.body.grade.id;
      expect(res.body.grade.score).toBe(85);
    });

    it("should reject if score > maxScore", async () => {
      const res = await request(app)
        .post("/grades")
        .set("Authorization", `Bearer ${teacherToken}`)
        .send({
          studentId,
          subject: "Science",
          assessmentType: "FINAL",
          score: 110,
          maxScore: 100
        });
      
      expect(res.status).toBe(400); // Validation error
    });
  });

  describe("GET /grades/student/:studentId", () => {
    it("should allow parent to view their verified child's grades", async () => {
      const res = await request(app)
        .get(`/grades/student/${studentId}`)
        .set("Authorization", `Bearer ${parentToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body.grades).toBeInstanceOf(Array);
      expect(res.body.grades.length).toBeGreaterThan(0);
    });
  });

  describe("GET /grades/student/:studentId/summary", () => {
    it("should return grade summary", async () => {
      const res = await request(app)
        .get(`/grades/student/${studentId}/summary`)
        .set("Authorization", `Bearer ${studentToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body.summary).toBeDefined();
      expect(res.body.summary.overallAverage).toBe(85);
      expect(res.body.summary.subjectAverages.Science).toBe(85);
    });
  });
});
