import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { uploadUsageSchema, updateLimitSchema } from "../validators/wellbeing.validator";
import {
  uploadUsageController,
  getWellbeingMeController,
  getWellbeingDailyController,
  getWellbeingWeeklyController,
  updateLimitController,
  getLimitController,
} from "../controllers/wellbeing.controller";

const router = Router();

router.use(authenticate);

// ------------------------------------------
// Student Specific Routes
// ------------------------------------------

// Upload usage (STUDENT only)
router.post("/usage", authorize(Role.STUDENT), validateRequest(uploadUsageSchema), uploadUsageController);

// Get own usage (STUDENT only)
router.get("/me", authorize(Role.STUDENT), getWellbeingMeController);

router.get("/students/:studentId", getWellbeingDailyController);
router.get("/students/:studentId/daily", getWellbeingDailyController);

router.get("/students/:studentId/weekly", getWellbeingWeeklyController);

router.put("/students/:studentId/limit", authorize(Role.PARENT), validateRequest(updateLimitSchema), updateLimitController);


router.get("/students/:studentId/limit", getLimitController);

export default router;
