import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { getStudentGuardiansController } from "../controllers/relationship.controller";

const router = Router();

// Protect ALL student endpoints with authenticate + authorize("STUDENT")
router.use(authenticate, authorize(Role.STUDENT));

router.get("/my-guardians", getStudentGuardiansController);

export default router;
