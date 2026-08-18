import { Request, Response, NextFunction } from "express";
import { Role, AuditAction } from "@prisma/client";
import { ForbiddenError, UnauthorizedError } from "../utils/errors";
import { createAuditLog } from "../service/audit.service";

/**
 * Role-based authorization middleware factory.
 * Usage: authorize("ADMIN"), authorize("ADMIN", "TEACHER")
 */
export function authorize(...allowedRoles: Role[]) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError();
      }

      if (!allowedRoles.includes(req.user.role)) {
        await createAuditLog({
          userId: req.user.id,
          action: AuditAction.ACCESS_DENIED,
          ipAddress: req.ip,
          userAgent: req.get("user-agent"),
          details: `Role ${req.user.role} attempted unauthorized access to ${req.originalUrl}`,
        });

        throw new ForbiddenError("You do not have permission to perform this action.");
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}

export const requireRole = authorize;
