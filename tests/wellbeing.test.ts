import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { generateAccessToken } from "../src/utils/jwt";
import { Role } from "@prisma/client";

// Setup mock users
let studentToken: string;
let studentId: string;

let parentToken: string;
let parentId: string;

let otherParentToken: string;

let unapprovedParentToken: string;

let teacherToken: string;

beforeAll(async () => {
  // Create Student
  const student = await prisma.user.create({
    data: {
      firstName: "Test",
      middleName: "M",
      lastName: "Student",
      email: "student_wellbeing@test.com",
      phoneNumber: "1234567890",
      passwordHash: "hash",
      gender: "MALE",
      role: Role.STUDENT,
      status: "ACTIVE",
    },
  });
  studentId = student.id;
  studentToken = generateAccessToken(student.id, Role.STUDENT);

  // Create Parent (Approved)
  const parent = await prisma.user.create({
    data: {
      firstName: "Test",
      middleName: "M",
      lastName: "Parent",
      email: "parent_wellbeing@test.com",
      phoneNumber: "1234567890",
      passwordHash: "hash",
      gender: "MALE",
      role: Role.PARENT,
      status: "ACTIVE",
    },
  });
  parentId = parent.id;
  parentToken = generateAccessToken(parent.id, Role.PARENT);

  // Approve Relationship
  await prisma.parentStudentRelationship.create({
    data: {
      parentId: parent.id,
      studentId: student.id,
      relationshipType: "FATHER",
      status: "APPROVED",
    },
  });

  // Create Parent (Unapproved)
  const unapprovedParent = await prisma.user.create({
    data: {
      firstName: "Unapproved",
      middleName: "M",
      lastName: "Parent",
      email: "unapproved_parent@test.com",
      phoneNumber: "1234567890",
      passwordHash: "hash",
      gender: "MALE",
      role: Role.PARENT,
      status: "ACTIVE",
    },
  });
  unapprovedParentToken = generateAccessToken(unapprovedParent.id, Role.PARENT);

  // Pending Relationship
  await prisma.parentStudentRelationship.create({
    data: {
      parentId: unapprovedParent.id,
      studentId: student.id,
      relationshipType: "MOTHER",
      status: "PENDING",
    },
  });

  // Create Other Parent (No relation)
  const otherParent = await prisma.user.create({
    data: {
      firstName: "Other",
      middleName: "M",
      lastName: "Parent",
      email: "other_parent@test.com",
      phoneNumber: "1234567890",
      passwordHash: "hash",
      gender: "MALE",
      role: Role.PARENT,
      status: "ACTIVE",
    },
  });
  otherParentToken = generateAccessToken(otherParent.id, Role.PARENT);

  // Create Teacher
  const teacher = await prisma.user.create({
    data: {
      firstName: "Test",
      middleName: "M",
      lastName: "Teacher",
      email: "teacher_wellbeing@test.com",
      phoneNumber: "1234567890",
      passwordHash: "hash",
      gender: "FEMALE",
      role: Role.TEACHER,
      status: "ACTIVE",
    },
  });
  teacherToken = generateAccessToken(teacher.id, Role.TEACHER);
});

afterAll(async () => {
  // Clean up
  await prisma.appUsage.deleteMany({});
  await prisma.deviceUsage.deleteMany({});
  await prisma.wellbeingLimit.deleteMany({});
  await prisma.parentStudentRelationship.deleteMany({
    where: { studentId },
  });
  await prisma.user.deleteMany({
    where: {
      email: {
        in: [
          "student_wellbeing@test.com",
          "parent_wellbeing@test.com",
          "unapproved_parent@test.com",
          "other_parent@test.com",
          "teacher_wellbeing@test.com",
        ],
      },
    },
  });
});

