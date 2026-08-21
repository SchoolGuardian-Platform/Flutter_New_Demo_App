import { Role, AccountStatus, AuditAction } from "@prisma/client";
import { prisma } from "../utils/prisma";
import { NotFoundError, BadRequestError } from "../utils/errors";
import { createAuditLog } from "./audit.service";
import { generateStudentId } from "../utils/date";

export async function getPendingUsersByRole(role: Role) {
  return await prisma.user.findMany({
    where: {
      role,
      status: AccountStatus.PENDING,
      emailVerifiedAt: { not: null },
    },
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
      createdAt: true,
    },
    orderBy: {
      createdAt: "desc",
    },
  });
}

export async function getVerifiedUsersByRole(role: Role) {
  return await prisma.user.findMany({
    where: {
      role,
      status: AccountStatus.ACTIVE,
    },
    select: {
      id: true,
      studentId: true,
      firstName: true,
      middleName: true,
      lastName: true,
      email: true,
      role: true,
      status: true,
      createdAt: true,
    },
    orderBy: {
      createdAt: "desc",
    },
  });
}

export async function getUserByIdAndRole(userId: string, role?: Role) {
  const user = await prisma.user.findFirst({
    where: {
      id: userId,
      ...(role ? { role } : {}),
    },
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
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw new NotFoundError("User record not found.");
  }

  return user;
}

export async function approveUserRegistration(
  adminId: string,
  userId: string,
  targetRole: Role,
  ipAddress?: string,
  userAgent?: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user || user.role !== targetRole) {
    throw new NotFoundError(`User record not found for role ${targetRole}.`);
  }

  if (user.status !== AccountStatus.PENDING) {
    throw new BadRequestError(`Cannot approve user. Current status is ${user.status}.`);
  }

  if (!user.emailVerifiedAt) {
    throw new BadRequestError(`Cannot approve user. User must verify their email first.`);
  }

  // Generate studentId if approving a student and studentId is not set
  let generatedId: string | undefined = undefined;
  let schoolCode: string | undefined = undefined;
  if (targetRole === Role.STUDENT) {
    if (!user.studentId) {
      const studentCount = await prisma.user.count({
        where: { role: Role.STUDENT, studentId: { not: null } },
      });
      generatedId = generateStudentId(studentCount + 1);
    }
    schoolCode = `ABC-001`;
  }

  // Update status PENDING -> ACTIVE inside transaction
  const updatedUser = await prisma.$transaction(async (tx) => {
    return await tx.user.update({
      where: { id: userId },
      data: {
        status: AccountStatus.ACTIVE,
        ...(generatedId ? { studentId: generatedId } : {}),
        ...(schoolCode ? { schoolCode } : {}),
      },
      select: {
        id: true,
        studentId: true,
        schoolCode: true,
        firstName: true,
        middleName: true,
        lastName: true,
        dateOfBirth: true,
        gender: true,
        email: true,
        role: true,
        status: true,
        updatedAt: true,
      },
    });
  });


  // Determine AuditAction
  let auditAction: AuditAction = AuditAction.STUDENT_APPROVED;
  if (targetRole === Role.TEACHER) auditAction = AuditAction.TEACHER_APPROVED;
  if (targetRole === Role.PARENT) auditAction = AuditAction.PARENT_APPROVED;

  await createAuditLog({
    userId: adminId,
    action: auditAction,
    ipAddress,
    userAgent,
    details: `Admin ${adminId} approved ${targetRole} registration for user ${userId} (${user.email})`,
  });

  return updatedUser;
}

export async function rejectUserRegistration(
  adminId: string,
  userId: string,
  targetRole: Role,
  reason?: string,
  ipAddress?: string,
  userAgent?: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user || user.role !== targetRole) {
    throw new NotFoundError(`User record not found for role ${targetRole}.`);
  }

  if (user.status !== AccountStatus.PENDING) {
    throw new BadRequestError(`Cannot reject user. Current status is ${user.status}.`);
  }

  if (!user.emailVerifiedAt) {
    throw new BadRequestError(`Cannot reject user. User must verify their email first.`);
  }

  // Update status PENDING -> REJECTED inside transaction
  const updatedUser = await prisma.$transaction(async (tx) => {
    return await tx.user.update({
      where: { id: userId },
      data: { status: AccountStatus.REJECTED },
      select: {
        id: true,
        studentId: true,
        schoolCode: true,
        firstName: true,
        middleName: true,
        lastName: true,
        email: true,
        role: true,
        status: true,
        updatedAt: true,
      },
    });
  });


  // Determine AuditAction
  let auditAction: AuditAction = AuditAction.STUDENT_REJECTED;
  if (targetRole === Role.TEACHER) auditAction = AuditAction.TEACHER_REJECTED;
  if (targetRole === Role.PARENT) auditAction = AuditAction.PARENT_REJECTED;

  await createAuditLog({
    userId: adminId,
    action: auditAction,
    ipAddress,
    userAgent,
    details: `Admin ${adminId} rejected ${targetRole} user ${userId}. Reason: ${reason || "No reason specified"}`,
  });

  return updatedUser;
}

export async function deleteUser(adminId: string, userId: string, ipAddress?: string, userAgent?: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw new NotFoundError("User not found.");
  }

  if (user.role === Role.ADMIN) {
    throw new BadRequestError("Cannot delete an Admin user.");
  }

  await prisma.user.delete({
    where: { id: userId },
  });

  // Use a generic log or an existing one
  await createAuditLog({
    userId: adminId,
    action: AuditAction.STUDENT_REJECTED, // closest generic action available
    ipAddress,
    userAgent,
    details: `Admin ${adminId} deleted user ${userId} (${user.email}) - Role: ${user.role}`,
  });

  return { message: "User deleted successfully." };
}
