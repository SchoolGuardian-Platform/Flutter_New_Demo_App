import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { createRelationshipSchema } from "../validators/relationship.validator";
import {
  requestRelationshipController,
  getParentStudentsController,
} from "../controllers/relationship.controller";

const router = Router();

// Protect ALL parent endpoints with authenticate + authorize("PARENT")
router.use(authenticate, authorize(Role.PARENT));

router.post("/relationships", validateRequest(createRelationshipSchema), requestRelationshipController);
router.post("/link-student", validateRequest(createRelationshipSchema), requestRelationshipController);
router.get("/my-students", getParentStudentsController);

export default router;
