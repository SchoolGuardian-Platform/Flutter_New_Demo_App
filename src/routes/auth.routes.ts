import { Router } from "express";
import {
  loginController,
  refreshController,
  logoutController,
  getMeController,
  registerController,
  registerStudentController,
  registerParentController,
  registerTeacherController,
  forgotPasswordController,
  resetPasswordConfirmController,
  verifyEmailController,
  resendVerificationController,
} from "../controllers/auth.controller";
import { validateRequest } from "../middleware/validate.middleware";
import {
  loginSchema,
  refreshSchema,
  logoutSchema,
  registerSchema,
  registerStudentSchema,
  registerParentSchema,
  registerTeacherSchema,
  forgotPasswordSchema,
  resetPasswordConfirmSchema,
  verifyEmailSchema,
  resendVerificationSchema,
} from "../validators/auth.validator";
import { authenticate } from "../middleware/auth.middleware";
import { loginRateLimiter } from "../middleware/rateLimit.middleware";

const router = Router();

// Public auth endpoints - Login & Token Refresh
router.post("/login", loginRateLimiter, validateRequest(loginSchema), loginController);
router.post("/refresh", validateRequest(refreshSchema), refreshController);

// Public auth endpoints - User Registration
router.post("/register", validateRequest(registerSchema), registerController);
router.post("/register/student", validateRequest(registerStudentSchema), registerStudentController);
router.post("/register/parent", validateRequest(registerParentSchema), registerParentController);
router.post("/register/teacher", validateRequest(registerTeacherSchema), registerTeacherController);

// Public auth endpoints - Password Reset Flow
router.post("/forgot-password", validateRequest(forgotPasswordSchema), forgotPasswordController);
router.post("/reset-password/request", validateRequest(forgotPasswordSchema), forgotPasswordController);
router.post("/reset-password/confirm", validateRequest(resetPasswordConfirmSchema), resetPasswordConfirmController);

// Public auth endpoints - Email Verification
router.post("/verify-email", validateRequest(verifyEmailSchema), verifyEmailController);
router.post("/resend-verification", loginRateLimiter, validateRequest(resendVerificationSchema), resendVerificationController);

// Authenticated auth endpoints
router.post("/logout", authenticate, validateRequest(logoutSchema), logoutController);
router.get("/me", authenticate, getMeController);

export default router;
