import { prisma } from "../utils/prisma";
import { generateRandomToken, hashToken, hashPassword } from "../utils/hash";
import { isStrongPassword } from "../utils/password";
import { BadRequestError } from "../utils/errors";
import { emailService } from "./email.service";

const TOKEN_EXPIRATION_MINUTES = 30;

/**
 * Initiates the password reset flow:
 * 1. Generates cryptographically secure reset token.
 * 2. Hashes token before DB storage.
 * 3. Sets expiration to 30 minutes.
 * 4. Sends reset email without logging the raw token.
 */
export async function requestPasswordReset(email: string): Promise<{ message: string }> {
  const normalizedEmail = email.toLowerCase().trim();

  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });

  if (user) {
    const rawToken = generateRandomToken();
    const tokenHash = await hashToken(rawToken);
    const expiresAt = new Date(Date.now() + TOKEN_EXPIRATION_MINUTES * 60 * 1000);

    // Delete any old unused tokens for this user
    await prisma.passwordResetToken.deleteMany({
      where: {
        userId: user.id,
        usedAt: null,
      },
    });

    // Create new password reset token
    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
      },
    });

    const baseUrl = process.env.RESET_PASSWORD_URL || "http://localhost:3000/reset-password";
    const resetLink = `${baseUrl}?token=${rawToken}`;

    // Send email (never log raw token)
    await emailService.sendPasswordResetEmail(user.email, resetLink);
  }

  return {
    message: "If an account with that email exists, a password reset link has been sent.",
  };
}

/**
 * Completes password reset:
 * 1. Validates and hashes incoming token.
 * 2. Checks token existence, expiration, and usedAt status.
 * 3. Validates new password strength.
 * 4. Atomically updates User.passwordHash and marks token as used.
 * 5. Invalidates all active refresh tokens for the user using existing token service logic.
 */
export async function confirmPasswordReset(rawToken: string, newPassword: string): Promise<{ message: string }> {
  if (!rawToken || typeof rawToken !== "string") {
    throw new BadRequestError("Invalid or expired reset token.", "INVALID_OR_EXPIRED_TOKEN");
  }

  if (!newPassword || typeof newPassword !== "string") {
    throw new BadRequestError("New password is required.", "BAD_REQUEST");
  }

  if (!isStrongPassword(newPassword)) {
    throw new BadRequestError(
      "Password must be at least 8 characters long and include an uppercase letter, lowercase letter, number, and special character.",
      "WEAK_PASSWORD"
    );
  }

  const tokenHash = await hashToken(rawToken);

  const resetTokenRecord = await prisma.passwordResetToken.findUnique({
    where: { tokenHash },
    include: { user: true },
  });

  // Validation: existence, expiration, and single-use checks
  if (
    !resetTokenRecord ||
    resetTokenRecord.usedAt !== null ||
    resetTokenRecord.expiresAt < new Date()
  ) {
    throw new BadRequestError("Invalid or expired reset token.", "INVALID_OR_EXPIRED_TOKEN");
  }

  const newPasswordHash = await hashPassword(newPassword);

  // Execute updates atomically inside a Prisma transaction
  await prisma.$transaction(async (tx) => {
    // 1. Update User passwordHash
    await tx.user.update({
      where: { id: resetTokenRecord.userId },
      data: { passwordHash: newPasswordHash },
    });

    // 2. Mark reset token as used
    await tx.passwordResetToken.update({
      where: { id: resetTokenRecord.id },
      data: { usedAt: new Date() },
    });

    // 3. Invalidate all active refresh tokens for the user
    await tx.refreshToken.updateMany({
      where: {
        userId: resetTokenRecord.userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  });

  return {
    message: "Password reset successful.",
  };
}
