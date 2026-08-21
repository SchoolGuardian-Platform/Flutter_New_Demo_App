import request from "supertest";
import app from "../src/app";
import { prisma } from "../src/utils/prisma";
import { hashPassword, verifyPassword, generateRandomToken, hashToken } from "../src/utils/hash";
import { createAndStoreRefreshToken } from "../src/service/token.service";
import { Role, AccountStatus } from "@prisma/client";

describe("Password Reset Service & API Endpoints Suite", () => {
  const initialPassword = "InitialPassword123!";
  let testUserId: string;
  const testUserEmail = "reset.user@test.com";

  beforeEach(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.passwordResetToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();

    const passwordHash = await hashPassword(initialPassword);
    const user = await prisma.user.create({
      data: {
        firstName: "Reset",
        middleName: "M",
        lastName: "User",
        email: testUserEmail,
        phoneNumber: "6000000000",
        gender: "MALE",
        passwordHash,
        role: Role.PARENT,
        status: AccountStatus.ACTIVE,
      },
    });
    testUserId = user.id;
  });

  afterAll(async () => {
    await prisma.auditLog.deleteMany();
    await prisma.refreshToken.deleteMany();
    await prisma.passwordResetToken.deleteMany();
    await prisma.parentStudentRelationship.deleteMany();
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  // Test 10: Forgot password with existing email
  it("10. should handle forgot password request for existing email and generate hashed token in DB", async () => {
    const res = await request(app).post("/auth/forgot-password").send({
      email: testUserEmail,
    });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty("message");

    const resetTokenRecord = await prisma.passwordResetToken.findFirst({
      where: { userId: testUserId },
    });

    expect(resetTokenRecord).not.toBeNull();
    expect(resetTokenRecord?.expiresAt.getTime()).toBeGreaterThan(Date.now());
  });

  // Test 11: Forgot password with unknown email
  it("11. should return generic success for unknown email without creating reset token", async () => {
    const res = await request(app).post("/auth/forgot-password").send({
      email: "nonexistent@test.com",
    });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty("message");

    const tokens = await prisma.passwordResetToken.findMany({
      where: { user: { email: "nonexistent@test.com" } },
    });
    expect(tokens.length).toBe(0);
  });

  // Test 12: Expired reset token
  it("12. should reject reset confirmation when token is expired", async () => {
    const rawToken = generateRandomToken();
    const tokenHash = await hashToken(rawToken);

    await prisma.passwordResetToken.create({
      data: {
        userId: testUserId,
        tokenHash,
        expiresAt: new Date(Date.now() - 1000), // Expired 1 second ago
      },
    });

    const res = await request(app).post("/auth/reset-password/confirm").send({
      token: rawToken,
      newPassword: "NewSecurePassword123!",
    });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_OR_EXPIRED_TOKEN");
    expect(res.body.error.message).toBe("Invalid or expired reset token.");
  });

  // Test 13: Used reset token
  it("13. should reject reset confirmation when token has already been used", async () => {
    const rawToken = generateRandomToken();
    const tokenHash = await hashToken(rawToken);

    await prisma.passwordResetToken.create({
      data: {
        userId: testUserId,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000),
        usedAt: new Date(), // Already used
      },
    });

    const res = await request(app).post("/auth/reset-password/confirm").send({
      token: rawToken,
      newPassword: "NewSecurePassword123!",
    });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_OR_EXPIRED_TOKEN");
    expect(res.body.error.message).toBe("Invalid or expired reset token.");
  });

  // Test 14: Invalid reset token
  it("14. should reject reset confirmation for random non-existent token", async () => {
    const res = await request(app).post("/auth/reset-password/confirm").send({
      token: "completely_invalid_random_token_string",
      newPassword: "NewSecurePassword123!",
    });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("INVALID_OR_EXPIRED_TOKEN");
    expect(res.body.error.message).toBe("Invalid or expired reset token.");
  });

  // Test 15: Successful password reset
  it("15. should successfully reset password and update password hash in DB", async () => {
    const rawToken = generateRandomToken();
    const tokenHash = await hashToken(rawToken);

    await prisma.passwordResetToken.create({
      data: {
        userId: testUserId,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000),
      },
    });

    const newPassword = "BrandNewPassword123!";

    const res = await request(app).post("/auth/reset-password/confirm").send({
      token: rawToken,
      newPassword,
    });

    expect(res.status).toBe(200);

    const updatedUser = await prisma.user.findUnique({ where: { id: testUserId } });
    const isNewPassValid = await verifyPassword(newPassword, updatedUser!.passwordHash);
    const isOldPassValid = await verifyPassword(initialPassword, updatedUser!.passwordHash);

    expect(isNewPassValid).toBe(true);
    expect(isOldPassValid).toBe(false);

    const updatedToken = await prisma.passwordResetToken.findUnique({ where: { tokenHash } });
    expect(updatedToken?.usedAt).not.toBeNull();
  });

  // Test 16: Existing refresh tokens invalidated after password reset
  it("16. should invalidate all existing active refresh tokens when password reset occurs", async () => {
    // Create 2 active refresh tokens for the user
    await createAndStoreRefreshToken(testUserId);
    await createAndStoreRefreshToken(testUserId);

    const activeBefore = await prisma.refreshToken.findMany({
      where: { userId: testUserId, revokedAt: null },
    });
    expect(activeBefore.length).toBe(2);

    const rawToken = generateRandomToken();
    const tokenHash = await hashToken(rawToken);

    await prisma.passwordResetToken.create({
      data: {
        userId: testUserId,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000),
      },
    });

    const res = await request(app).post("/auth/reset-password/confirm").send({
      token: rawToken,
      newPassword: "AfterResetPassword123!",
    });

    expect(res.status).toBe(200);

    const activeAfter = await prisma.refreshToken.findMany({
      where: { userId: testUserId, revokedAt: null },
    });
    expect(activeAfter.length).toBe(0);
  });
});
