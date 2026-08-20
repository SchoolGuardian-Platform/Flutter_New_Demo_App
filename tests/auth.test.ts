import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { generateAccessToken } from "../src/utils/jwt";
import { hashPassword } from "../src/utils/hash";
import { Role, AccountStatus, RelationshipType, RelationshipStatus } from "@prisma/client";

describe("SchoolGuardian Backend Core, Admin Approval & Parent-Student Trust Test Suite", () => {
  const testPassword = "TestPassword123!";
  let adminId: string;
  let adminToken: string;

  let activeParentId: string;
  let activeParentToken: string;

  let secondParentId: string;
  let secondParentToken: string;

  let pendingStudentId: string;
  let activeStudentId: string;

  beforeAll(async () => {
    // Clean up DB records in order
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();

    const passwordHash = await hashPassword(testPassword);

    // 1. Admin
    const admin = await prisma.user.create({
      data: {
        firstName: "Admin",
        lastName: "User",
        email: "admin@test.com",
        passwordHash,
        phoneNumber: "1000000000",
        middleName: "M",
        gender: "MALE",
        role: Role.ADMIN,
        status: AccountStatus.ACTIVE,
      },
    });
    adminId = admin.id;
    adminToken = generateAccessToken(adminId, Role.ADMIN);

    // 2. Active Parent 1 (Mother)
    const activeParent = await prisma.user.create({
      data: {
        firstName: "Mother",
        lastName: "Parent",
        email: "mother@test.com",
        passwordHash,
        phoneNumber: "2000000000",
        middleName: "M",
        gender: "FEMALE",
        role: Role.PARENT,
        status: AccountStatus.ACTIVE,
      },
    });
    activeParentId = activeParent.id;
    activeParentToken = generateAccessToken(activeParentId, Role.PARENT);

    // 3. Active Parent 2 (Father - 2nd Guardian)
    const secondParent = await prisma.user.create({
      data: {
        firstName: "Father",
        lastName: "Parent",
        email: "father@test.com",
        passwordHash,
        phoneNumber: "3000000000",
        middleName: "M",
        gender: "MALE",
        role: Role.PARENT,
        status: AccountStatus.ACTIVE,
      },
    });
    secondParentId = secondParent.id;
    secondParentToken = generateAccessToken(secondParentId, Role.PARENT);

    // 4. Pending Student
    const pendingStudent = await prisma.user.create({
      data: {
        firstName: "Daniel",
        lastName: "Student",
        dateOfBirth: new Date("2013-09-10"),
        gender: "MALE",
        phoneNumber: "4000000000",
        middleName: "M",
        email: "daniel@test.com",
        passwordHash,
        role: Role.STUDENT,
        status: AccountStatus.PENDING,
        emailVerifiedAt: new Date(),
      },
    });
    pendingStudentId = pendingStudent.id;

    // 5. Active Student
    const activeStudent = await prisma.user.create({
      data: {
        firstName: "Sara",
        lastName: "Student",
        dateOfBirth: new Date("2012-05-18"),
        gender: "FEMALE",
        phoneNumber: "5000000000",
        middleName: "M",
        studentId: "SG-2026-000001",
        email: "sara@test.com",
        passwordHash,
        role: Role.STUDENT,
        status: AccountStatus.ACTIVE,
      },
    });
    activeStudentId = activeStudent.id;
  });

  afterAll(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  describe("1. Authentication & Status Enforcement", () => {
    it("should allow ACTIVE parent login", async () => {
      const res = await request(app).post("/auth/login").send({
        email: "mother@test.com",
        password: testPassword,
      });

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty("token");
      expect(res.body.data.user.role).toBe("PARENT");
    });

    it("should reject PENDING student login", async () => {
      const res = await request(app).post("/auth/login").send({
        email: "daniel@test.com",
        password: testPassword,
      });

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe("UNAUTHORIZED");
    });
  });

  describe("2. Admin Student Approval Workflow", () => {
    it("should allow ADMIN to list pending students", async () => {
      const res = await request(app)
        .get("/admin/students/pending")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].id).toBe(pendingStudentId);
    });

    it("should prevent non-admin from accessing pending students (403)", async () => {
      const res = await request(app)
        .get("/admin/students/pending")
        .set("Authorization", `Bearer ${activeParentToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe("FORBIDDEN");
    });

    it("should allow ADMIN to approve pending student (PENDING -> ACTIVE)", async () => {
      const res = await request(app)
        .patch(`/admin/students/${pendingStudentId}/approve`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("ACTIVE");

      // Verify student can now log in
      const loginRes = await request(app).post("/auth/login").send({
        email: "daniel@test.com",
        password: testPassword,
      });
      expect(loginRes.status).toBe(200);
    });
  });

  describe("3. Parent-Student Relationship & 2nd Guardian Verification", () => {
    let relId1: string;
    let relId2: string;

    it("should allow Mother (Guardian 1) to request connection to Sara", async () => {
      const res = await request(app)
        .post("/parents/relationships")
        .set("Authorization", `Bearer ${activeParentToken}`)
        .send({
          studentId: "SG-2026-000001",
          relationshipType: RelationshipType.MOTHER,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.status).toBe("PENDING");
      relId1 = res.body.data.id;
    });

    it("should allow Father (Guardian 2) to request 2nd guardian connection to same student Sara", async () => {
      const res = await request(app)
        .post("/parents/relationships")
        .set("Authorization", `Bearer ${secondParentToken}`)
        .send({
          studentId: "SG-2026-000001",
          relationshipType: RelationshipType.FATHER,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.status).toBe("PENDING");
      relId2 = res.body.data.id;
      expect(relId2).not.toBe(relId1);
    });

    it("should reject duplicate relationship request for same parent + student + type", async () => {
      const res = await request(app)
        .post("/parents/relationships")
        .set("Authorization", `Bearer ${activeParentToken}`)
        .send({
          studentId: "SG-2026-000001",
          relationshipType: RelationshipType.MOTHER,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("BAD_REQUEST");
    });

    it("should allow ADMIN to view and approve both guardian relationships", async () => {
      // Approve Mother link
      const approveRes1 = await request(app)
        .patch(`/admin/relationships/${relId1}/approve`)
        .set("Authorization", `Bearer ${adminToken}`);
      expect(approveRes1.status).toBe(200);
      expect(approveRes1.body.data.status).toBe("APPROVED");

      // Approve Father link (2nd Guardian)
      const approveRes2 = await request(app)
        .patch(`/admin/relationships/${relId2}/approve`)
        .set("Authorization", `Bearer ${adminToken}`);
      expect(approveRes2.status).toBe(200);
      expect(approveRes2.body.data.status).toBe("APPROVED");
    });

    it("should allow Mother to view linked students", async () => {
      const res = await request(app)
        .get("/parents/my-students")
        .set("Authorization", `Bearer ${activeParentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].student.id).toBe(activeStudentId);
    });
  });
});
