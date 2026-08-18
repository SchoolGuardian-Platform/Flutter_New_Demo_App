import { Router } from "express";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { Role } from "@prisma/client";
import { validateRequest } from "../middleware/validate.middleware";
import {
  createClassSchema,
  createSubjectSchema,
  assignStudentSchema,
  assignTeacherSchema,
} from "../validators/schoolManagement.validator";
import {
  getClassesController,
  getSubjectsController,
  createClassController,
  createSubjectController,
  deleteClassController,
  deleteSubjectController,
  assignStudentController,
  deleteStudentAssignmentController,
  assignTeacherController,
  deleteTeacherAssignmentController,
} from "../controllers/schoolManagement.controller";

const router = Router();

// Only ADMIN can access these routes
router.use(authenticate);

// Both ADMIN and TEACHER can view classes & subjects
router.get("/classes", authorize(Role.ADMIN, Role.TEACHER), getClassesController);
router.get("/subjects", authorize(Role.ADMIN, Role.TEACHER), getSubjectsController);

// Mutation endpoints restricted to ADMIN
router.use(authorize(Role.ADMIN));

router.post("/classes", validateRequest(createClassSchema), createClassController);
router.post("/subjects", validateRequest(createSubjectSchema), createSubjectController);

router.delete("/classes/:id", deleteClassController);
router.delete("/subjects/:id", deleteSubjectController);

router.post("/assign-student", validateRequest(assignStudentSchema), assignStudentController);
router.delete("/assign-student/:id", deleteStudentAssignmentController);

router.post("/assign-teacher", validateRequest(assignTeacherSchema), assignTeacherController);
router.delete("/assign-teacher/:id", deleteTeacherAssignmentController);

export default router;
