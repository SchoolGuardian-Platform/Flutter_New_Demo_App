import crypto from "crypto";
import { prisma } from "../utils/prisma";
import { emailService } from "./email.service";
import { hashToken } from "../utils/hash";
import { BadRequestError } from "../utils/errors";
import { createAuditLog } from "./audit.service";
import { AuditAction } from "@prisma/client";

const VERIFICATION_TOKEN_EXPIRES_IN_MINUTES = 30;

/**
 * Generates a verification token, saves its hash to DB, and sends the email.
 */
export async function generateAndSendVerificationToken(user: { id: string; email: string; firstName: string }) {
  // Generate a cryptographically secure random token
  const rawToken = crypto.randomBytes(32).toString("hex");
  const hashedToken = await hashToken(rawToken);

  const expiresAt = new Date(Date.now() + VERIFICATION_TOKEN_EXPIRES_IN_MINUTES * 60 * 1000);

  // Store the hashed token in the database
  await prisma.emailVerificationToken.create({
    data: {
      userId: user.id,
      tokenHash: hashedToken,
      expiresAt,
    },
  });

  // Construct verification URL
  const baseUrl = process.env.EMAIL_VERIFICATION_URL || "http://localhost:3000/verify-email";
  const verificationLink = `${baseUrl}?token=${rawToken}`;

  // Send verification email
  await emailService.sendVerificationEmail(user.email, user.firstName, verificationLink);

  // Audit log
  await createAuditLog({
    userId: user.id,
    action: AuditAction.EMAIL_VERIFICATION_SENT,
    details: `Email verification link sent to ${user.email}`,
  });
}

/**
 * Validates a verification token and updates the user's emailVerifiedAt field.
 */
export async function verifyEmailToken(rawToken: string, ipAddress?: string, userAgent?: string) {
  const hashedToken = await hashToken(rawToken);

  const tokenRecord = await prisma.emailVerificationToken.findUnique({
    where: { tokenHash: hashedToken },
    include: { user: true },
  });

  if (!tokenRecord) {
    throw new BadRequestError("Invalid or expired verification token.", "INVALID_OR_EXPIRED_TOKEN");
  }

  if (tokenRecord.usedAt || tokenRecord.expiresAt < new Date()) {
    throw new BadRequestError("Invalid or expired verification token.", "INVALID_OR_EXPIRED_TOKEN");
  }

  if (tokenRecord.user.emailVerifiedAt) {
    throw new BadRequestError("Email is already verified.", "EMAIL_ALREADY_VERIFIED");
  }

  // Use a transaction to mark the token as used and update the user
  await prisma.$transaction(async (tx) => {
    await tx.emailVerificationToken.update({
      where: { id: tokenRecord.id },
      data: { usedAt: new Date() },
    });

    await tx.user.update({
      where: { id: tokenRecord.userId },
      data: { 
        emailVerifiedAt: new Date(),
        status: "PENDING"
      },
    });
  });

  await createAuditLog({
    userId: tokenRecord.userId,
    action: AuditAction.EMAIL_VERIFIED,
    ipAddress,
    userAgent,
    details: `Email verified successfully for user ${tokenRecord.userId}`,
  });
}

/**
 * Resends a verification token if the account requires it.
 */
export async function resendVerificationToken(email: string, ipAddress?: string, userAgent?: string) {
  const normalizedEmail = email.toLowerCase().trim();

  const user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    select: { id: true, email: true, firstName: true, emailVerifiedAt: true },
  });

  // If user doesn't exist, we just return safely without error to avoid revealing account existence
  if (!user) {
    return;
  }

  // If already verified, we do not throw an error because that reveals existence
  // We just return safely
  if (user.emailVerifiedAt) {
    return;
  }

  // Invalidate any previous unused tokens
  await prisma.emailVerificationToken.updateMany({
    where: {
      userId: user.id,
      usedAt: null,
      expiresAt: { gt: new Date() },
    },
    data: {
      usedAt: new Date(), // Marking them as used effectively invalidates them
    },
  });

  // Generate and send a new token
  await generateAndSendVerificationToken(user);
}
