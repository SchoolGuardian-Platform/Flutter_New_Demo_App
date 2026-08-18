import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { rejectionSchema } from "../validators/admin.validator";
import {
  getPendingStudentsController,
  getStudentByIdController,
  approveStudentController,
  rejectStudentController,
  getPendingTeachersController,
  getTeacherByIdController,
  approveTeacherController,
  rejectTeacherController,
  getPendingParentsController,
  getParentByIdController,
  approveParentController,
  rejectParentController,
  getVerifiedUsersController,
  deleteUserController,
  getAuditLogsController,
} from "../controllers/admin.controller";
import {
  getPendingRelationshipsController,
  getRelationshipByIdController,
  approveRelationshipController,
  rejectRelationshipController,
} from "../controllers/relationship.controller";

const router = Router();

// Protect ALL admin routes with authenticate + authorize("ADMIN")
router.use(authenticate);

// General User Management (Both ADMIN and TEACHER can view verified users)
router.get("/users/verified", authorize(Role.ADMIN, Role.TEACHER), getVerifiedUsersController);

router.use(authorize(Role.ADMIN));
router.delete("/users/:id", deleteUserController);

// Security & Audit Monitoring
router.get("/audit-logs", getAuditLogsController);

// Student Registrations Approval Endpoints
router.get("/students/pending", getPendingStudentsController);
router.get("/students/:id", getStudentByIdController);
router.patch("/students/:id/approve", approveStudentController);
router.patch("/students/:id/reject", validateRequest(rejectionSchema), rejectStudentController);

// Teacher Registrations Approval Endpoints
router.get("/teachers/pending", getPendingTeachersController);
router.get("/teachers/:id", getTeacherByIdController);
router.patch("/teachers/:id/approve", approveTeacherController);
router.patch("/teachers/:id/reject", validateRequest(rejectionSchema), rejectTeacherController);

// Parent Registrations Approval Endpoints
router.get("/parents/pending", getPendingParentsController);
router.get("/parents/:id", getParentByIdController);
router.patch("/parents/:id/approve", approveParentController);
router.patch("/parents/:id/reject", validateRequest(rejectionSchema), rejectParentController);

// Parent-Student Relationship Verification Endpoints
router.get("/relationships/pending", getPendingRelationshipsController);
router.get("/relationships/:id", getRelationshipByIdController);
router.patch("/relationships/:id/approve", approveRelationshipController);
router.patch("/relationships/:id/reject", validateRequest(rejectionSchema), rejectRelationshipController);

export default router;
