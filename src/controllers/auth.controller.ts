import { Request, Response, NextFunction } from "express";
import { loginUser, refreshUserToken, logoutUser, getUserProfile } from "../service/auth.service";
import { registerUser, registerStudent, registerParent, registerTeacher } from "../service/registration.service";
import { requestPasswordReset, confirmPasswordReset } from "../service/passwordReset.service";
import { verifyEmailToken, resendVerificationToken } from "../service/emailVerification.service";
import {
  LoginInput,
  RefreshInput,
  LogoutInput,
  RegisterInput,
  RegisterStudentInput,
  RegisterParentInput,
  RegisterTeacherInput,
  ForgotPasswordInput,
  ResetPasswordConfirmInput,
  VerifyEmailInput,
  ResendVerificationInput,
} from "../validators/auth.validator";

/**
 * POST /auth/login
 */
export async function loginController(
  req: Request<{}, {}, LoginInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const result = await loginUser({
      input: req.body,
      ipAddress: req.ip,
      userAgent: req.get("user-agent"),
    });

    res.status(200).json({
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/refresh
 */
export async function refreshController(
  req: Request<{}, {}, RefreshInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const result = await refreshUserToken(
      req.body.refreshToken,
      req.ip,
      req.get("user-agent")
    );

    res.status(200).json({
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/logout
 */
export async function logoutController(
  req: Request<{}, {}, LogoutInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const userId = req.user!.id;
    const refreshToken = req.body?.refreshToken;

    await logoutUser(userId, refreshToken, req.ip, req.get("user-agent"));

    res.status(204).send();
  } catch (error) {
    next(error);
  }
}

/**
 * GET /auth/me
 */
export async function getMeController(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const userProfile = await getUserProfile(req.user!.id);

    res.status(200).json({
      data: userProfile,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/register
 */
export async function registerController(
  req: Request<{}, {}, RegisterInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await registerUser(req.body);
    res.status(201).json({
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/register/student
 */
export async function registerStudentController(
  req: Request<{}, {}, RegisterStudentInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await registerStudent(req.body);
    res.status(201).json({
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/register/parent
 */
export async function registerParentController(
  req: Request<{}, {}, RegisterParentInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await registerParent(req.body);
    res.status(201).json({
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/register/teacher
 */
export async function registerTeacherController(
  req: Request<{}, {}, RegisterTeacherInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await registerTeacher(req.body);
    res.status(201).json({
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/forgot-password or POST /auth/reset-password/request
 */
export async function forgotPasswordController(
  req: Request<{}, {}, ForgotPasswordInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const result = await requestPasswordReset(req.body.email);
    res.status(200).json({
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/reset-password/confirm
 */
export async function resetPasswordConfirmController(
  req: Request<{}, {}, ResetPasswordConfirmInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const result = await confirmPasswordReset(req.body.token, req.body.newPassword);
    res.status(200).json({
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/verify-email
 */
export async function verifyEmailController(
  req: Request<{}, {}, VerifyEmailInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await verifyEmailToken(req.body.token, req.ip, req.get("user-agent"));
    res.status(200).json({
      data: {
        message: "Email verified successfully.",
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /auth/resend-verification
 */
export async function resendVerificationController(
  req: Request<{}, {}, ResendVerificationInput>,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await resendVerificationToken(req.body.email, req.ip, req.get("user-agent"));
    res.status(202).json({
      data: {
        message: "If the account requires verification, a verification email has been sent.",
      },
    });
  } catch (error) {
    next(error);
  }
}
