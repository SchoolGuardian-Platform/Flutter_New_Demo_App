import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { verifyRecordAccess } from "../middleware/recordAccess.middleware";
import { createAttendanceSchema, updateAttendanceSchema } from "../validators/attendance.validator";
import {
  createAttendanceController,
  getAttendanceByIdController,
  getAttendanceByStudentIdController,
  getAttendanceSummaryController,
  getAttendanceByTeacherController,
  updateAttendanceController,
  deleteAttendanceController,
  getGlobalAttendanceReportController
} from "../controllers/attendance.controller";

const router = Router();

router.use(authenticate);

// Teacher-only routes
router.post("/", authorize(Role.TEACHER), validateRequest(createAttendanceSchema), createAttendanceController);
router.get("/teacher", authorize(Role.TEACHER), getAttendanceByTeacherController);

// Admin global report
router.get("/report", authorize(Role.ADMIN), getGlobalAttendanceReportController);

// Routes requiring record access checks (Teacher, Student, Parent, Admin)
router.get("/student/:studentId", verifyRecordAccess("studentId"), getAttendanceByStudentIdController);
router.get("/student/:studentId/summary", verifyRecordAccess("studentId"), getAttendanceSummaryController);

// Single record routes
router.get("/:id", getAttendanceByIdController);
router.patch("/:id", authorize(Role.TEACHER), validateRequest(updateAttendanceSchema), updateAttendanceController);
router.delete("/:id", authorize(Role.TEACHER), deleteAttendanceController);

export default router;
