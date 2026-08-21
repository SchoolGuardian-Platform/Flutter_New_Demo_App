import dotenv from "dotenv";
import { prisma } from "../utils/prisma";
import { UnauthorizedError } from "../utils/errors";
import { generateAccessToken } from "../utils/jwt";
import { generateRandomToken, hashToken } from "../utils/hash";

dotenv.config();

const REFRESH_TOKEN_EXPIRES_IN_DAYS = parseInt(
  process.env.REFRESH_TOKEN_EXPIRES_IN_DAYS || "7",
  10
);

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
}

/**
 * Generates a random refresh token string, hashes it, computes expiration,
 * and saves the HASH to PostgreSQL.
 */
export async function createAndStoreRefreshToken(userId: string): Promise<{ token: string; expiresAt: Date }> {
  const token = generateRandomToken();
  const tokenHash = await hashToken(token);
  const expiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRES_IN_DAYS * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash,
      expiresAt,
    },
  });

  return { token, expiresAt };
}

/**
 * Validates an incoming raw refresh token, revokes it (token rotation),
 * and issues a brand-new access token + refresh token pair.
 */
export async function verifyAndRotateRefreshToken(rawRefreshToken: string) {
  const tokenHash = await hashToken(rawRefreshToken);

  const storedToken = await prisma.refreshToken.findUnique({
    where: { tokenHash },
    include: { user: true },
  });

  if (!storedToken) {
    throw new UnauthorizedError("Invalid or expired refresh token.", "INVALID_REFRESH_TOKEN");
  }

  // Check if token was already revoked or has expired
  if (storedToken.revokedAt !== null || storedToken.expiresAt < new Date()) {
    throw new UnauthorizedError("Invalid or expired refresh token.", "INVALID_REFRESH_TOKEN");
  }

  // Check user status
  if (storedToken.user.status !== "ACTIVE") {
    throw new UnauthorizedError("Account is not active.", "ACCOUNT_INACTIVE");
  }

  // Token Rotation: Revoke current refresh token
  await prisma.refreshToken.update({
    where: { id: storedToken.id },
    data: { revokedAt: new Date() },
  });

  // Issue new access token & new refresh token
  const newAccessToken = generateAccessToken(storedToken.user.id, storedToken.user.role);
  const newRefreshToken = await createAndStoreRefreshToken(storedToken.user.id);

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken.token,
    user: storedToken.user,
  };
}

/**
 * Revokes refresh token(s) upon user logout.
 */
export async function revokeRefreshToken(userId: string, rawRefreshToken?: string): Promise<void> {
  if (rawRefreshToken) {
    const tokenHash = await hashToken(rawRefreshToken);
    await prisma.refreshToken.updateMany({
      where: {
        userId,
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  } else {
    // Revoke all active tokens for the user
    await prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }
}