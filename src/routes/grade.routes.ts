import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { verifyRecordAccess } from "../middleware/recordAccess.middleware";
import { createGradeSchema, updateGradeSchema } from "../validators/grade.validator";
import {
  createGradeController,
  getGradeByIdController,
  getGradesByStudentIdController,
  getGradeSummaryController,
  getGradesByTeacherController,
  updateGradeController,
  deleteGradeController,
  getGlobalGradeReportController
} from "../controllers/grade.controller";

const router = Router();

router.use(authenticate);


router.post("/", authorize(Role.TEACHER), validateRequest(createGradeSchema), createGradeController);
router.get("/teacher", authorize(Role.TEACHER), getGradesByTeacherController);


router.get("/report", authorize(Role.ADMIN), getGlobalGradeReportController);

router.get("/student/:studentId", verifyRecordAccess("studentId"), getGradesByStudentIdController);
router.get("/student/:studentId/summary", verifyRecordAccess("studentId"), getGradeSummaryController);


router.get("/:id", getGradeByIdController);
router.patch("/:id", authorize(Role.TEACHER), validateRequest(updateGradeSchema), updateGradeController);
router.put("/:id", authorize(Role.TEACHER), validateRequest(updateGradeSchema), updateGradeController);
router.delete("/:id", authorize(Role.TEACHER), deleteGradeController);

export default router;