describe("Digital Wellbeing API", () => {
  describe("Upload Usage (Student)", () => {
    it("1. Student can upload wellbeing data", async () => {
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 185,
          apps: [
            { appName: "YouTube", usageMinutes: 60 },
            { appName: "Chrome", usageMinutes: 45 },
          ],
        });
      expect(res.status).toBe(200);
      expect(res.body.data.screenTimeMinutes).toBe(185);
    });

    it("2. Unauthenticated user cannot upload wellbeing data", async () => {
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 185,
        });
      expect(res.status).toBe(401);
    });

    it("3. Parent cannot upload wellbeing data for a student", async () => {
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${parentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 185,
        });
      expect(res.status).toBe(403);
    });

    it("4. Negative screen time is rejected", async () => {
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: -50,
        });
      expect(res.status).toBe(400);
    });

    it("5. Invalid app usage is rejected", async () => {
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 100,
          apps: [{ appName: "YouTube", usageMinutes: -10 }],
        });
      expect(res.status).toBe(400);
    });

    it("6. Duplicate daily usage is handled correctly (Upsert)", async () => {
      const res1 = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 200,
        });
      expect(res1.status).toBe(200);
      expect(res1.body.data.screenTimeMinutes).toBe(200);

      // Verify DB count
      const count = await prisma.deviceUsage.count({
        where: { studentId, date: new Date("2026-08-18") },
      });
      expect(count).toBe(1);
    });
  });

  describe("View Wellbeing Data", () => {
    it("7. Student can view own wellbeing data", async () => {
      const res = await request(app)
        .get("/api/wellbeing/me")
        .set("Authorization", `Bearer ${studentToken}`);
      expect(res.status).toBe(200);
      expect(res.body.data.screenTimeMinutes).toBe(200); // from previous test
    });

    it("8. Student cannot view another student's wellbeing data", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/some-other-uuid/daily`)
        .set("Authorization", `Bearer ${studentToken}`);
      expect(res.status).toBe(403);
    });

    it("9. Parent can view approved child's wellbeing data", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/daily`)
        .set("Authorization", `Bearer ${parentToken}`);
      expect(res.status).toBe(200);
      expect(res.body.data.screenTimeMinutes).toBe(200);
    });

    it("10. Parent cannot view unapproved child's wellbeing data", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/daily`)
        .set("Authorization", `Bearer ${unapprovedParentToken}`);
      expect(res.status).toBe(403);
    });

    it("11. Parent cannot view another parent's child's data", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/daily`)
        .set("Authorization", `Bearer ${otherParentToken}`);
      expect(res.status).toBe(403);
    });

    it("12. Teacher cannot access wellbeing data by default", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/daily`)
        .set("Authorization", `Bearer ${teacherToken}`);
      expect(res.status).toBe(403);
    });

    it("17. Weekly summary is calculated correctly", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/weekly`)
        .set("Authorization", `Bearer ${parentToken}`);
      expect(res.status).toBe(200);
      expect(res.body.data.totalScreenTimeMinutes).toBe(200);
      expect(res.body.data.daysReported).toBe(1);
    });
  });

  describe("Usage Limits", () => {
    it("13. Parent can create a wellbeing limit for approved child", async () => {
      const res = await request(app)
        .put(`/api/wellbeing/students/${studentId}/limit`)
        .set("Authorization", `Bearer ${parentToken}`)
        .send({
          dailyScreenTimeMinutes: 120,
          enabled: true,
        });
      expect(res.status).toBe(200);
      expect(res.body.data.dailyScreenTimeMinutes).toBe(120);
    });

    it("14. Parent cannot create a limit for an unapproved child", async () => {
      const res = await request(app)
        .put(`/api/wellbeing/students/${studentId}/limit`)
        .set("Authorization", `Bearer ${unapprovedParentToken}`)
        .send({
          dailyScreenTimeMinutes: 120,
          enabled: true,
        });
      expect(res.status).toBe(403);
    });

    it("15. Student cannot change their parent's configured limit", async () => {
      const res = await request(app)
        .put(`/api/wellbeing/students/${studentId}/limit`)
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          dailyScreenTimeMinutes: 300,
        });
      expect(res.status).toBe(403);
    });

    it("16. Limit exceeded is correctly detected", async () => {
      // Current limit is 120. Upload 185.
      const res = await request(app)
        .post("/api/wellbeing/usage")
        .set("Authorization", `Bearer ${studentToken}`)
        .send({
          date: "2026-08-18",
          screenTimeMinutes: 185,
        });
      expect(res.status).toBe(200);
      expect(res.body.data.limitExceeded).toBe(true);
      expect(res.body.data.dailyLimitMinutes).toBe(120);
    });
  });

  it("18. Sensitive authentication data is never returned", async () => {
      const res = await request(app)
        .get(`/api/wellbeing/students/${studentId}/daily`)
        .set("Authorization", `Bearer ${parentToken}`);
      
      const bodyStr = JSON.stringify(res.body);
      expect(bodyStr).not.toContain("passwordHash");
      expect(bodyStr).not.toContain("token");
  });
});
