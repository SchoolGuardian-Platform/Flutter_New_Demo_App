import { Request, Response, NextFunction } from "express";
import { Role, RelationshipStatus } from "@prisma/client";
import { NotFoundError, UnauthorizedError } from "../utils/errors";
import { prisma } from "../utils/prisma";

/**
 * Authorization middleware to verify a Parent user has an APPROVED relationship with a requested Student.
 * SECURITY: If relationship does NOT exist or is NOT approved, returns HTTP 404 NOT_FOUND
 * to avoid exposing whether the student exists.
 */
export function verifyParentStudentAccess(paramName = "studentId") {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError();
      }

      // Admins bypass parent-student relationship check
      if (req.user.role === Role.ADMIN) {
        return next();
      }

      // Non-parents are rejected with 404 for student-scoped endpoints
      if (req.user.role !== Role.PARENT) {
        throw new NotFoundError("Resource not found.");
      }

      const studentId = req.params[paramName] as string;
      if (!studentId) {
        throw new NotFoundError("Resource not found.");
      }

      // Check for APPROVED relationship in database
      const relationship = await prisma.parentStudentRelationship.findFirst({
        where: {
          parentId: req.user.id,
          studentId: studentId,
          status: RelationshipStatus.APPROVED,
        },
      });

      if (!relationship) {
        // Return HTTP 404 NOT_FOUND to hide student existence from unlinked parents
        throw new NotFoundError("Resource not found.");
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}
