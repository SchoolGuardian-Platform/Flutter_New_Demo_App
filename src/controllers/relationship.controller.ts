import { Request, Response, NextFunction } from "express";
import {
  requestParentStudentRelationship,
  getPendingRelationships,
  getRelationshipById,
  approveRelationship,
  rejectRelationship,
  getParentVerifiedStudents,
  getStudentVerifiedGuardians,
} from "../service/relationship.service";
import { CreateRelationshipInput } from "../validators/relationship.validator";
import { RejectionInput } from "../validators/admin.validator";

/**
 * POST /parents/relationships (or POST /parents/link-student)
 */
export async function requestRelationshipController(
  req: Request<{}, {}, CreateRelationshipInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const parentId = req.user!.id;
    const relationship = await requestParentStudentRelationship(
      parentId,
      req.body,
      req.ip,
      req.get("user-agent")
    );
    res.status(201).json({ data: relationship });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /admin/relationships/pending
 */
export async function getPendingRelationshipsController(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const pending = await getPendingRelationships();
    res.status(200).json({ data: pending });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /admin/relationships/:id
 */
export async function getRelationshipByIdController(
  req: Request<{ id: string }>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const rel = await getRelationshipById(req.params.id as string);
    res.status(200).json({ data: rel });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /admin/relationships/:id/approve
 */
export async function approveRelationshipController(
  req: Request<{ id: string }>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const adminId = req.user!.id;
    const updated = await approveRelationship(
      adminId,
      req.params.id as string,
      req.ip,
      req.get("user-agent")
    );
    res.status(200).json({ data: updated });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /admin/relationships/:id/reject
 */
export async function rejectRelationshipController(
  req: Request<{ id: string }, {}, RejectionInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const adminId = req.user!.id;
    const updated = await rejectRelationship(
      adminId,
      req.params.id as string,
      req.body?.reason,
      req.ip,
      req.get("user-agent")
    );
    res.status(200).json({ data: updated });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /parents/my-students
 */
export async function getParentStudentsController(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const parentId = req.user!.id;
    const students = await getParentVerifiedStudents(parentId);
    res.status(200).json({ data: students });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /students/my-guardians
 */
export async function getStudentGuardiansController(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const studentId = req.user!.id;
    const guardians = await getStudentVerifiedGuardians(studentId);
    res.status(200).json({ data: guardians });
  } catch (error) {
    next(error);
  }
}
