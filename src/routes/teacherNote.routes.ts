import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { createTeacherNoteSchema, updateTeacherNoteSchema } from "../validators/teacherNote.validator";
import {
  createTeacherNoteController,
  getTeacherNoteByIdController,
  getTeacherNotesByStudentIdController,
  getTeacherNotesByTeacherController,
  updateTeacherNoteController,
  deleteTeacherNoteController,
} from "../controllers/teacherNote.controller";

const router = Router();

router.use(authenticate);

// Teacher-specific endpoints
router.post("/", authorize(Role.TEACHER), validateRequest(createTeacherNoteSchema), createTeacherNoteController);
router.get("/teacher", authorize(Role.TEACHER), getTeacherNotesByTeacherController);

// Student/Parent/Teacher access endpoints
router.get("/student/:studentId", getTeacherNotesByStudentIdController);
router.get("/:id", getTeacherNoteByIdController);

// Teacher update/delete endpoints
router.patch("/:id", authorize(Role.TEACHER), validateRequest(updateTeacherNoteSchema), updateTeacherNoteController);
router.delete("/:id", authorize(Role.TEACHER), deleteTeacherNoteController);

export default router;
