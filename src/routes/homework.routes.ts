import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { createHomeworkSchema, updateHomeworkSchema } from "../validators/homework.validator";
import {
  createHomeworkController,
  getMyHomeworkController,
  getHomeworkByIdController,
  getHomeworksByStudentIdController,
  getHomeworksByClassIdController,
  getHomeworksByTeacherController,
  updateHomeworkController,
  deleteHomeworkController,
} from "../controllers/homework.controller";

const router = Router();

router.use(authenticate);

// Teacher-specific endpoints
router.post("/", authorize(Role.TEACHER), validateRequest(createHomeworkSchema), createHomeworkController);
router.get("/teacher", authorize(Role.TEACHER), getHomeworksByTeacherController);

// Student's own homework (based on enrolled class) — no studentId in URL
router.get("/student/me", authorize(Role.STUDENT), getMyHomeworkController);

// Student/Parent/Teacher access endpoints
router.get("/student/:studentId", getHomeworksByStudentIdController);
router.get("/class/:classId", getHomeworksByClassIdController);
router.get("/:id", getHomeworkByIdController);

// Teacher update/delete endpoints
router.patch("/:id", authorize(Role.TEACHER), validateRequest(updateHomeworkSchema), updateHomeworkController);
router.delete("/:id", authorize(Role.TEACHER), deleteHomeworkController);

export default router;
