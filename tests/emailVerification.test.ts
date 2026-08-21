import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { emailService } from "../src/service/email.service";

jest.mock("../src/service/email.service", () => ({
  emailService: {
    sendPasswordResetEmail: jest.fn(),
    sendVerificationEmail: jest.fn(),
  },
}));

describe("Email Verification API Endpoints Suite", () => {
  beforeEach(async () => {
    jest.clearAllMocks();
    await prisma.auditLog.deleteMany();
    await prisma.emailVerificationToken.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.emailVerificationToken.deleteMany();
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  const getStudentPayload = (email: string) => ({
    firstName: "Sara",
    middleName: "M",
    lastName: "Kebede",
    dateOfBirth: "2012-05-18",
    gender: "FEMALE",
    phoneNumber: "8000000000",
    email,
    password: "StrongPassword123!",
    confirmPassword: "StrongPassword123!",
  });

  it("1. Verification email is sent after student registration", async () => {
    const res = await request(app).post("/auth/register/student").send(getStudentPayload("student@example.com"));
    expect(res.status).toBe(201);
    expect(emailService.sendVerificationEmail).toHaveBeenCalledTimes(1);
    expect(emailService.sendVerificationEmail).toHaveBeenCalledWith("student@example.com", "Sara", expect.any(String));
  });

  it("2. Verification email is sent after parent registration", async () => {
    const res = await request(app).post("/auth/register/parent").send({
      firstName: "Abebe",
      middleName: "M",
      lastName: "Kebede",
      phoneNumber: "8100000000",
      gender: "MALE",
      email: "parent@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });
    expect(res.status).toBe(201);
    expect(emailService.sendVerificationEmail).toHaveBeenCalledTimes(1);
  });

  it("3. Verification email is sent after teacher registration", async () => {
    const res = await request(app).post("/auth/register/teacher").send({
      firstName: "Bekele",
      middleName: "M",
      lastName: "Debele",
      dateOfBirth: "1985-05-18",
      phoneNumber: "8200000000",
      gender: "MALE",
      email: "teacher@example.com",
      password: "StrongPassword123!",
      confirmPassword: "StrongPassword123!",
    });
    expect(res.status).toBe(201);
    expect(emailService.sendVerificationEmail).toHaveBeenCalledTimes(1);
  });

  it("4. Verification token is stored hashed and 5. Raw token is never stored", async () => {
    const res = await request(app).post("/auth/register/student").send(getStudentPayload("hash@example.com"));
    const tokens = await prisma.emailVerificationToken.findMany({ where: { userId: res.body.data.id } });
    
    expect(tokens.length).toBe(1);
    const storedHash = tokens[0].tokenHash;

    const emailCall = (emailService.sendVerificationEmail as jest.Mock).mock.calls[0];
    const verificationUrl = emailCall[2] as string;
    const rawToken = verificationUrl.split("?token=")[1];

    expect(rawToken).toBeDefined();
    expect(storedHash).not.toBe(rawToken); // 5. Raw token is never stored
    expect(storedHash.length).toBeGreaterThan(50); // It's hashed (SHA-256 hex is 64 chars)
  });

  it("6. Valid token verifies email and 14. Email verification does not change PENDING status", async () => {
    await request(app).post("/auth/register/student").send(getStudentPayload("verify@example.com"));
    
    const emailCall = (emailService.sendVerificationEmail as jest.Mock).mock.calls[0];
    const rawToken = emailCall[2].split("?token=")[1];

    const verifyRes = await request(app).post("/auth/verify-email").send({ token: rawToken });
    expect(verifyRes.status).toBe(200);

    const user = await prisma.user.findUnique({ where: { email: "verify@example.com" } });
    expect(user?.emailVerifiedAt).not.toBeNull();
    expect(user?.status).toBe("PENDING"); // 14. Does not change PENDING
  });

  it("7. Invalid token is rejected", async () => {
    const res = await request(app).post("/auth/verify-email").send({ token: "invalid-token" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_OR_EXPIRED_TOKEN");
  });

  it("8. Expired token is rejected", async () => {
    await request(app).post("/auth/register/student").send(getStudentPayload("expired@example.com"));
    const emailCall = (emailService.sendVerificationEmail as jest.Mock).mock.calls[0];
    const rawToken = emailCall[2].split("?token=")[1];

    // manually expire it
    await prisma.emailVerificationToken.updateMany({
      data: { expiresAt: new Date(Date.now() - 1000) }
    });

    const verifyRes = await request(app).post("/auth/verify-email").send({ token: rawToken });
    expect(verifyRes.status).toBe(400);
  });

  it("9. Used token is rejected", async () => {
    await request(app).post("/auth/register/student").send(getStudentPayload("used@example.com"));
    const emailCall = (emailService.sendVerificationEmail as jest.Mock).mock.calls[0];
    const rawToken = emailCall[2].split("?token=")[1];

    await request(app).post("/auth/verify-email").send({ token: rawToken });
    
    // reuse
    const verifyRes2 = await request(app).post("/auth/verify-email").send({ token: rawToken });
    expect(verifyRes2.status).toBe(400);
  });

  it("10. Already verified email is handled correctly", async () => {
    const res = await request(app).post("/auth/register/student").send(getStudentPayload("already@example.com"));
    
    // forcefully verify without token
    await prisma.user.update({
      where: { id: res.body.data.id },
      data: { emailVerifiedAt: new Date() }
    });

    const emailCall = (emailService.sendVerificationEmail as jest.Mock).mock.calls[0];
    const rawToken = emailCall[2].split("?token=")[1];

    const verifyRes = await request(app).post("/auth/verify-email").send({ token: rawToken });
    expect(verifyRes.status).toBe(400);
    expect(verifyRes.body.error.code).toBe("EMAIL_ALREADY_VERIFIED");
  });

  it("11. Resend verification works", async () => {
    await request(app).post("/auth/register/student").send(getStudentPayload("resend@example.com"));
    jest.clearAllMocks();

    const res = await request(app).post("/auth/resend-verification").send({ email: "resend@example.com" });
    expect(res.status).toBe(202);
    expect(emailService.sendVerificationEmail).toHaveBeenCalledTimes(1);

    const user = await prisma.user.findUnique({ where: { email: "resend@example.com" }, include: { emailVerificationTokens: true } });
    expect(user?.emailVerificationTokens.length).toBe(2);
    
    // Verify older token is invalidated
    const oldToken = user?.emailVerificationTokens.find(t => t.usedAt !== null);
    expect(oldToken).toBeDefined();
  });

  it("12. Unknown email does not reveal account existence", async () => {
    const res = await request(app).post("/auth/resend-verification").send({ email: "nonexistent@example.com" });
    expect(res.status).toBe(202);
    expect(emailService.sendVerificationEmail).not.toHaveBeenCalled();
  });

  it("13. Resend endpoint is rate limited", async () => {
    // If the rate limiter allows 5 requests per 15 minutes, we hit it 6 times.
    const promises = Array(6).fill(0).map(() => request(app).post("/auth/resend-verification").send({ email: "rate@example.com" }));
    const responses = await Promise.all(promises);
    
    const rateLimited = responses.some(r => r.status === 429);
    expect(rateLimited).toBe(true);
  });
});
