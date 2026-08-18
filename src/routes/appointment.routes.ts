import { Router } from "express";
import { Role } from "@prisma/client";
import { authenticate } from "../middleware/auth.middleware";
import { authorize } from "../middleware/role.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { 
  createSlotSchema, 
  bookAppointmentSchema, 
  updateAppointmentStatusSchema 
} from "../validators/appointment.validator";
import {
  createSlotController,
  closeSlotController,
  getTeacherAppointmentsController,
  updateAppointmentStatusController,
  getAvailableSlotsController,
  bookAppointmentController,
  cancelAppointmentController,
  getParentAppointmentsController
} from "../controllers/appointment.controller";

const router = Router();

router.use(authenticate);

// ==========================================
// TEACHER ROUTES
// ==========================================
router.post(
  "/slots", 
  authorize(Role.TEACHER), 
  validateRequest(createSlotSchema), 
  createSlotController
);

router.patch(
  "/slots/:slotId/close", 
  authorize(Role.TEACHER), 
  closeSlotController
);

router.get(
  "/teacher", 
  authorize(Role.TEACHER), 
  getTeacherAppointmentsController
);

router.patch(
  "/:appointmentId/status", 
  authorize(Role.TEACHER), 
  validateRequest(updateAppointmentStatusSchema), 
  updateAppointmentStatusController
);

// ==========================================
// PARENT ROUTES
// ==========================================
router.get(
  "/teachers/:teacherId/slots", 
  authorize(Role.PARENT), 
  getAvailableSlotsController
);

router.post(
  "/book", 
  authorize(Role.PARENT), 
  validateRequest(bookAppointmentSchema), 
  bookAppointmentController
);

router.patch(
  "/:appointmentId/cancel", 
  authorize(Role.PARENT), 
  cancelAppointmentController
);

router.get(
  "/parent", 
  authorize(Role.PARENT), 
  getParentAppointmentsController
);

export default router;
