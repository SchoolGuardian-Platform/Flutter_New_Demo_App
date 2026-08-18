import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { Role } from "@prisma/client";
import { generateAccessToken } from "../src/utils/jwt";

describe("Attendance API", () => {
  let teacherId: string;
  let studentId: string;
  let teacherToken: string;
  let studentToken: string;
  
  beforeAll(async () => {
    await prisma.attendance.deleteMany();
    await prisma.teacherClassSubject.deleteMany();
    await prisma.studentClass.deleteMany();
    await prisma.subject.deleteMany();
    await prisma.class.deleteMany();
    await prisma.user.deleteMany();
    // Setup users
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

    // Setup Class and Subjects
    const cls = await prisma.class.create({
      data: { grade: 7, section: "A" }
    });
    const subj = await prisma.subject.create({
      data: { name: "Math Test" }
    });

    await prisma.studentClass.create({
      data: { studentId, classId: cls.id }
    });

    await prisma.teacherClassSubject.create({
      data: { teacherId, classId: cls.id, subjectId: subj.id }
    });
  });

  afterAll(async () => {
    await prisma.teacherClassSubject.deleteMany();
    await prisma.studentClass.deleteMany();
    await prisma.subject.deleteMany();
    await prisma.class.deleteMany();
    await prisma.attendance.deleteMany();
    await prisma.user.deleteMany();
  });

  describe("POST /attendance", () => {
    it("should allow teacher to create attendance", async () => {
      const res = await request(app)
        .post("/attendance")
        .set("Authorization", `Bearer ${teacherToken}`)
        .send({
          studentId,
          date: "2026-08-16",
          status: "PRESENT",
          note: "On time"
        });
      
      console.log(res.body);
      
      expect(res.status).toBe(201);
      expect(res.body.attendance.status).toBe("PRESENT");
    });

    it("should reject duplicate attendance for the same day", async () => {
      const res = await request(app)
        .post("/attendance")
        .set("Authorization", `Bearer ${teacherToken}`)
        .send({
          studentId,
          date: "2026-08-16T00:00:00.000Z",
          status: "LATE"
        });
      
      expect(res.status).toBe(400); // Bad Request
    });

    it("should reject unauthorized users", async () => {
      const res = await request(app)
        .post("/attendance")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          studentId,
          date: "2026-08-17T00:00:00.000Z",
          status: "PRESENT"
        });
      
      expect(res.status).toBe(403);
    });
  });

  describe("GET /attendance/student/:studentId", () => {
    it("should allow student to view their own attendance", async () => {
      const res = await request(app)
        .get(`/attendance/student/${studentId}`)
        .set("Authorization", `Bearer ${studentToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body.attendance).toBeInstanceOf(Array);
      expect(res.body.attendance.length).toBeGreaterThan(0);
    });

    it("should allow teacher to view assigned student attendance", async () => {
      const res = await request(app)
        .get(`/attendance/student/${studentId}`)
        .set("Authorization", `Bearer ${teacherToken}`);
      
      expect(res.status).toBe(200);
    });
  });

  describe("GET /attendance/student/:studentId/summary", () => {
    it("should return attendance summary", async () => {
      const res = await request(app)
        .get(`/attendance/student/${studentId}/summary`)
        .set("Authorization", `Bearer ${studentToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body.summary).toBeDefined();
      expect(res.body.summary.present).toBe(1);
    });
  });
});
