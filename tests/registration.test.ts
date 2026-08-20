import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { hashPassword, verifyPassword } from "../src/utils/hash";
import { registerStudent, registerParent, registerTeacher } from "../src/service/registration.service";
import { Gender } from "@prisma/client";

describe("Registration Service & API Endpoints Suite (#18 - #24)", () => {
  beforeEach(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.passwordResetToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.passwordResetToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  // Test 1: Student registration with all fields
  it("1. should successfully register a Student with required fields", async () => {
    const res = await request(app).post("/auth/register/student").send({
      firstName: "Sara",
      middleName: "Abebe",
      lastName: "Kebede",
      dateOfBirth: "2012-05-18",
      gender: "FEMALE",
      phoneNumber: "7000000000",
      email: "sara@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(201);
    expect(res.body.data).toHaveProperty("id");
    expect(res.body.data.firstName).toBe("Sara");
    expect(res.body.data.middleName).toBe("Abebe");
    expect(res.body.data.lastName).toBe("Kebede");
    expect(res.body.data.gender).toBe("FEMALE");
    expect(res.body.data.email).toBe("sara@example.com");
    expect(res.body.data.role).toBe("STUDENT");
    expect(res.body.data.status).toBe("UNVERIFIED");
  });

  // Test 2: Parent registration with all fields
  it("2. should successfully register a Parent with required fields", async () => {
    const res = await request(app).post("/auth/register/parent").send({
      firstName: "Abebe",
      middleName: "Kebede",
      lastName: "Tesfaye",
      phoneNumber: "7100000000",
      gender: "MALE",
      email: "abebe@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(201);
    expect(res.body.data.firstName).toBe("Abebe");
    expect(res.body.data.email).toBe("abebe@example.com");
    expect(res.body.data.role).toBe("PARENT");
  });

  // Test 3: Teacher registration with all fields
  it("3. should successfully register a Teacher with required fields", async () => {
    const res = await request(app).post("/auth/register/teacher").send({
      firstName: "Marta",
      middleName: "John",
      lastName: "Smith",
      dateOfBirth: "1995-08-12",
      gender: "FEMALE",
      phoneNumber: "7200000000",
      email: "marta@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(201);
    expect(res.body.data.firstName).toBe("Marta");
    expect(res.body.data.email).toBe("marta@example.com");
    expect(res.body.data.role).toBe("TEACHER");
  });

  // Test 4: Rejection when confirmPassword does not match password
  it("4. should reject registration if confirmPassword does not match password", async () => {
    const res = await request(app).post("/auth/register/student").send({
      firstName: "Sara",
      lastName: "Kebede",
      dateOfBirth: "2012-05-18",
      gender: "FEMALE",
      phoneNumber: "7300000000",
      middleName: "A",
      email: "mismatch@example.com",
      password: "StrongPassword123!",
      confirmPassword: "DifferentPassword123!",
    });

    expect(res.status).toBe(400);
  });

  // Test 5: Rejection when dateOfBirth is in the future
  it("5. should reject student registration with a future date of birth", async () => {
    const res = await request(app).post("/auth/register/student").send({
      firstName: "Future",
      lastName: "Baby",
      dateOfBirth: "2099-01-01",
      gender: "MALE",
      phoneNumber: "7400000000",
      middleName: "A",
      email: "future@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(400);
  });

  // Test 6: Rejection when dateOfBirth format is invalid
  it("6. should reject registration with an invalid date of birth format", async () => {
    const res = await request(app).post("/auth/register/student").send({
      firstName: "Invalid",
      lastName: "Date",
      dateOfBirth: "18-05-2012",
      gender: "MALE",
      phoneNumber: "7500000000",
      middleName: "A",
      email: "invaliddate@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(400);
  });

  // Test 7: Duplicate email rejection
  it("7. should reject registration with a duplicate email", async () => {
    await registerStudent({
      firstName: "Existing",
      middleName: "M",
      lastName: "Student",
      dateOfBirth: "2012-05-18",
      gender: Gender.MALE,
      phoneNumber: "7600000000",
      email: "duplicate@test.com",
      password: "StrongPassword123!",
    });

    const res = await request(app).post("/auth/register/student").send({
      firstName: "Another",
      middleName: "M",
      lastName: "Student",
      dateOfBirth: "2012-05-18",
      gender: "FEMALE",
      phoneNumber: "7700000000",
      email: "duplicate@test.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("DUPLICATE_EMAIL");
  });

  // Test 8: Disallow public admin registration endpoint
  it("8. should NOT have a public POST /auth/register/admin endpoint (404)", async () => {
    const res = await request(app).post("/auth/register/admin").send({
      firstName: "Hacker",
      middleName: "M",
      lastName: "Admin",
      phoneNumber: "7800000000",
      gender: "MALE",
      email: "hacker@test.com",
      password: "StrongPassword123!",
    });

    expect(res.status).toBe(404);
  });

  // Test 9: Disallow selecting ADMIN role in public registration
  it("9. should reject attempts to select ADMIN role via public registration endpoint", async () => {
    const res = await request(app).post("/auth/register").send({
      firstName: "Sneaky",
      middleName: "M",
      lastName: "User",
      phoneNumber: "7900000000",
      gender: "MALE",
      email: "sneaky@test.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
      role: "ADMIN",
    });

    expect(res.status).toBe(400);
  });

  // Test 10: Password hashing verification
  it("10. should ensure password is stored as a secure bcrypt hash", async () => {
    const plainPassword = "StrongPassword123!";
    const user = await registerParent({
      firstName: "Hashed",
      middleName: "M",
      lastName: "User",
      phoneNumber: "7910000000",
      gender: Gender.MALE,
      email: "hashcheck@test.com",
      password: plainPassword,
    });

    const dbUser = await prisma.user.findUnique({ where: { id: user.id } });
    expect(dbUser).not.toBeNull();
    expect(dbUser?.passwordHash).not.toBe(plainPassword);
    expect(dbUser?.passwordHash.startsWith("$2")).toBe(true);
  });
});
