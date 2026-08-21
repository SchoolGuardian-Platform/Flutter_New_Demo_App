import { Role, RelationshipStatus, AuditAction } from "@prisma/client";
import { prisma } from "../utils/prisma";
import { NotFoundError, BadRequestError } from "../utils/errors";
import { createAuditLog } from "./audit.service";
import { CreateRelationshipInput } from "../validators/relationship.validator";

export async function requestParentStudentRelationship(
  parentId: string,
  input: CreateRelationshipInput,
  ipAddress?: string,
  userAgent?: string
) {
  // Find student by ID or email
  const student = await prisma.user.findFirst({
    where: {
      role: Role.STUDENT,
      ...(input.studentId ? { studentId: input.studentId } : {}),
      ...(input.studentEmail ? { email: input.studentEmail.toLowerCase().trim() } : {}),
    },
  });

  if (!student) {
    throw new NotFoundError("Student record not found.");
  }

  // Check for duplicate relationship request
  const existing = await prisma.parentStudentRelationship.findUnique({
    where: {
      parentId_studentId_relationshipType: {
        parentId,
        studentId: student.id,
        relationshipType: input.relationshipType,
      },
    },
  });

  if (existing) {
    throw new BadRequestError("A relationship request already exists for this parent, student, and relationship type.");
  }

  // Create relationship with status = PENDING
  const relationship = await prisma.parentStudentRelationship.create({
    data: {
      parentId,
      studentId: student.id,
      relationshipType: input.relationshipType,
      status: RelationshipStatus.PENDING,
    },
    include: {
      student: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true },
      },
    },
  });

  await createAuditLog({
    userId: parentId,
    action: AuditAction.PARENT_STUDENT_REQUESTED,
    ipAddress,
    userAgent,
    details: `Parent ${parentId} requested ${input.relationshipType} connection to student ${student.id} (${student.email})`,
  });

  return relationship;
}

export async function getPendingRelationships() {
  return await prisma.parentStudentRelationship.findMany({
    where: {
      status: RelationshipStatus.PENDING,
    },
    include: {
      parent: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true, status: true },
      },
      student: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true, status: true },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });
}

export async function getRelationshipById(id: string) {
  const relationship = await prisma.parentStudentRelationship.findUnique({
    where: { id },
    include: {
      parent: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true },
      },
      student: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true },
      },
      verifier: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true },
      },
    },
  });

  if (!relationship) {
    throw new NotFoundError("Parent-Student relationship record not found.");
  }

  return relationship;
}

export async function approveRelationship(
  adminId: string,
  relationshipId: string,
  ipAddress?: string,
  userAgent?: string
) {
  const rel = await prisma.parentStudentRelationship.findUnique({
    where: { id: relationshipId },
  });

  if (!rel) {
    throw new NotFoundError("Relationship request not found.");
  }

  if (rel.status !== RelationshipStatus.PENDING) {
    throw new BadRequestError(`Cannot approve relationship. Current status is ${rel.status}.`);
  }

  const updated = await prisma.parentStudentRelationship.update({
    where: { id: relationshipId },
    data: {
      status: RelationshipStatus.APPROVED,
      verifiedBy: adminId,
      verifiedAt: new Date(),
    },
    include: {
      parent: { select: { id: true, firstName: true, middleName: true, lastName: true, email: true } },
      student: { select: { id: true, firstName: true, middleName: true, lastName: true, email: true } },
    },
  });

  await createAuditLog({
    userId: adminId,
    action: AuditAction.PARENT_STUDENT_APPROVED,
    ipAddress,
    userAgent,
    details: `Admin ${adminId} approved relationship ${relationshipId} (Parent: ${rel.parentId}, Student: ${rel.studentId}, Type: ${rel.relationshipType})`,
  });

  return updated;
}

export async function rejectRelationship(
  adminId: string,
  relationshipId: string,
  reason?: string,
  ipAddress?: string,
  userAgent?: string
) {
  const rel = await prisma.parentStudentRelationship.findUnique({
    where: { id: relationshipId },
  });

  if (!rel) {
    throw new NotFoundError("Relationship request not found.");
  }

  if (rel.status !== RelationshipStatus.PENDING) {
    throw new BadRequestError(`Cannot reject relationship. Current status is ${rel.status}.`);
  }

  const updated = await prisma.parentStudentRelationship.update({
    where: { id: relationshipId },
    data: {
      status: RelationshipStatus.REJECTED,
      verifiedBy: adminId,
      verifiedAt: new Date(),
    },
    include: {
      parent: { select: { id: true, firstName: true, middleName: true, lastName: true, email: true } },
      student: { select: { id: true, firstName: true, middleName: true, lastName: true, email: true } },
    },
  });

  await createAuditLog({
    userId: adminId,
    action: AuditAction.PARENT_STUDENT_REJECTED,
    ipAddress,
    userAgent,
    details: `Admin ${adminId} rejected relationship ${relationshipId}. Reason: ${reason || "No reason specified"}`,
  });

  return updated;
}

export async function getParentVerifiedStudents(parentId: string) {
  const links = await prisma.parentStudentRelationship.findMany({
    where: {
      parentId,
      status: RelationshipStatus.APPROVED,
    },
    include: {
      student: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true, status: true },
      },
    },
  });

  return links.map((link: any) => ({
    relationshipId: link.id,
    relationshipType: link.relationshipType,
    student: link.student,
    verifiedAt: link.verifiedAt,
  }));
}

export async function getStudentVerifiedGuardians(studentId: string) {
  const links = await prisma.parentStudentRelationship.findMany({
    where: {
      studentId,
      status: RelationshipStatus.APPROVED,
    },
    include: {
      parent: {
        select: { id: true, firstName: true, middleName: true, lastName: true, email: true, status: true },
      },
    },
  });

  return links.map((link: any) => ({
    relationshipId: link.id,
    relationshipType: link.relationshipType,
    guardian: link.parent,
    verifiedAt: link.verifiedAt,
  }));
}
