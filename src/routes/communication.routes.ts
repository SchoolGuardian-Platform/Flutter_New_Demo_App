import { Router } from "express";
import { authenticate } from "../middleware/auth.middleware";
import { verifyRecordAccess } from "../middleware/recordAccess.middleware";
import { validateRequest } from "../middleware/validate.middleware";
import { sendMessageSchema } from "../validators/communication.validator";
import {
  getTeacherStudentsController,
  getStudentTeachersController,
  getStudentParentsController,
  lookupStudentBySchoolIdController,
  sendMessageController,
  getChatHistoryController,
  markAsReadController,
  deleteMessageController,
  getUnreadCountController
} from "../controllers/communication.controller";

const router = Router();

// All communication routes require authentication
router.use(authenticate);

// --- Contact Discovery ---
// Teacher fetches their own students (with optional ?q= search filter for autocomplete)
router.get("/my-students", getTeacherStudentsController);

// Look up a student record by their human-readable school ID (e.g. SG-2026-000001)
router.get("/students/by-school-id/:schoolId", lookupStudentBySchoolIdController);

// Teachers, Parents, and Students can view teachers assigned to a student they have access to
router.get("/students/:studentId/teachers", verifyRecordAccess("studentId"), getStudentTeachersController);

// Teachers and Admins can view parents of a student they have access to
router.get("/students/:studentId/parents", verifyRecordAccess("studentId"), getStudentParentsController);


// --- Direct Messaging ---
router.post("/messages", validateRequest(sendMessageSchema), sendMessageController);
router.get("/messages/unread-count", getUnreadCountController);
router.get("/messages/:userId", getChatHistoryController);
router.patch("/messages/:messageId/read", markAsReadController);
router.delete("/messages/:messageId", deleteMessageController);

export default router;
