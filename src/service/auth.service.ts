import { AuditAction } from "@prisma/client";
import { prisma } from "../utils/prisma";
import { verifyPassword } from "../utils/hash";
import { generateAccessToken } from "../utils/jwt";
import { UnauthorizedError } from "../utils/errors";
import { createAuditLog } from "./audit.service";
import { createAndStoreRefreshToken, verifyAndRotateRefreshToken, revokeRefreshToken } from "./token.service";
import { LoginInput } from "../validators/auth.validator";

export interface LoginOptions {
  input: LoginInput;
  ipAddress?: string;
  userAgent?: string;
}

export async function loginUser({ input, ipAddress, userAgent }: LoginOptions) {
  const normalizedEmail = input.email.toLowerCase().trim();

  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });

  // Check if user exists
  if (!user) {
    await createAuditLog({
      action: AuditAction.LOGIN_FAILED,
      ipAddress,
      userAgent,
      details: `Failed login for non-existent email: ${normalizedEmail}`,
    });
    throw new UnauthorizedError("Invalid email or password.");
  }

  // Verify password
  const isPasswordValid = await verifyPassword(input.password, user.passwordHash);
  if (!isPasswordValid) {
    await createAuditLog({
      userId: user.id,
      action: AuditAction.LOGIN_FAILED,
      ipAddress,
      userAgent,
      details: "Invalid password attempt",
    });
    throw new UnauthorizedError("Invalid email or password.");
  }

  // Reject non-ACTIVE users with specific messages
  if (user.status !== "ACTIVE") {
    await createAuditLog({
      userId: user.id,
      action: AuditAction.LOGIN_FAILED,
      ipAddress,
      userAgent,
      details: `Login rejected for non-active account status: ${user.status}`,
    });
    
    if (!user.emailVerifiedAt) {
      throw new UnauthorizedError("You are not verified. Please verify your email first.");
    } else if (user.status === "PENDING") {
      throw new UnauthorizedError("Your email is verified, but your account is pending Admin approval.");
    } else {
      throw new UnauthorizedError("Your account is currently inactive.");
    }
  }

  // Generate tokens
  const accessToken = generateAccessToken(user.id, user.role);
  const refreshTokenObj = await createAndStoreRefreshToken(user.id);

  // Write successful audit log
  await createAuditLog({
    userId: user.id,
    action: AuditAction.LOGIN_SUCCESS,
    ipAddress,
    userAgent,
  });

  return {
    token: accessToken,
    refreshToken: refreshTokenObj.token,
    user: {
      id: user.id,
      studentId: user.studentId,
      firstName: user.firstName,
      middleName: user.middleName,
      lastName: user.lastName,
      email: user.email,
      role: user.role,
    },
  };
}

export async function refreshUserToken(refreshToken: string, ipAddress?: string, userAgent?: string) {
  try {
    const result = await verifyAndRotateRefreshToken(refreshToken);

    await createAuditLog({
      userId: result.user.id,
      action: AuditAction.TOKEN_REFRESH,
      ipAddress,
      userAgent,
    });

    return {
      token: result.accessToken,
      refreshToken: result.refreshToken,
    };
  } catch (error) {
    await createAuditLog({
      action: AuditAction.LOGIN_FAILED,
      ipAddress,
      userAgent,
      details: "Failed refresh token attempt",
    });
    throw error;
  }
}

export async function logoutUser(userId: string, refreshToken?: string, ipAddress?: string, userAgent?: string) {
  await revokeRefreshToken(userId, refreshToken);

  await createAuditLog({
    userId,
    action: AuditAction.LOGOUT,
    ipAddress,
    userAgent,
  });
}

export async function getUserProfile(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      studentId: true,
      firstName: true,
      middleName: true,
      lastName: true,
      dateOfBirth: true,
      gender: true,
      email: true,
      role: true,
      status: true,
    },
  });

  if (!user || user.status !== "ACTIVE") {
    throw new UnauthorizedError("User not found or account is inactive.");
  }

  return user;
}
