import { Request, Response, NextFunction } from "express";
import { Role } from "@prisma/client";
import {
  getPendingUsersByRole,
  getUserByIdAndRole,
  getVerifiedUsersByRole,
  approveUserRegistration,
  rejectUserRegistration,
  deleteUser,
} from "../service/admin.service";
import { getAuditLogs } from "../service/audit.service";
import { RejectionInput } from "../validators/admin.validator";

// Helper function factory for handling pending list requests
function makeGetPendingController(role: Role) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const pendingUsers = await getPendingUsersByRole(role);
      res.status(200).json({ data: pendingUsers });
    } catch (error) {
      next(error);
    }
  };
}

// Helper function factory for handling single user fetch
function makeGetByIdController(role: Role) {
  return async (req: Request<{ id: string }>, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = await getUserByIdAndRole(req.params.id as string, role);
      res.status(200).json({ data: user });
    } catch (error) {
      next(error);
    }
  };
}

// Helper function factory for approving user registration
function makeApproveController(role: Role) {
  return async (req: Request<{ id: string }>, res: Response, next: NextFunction): Promise<void> => {
    try {
      const adminId = req.user!.id;
      const updatedUser = await approveUserRegistration(
        adminId,
        req.params.id as string,
        role,
        req.ip,
        req.get("user-agent")
      );
      res.status(200).json({ data: updatedUser });
    } catch (error) {
      next(error);
    }
  };
}

// Helper function factory for rejecting user registration
function makeRejectController(role: Role) {
  return async (req: Request<{ id: string }, {}, RejectionInput>, res: Response, next: NextFunction): Promise<void> => {
    try {
      const adminId = req.user!.id;
      const updatedUser = await rejectUserRegistration(
        adminId,
        req.params.id as string,
        role,
        req.body?.reason,
        req.ip,
        req.get("user-agent")
      );
      res.status(200).json({ data: updatedUser });
    } catch (error) {
      next(error);
    }
  };
}

// Student Approval Handlers
export const getPendingStudentsController = makeGetPendingController(Role.STUDENT);
export const getStudentByIdController = makeGetByIdController(Role.STUDENT);
export const approveStudentController = makeApproveController(Role.STUDENT);
export const rejectStudentController = makeRejectController(Role.STUDENT);

// Teacher Approval Handlers
export const getPendingTeachersController = makeGetPendingController(Role.TEACHER);
export const getTeacherByIdController = makeGetByIdController(Role.TEACHER);
export const approveTeacherController = makeApproveController(Role.TEACHER);
export const rejectTeacherController = makeRejectController(Role.TEACHER);


export const getPendingParentsController = makeGetPendingController(Role.PARENT);
export const getParentByIdController = makeGetByIdController(Role.PARENT);
export const approveParentController = makeApproveController(Role.PARENT);
export const rejectParentController = makeRejectController(Role.PARENT);


export async function getVerifiedUsersController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const role = req.query.role as Role;
    if (!role) {
      res.status(400).json({ message: "Role query parameter is required." });
      return;
    }

    const users = await getVerifiedUsersByRole(role);
    res.status(200).json({ data: users });
  } catch (error) {
    next(error);
  }
}

export async function deleteUserController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const adminId = req.user!.id;
    const userId = req.params.id;

    const result = await deleteUser(adminId, userId as string, req.ip, req.get("user-agent"));
    res.status(200).json({ message: result.message });
  } catch (error) {
    next(error);
  }
}

export async function getAuditLogsController(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;
    const action = req.query.action as any; // Need to cast as AuditAction
    const userId = req.query.userId as string | undefined;

    const result = await getAuditLogs(limit, offset, action, userId);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
}
