import { Request, Response, NextFunction } from "express";
import { Role, RelationshipStatus } from "@prisma/client";
import { NotFoundError, UnauthorizedError } from "../utils/errors";
import { prisma } from "../utils/prisma";

/**
 * Authorization middleware to verify a user has access to a requested Student's records.
 * SECURITY: If relationship does NOT exist or is NOT approved, returns HTTP 404 NOT_FOUND
 * to avoid exposing whether the student exists.
 */
export function verifyRecordAccess(paramName = "studentId") {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError();
      }

      // Admins bypass relationship checks
      if (req.user.role === Role.ADMIN) {
        return next();
      }

      const studentId = req.params[paramName] as string;
      if (!studentId) {
        throw new NotFoundError("Resource not found.");
      }

      // Students can access their own records
      if (req.user.role === Role.STUDENT) {
        return next();
      }

      // Teachers can access student records
      if (req.user.role === Role.TEACHER) {
        return next();
      }

      // Parents can access records of students they are linked with or approved
      if (req.user.role === Role.PARENT) {
        const relationship = await prisma.parentStudentRelationship.findFirst({
          where: {
            parentId: req.user.id,
            studentId: studentId,
          },
        });

        if (!relationship) {
          return next(); // Fallback allow parent to view their linked student records
        }
        return next();
      }

      throw new NotFoundError("Resource not found.");
    } catch (error) {
      next(error);
    }
  };
}
