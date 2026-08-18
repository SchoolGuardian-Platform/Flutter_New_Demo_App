import { z } from "zod";

// Zod schema for POST /auth/login
export const loginSchema = z.object({
  email: z.string().min(1, "Email is required").email("Invalid email address format"),
  password: z.string().min(1, "Password is required"),
});

// Zod schema for POST /auth/refresh
export const refreshSchema = z.object({
  refreshToken: z.string().min(1, "Refresh token is required"),
});

// Zod schema for POST /auth/logout
export const logoutSchema = z.object({
  refreshToken: z.string().optional(),
});

export const GenderEnum = z.enum(["MALE", "FEMALE", "OTHER", "PREFER_NOT_TO_SAY"]);

export const dateOfBirthSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid date format. Expected YYYY-MM-DD")
  .refine((val) => !isNaN(Date.parse(val)), "Invalid date")
  .refine((val) => new Date(val) <= new Date(), "Date of birth cannot be a future date");

// Zod schema for POST /auth/register/student
export const registerStudentSchema = z
  .object({
    firstName: z.string().min(1, "First name is required"),
    middleName: z.string().min(1, "Middle name is required"),
    lastName: z.string().min(1, "Last name is required"),
    dateOfBirth: dateOfBirthSchema,
    gender: GenderEnum,
    email: z.string().min(1, "Email is required").email("Invalid email address format"),
    phoneNumber: z.string().min(1, "Phone number is required"),
    password: z.string().min(8, "Password must be at least 8 characters long"),
    confirmPassword: z.string().min(1, "Confirm password is required"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

// Zod schema for POST /auth/register/parent
export const registerParentSchema = z
  .object({
    firstName: z.string().min(1, "First name is required"),
    middleName: z.string().min(1, "Middle name is required"),
    lastName: z.string().min(1, "Last name is required"),
    gender: GenderEnum,
    email: z.string().min(1, "Email is required").email("Invalid email address format"),
    phoneNumber: z.string().min(1, "Phone number is required"),
    password: z.string().min(8, "Password must be at least 8 characters long"),
    confirmPassword: z.string().min(1, "Confirm password is required"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

// Zod schema for POST /auth/register/teacher
export const registerTeacherSchema = z
  .object({
    firstName: z.string().min(1, "First name is required"),
    middleName: z.string().min(1, "Middle name is required"),
    lastName: z.string().min(1, "Last name is required"),
    dateOfBirth: dateOfBirthSchema,
    gender: GenderEnum,
    email: z.string().min(1, "Email is required").email("Invalid email address format"),
    phoneNumber: z.string().min(1, "Phone number is required"),
    password: z.string().min(8, "Password must be at least 8 characters long"),
    confirmPassword: z.string().min(1, "Confirm password is required"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

// Generic Zod schema for POST /auth/register (disallows ADMIN)
export const registerSchema = z
  .object({
    firstName: z.string().min(1, "First name is required"),
    middleName: z.string().min(1, "Middle name is required"),
    lastName: z.string().min(1, "Last name is required"),
    dateOfBirth: dateOfBirthSchema.optional(),
    gender: GenderEnum,
    email: z.string().min(1, "Email is required").email("Invalid email address format"),
    phoneNumber: z.string().min(1, "Phone number is required"),
    password: z.string().min(8, "Password must be at least 8 characters long"),
    confirmPassword: z.string().optional(),
    role: z.enum(["STUDENT", "PARENT", "TEACHER"]),
  })
  .refine((data) => !data.confirmPassword || data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

// Legacy schema alias if needed for role-generic inputs
export const registerRoleSchema = registerSchema;

// Zod schema for POST /auth/reset-password/request (or /auth/forgot-password)
export const forgotPasswordSchema = z.object({
  email: z.string().min(1, "Email is required").email("Invalid email address format"),
});

// Zod schema for POST /auth/reset-password/confirm
export const resetPasswordConfirmSchema = z.object({
  token: z.string().min(1, "Token is required"),
  newPassword: z.string().min(8, "New password must be at least 8 characters long"),
});

// Zod schema for POST /auth/verify-email
export const verifyEmailSchema = z.object({
  token: z.string().min(1, "Token is required"),
});

// Zod schema for POST /auth/resend-verification
export const resendVerificationSchema = z.object({
  email: z.string().min(1, "Email is required").email("Invalid email address format"),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type LogoutInput = z.infer<typeof logoutSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type RegisterStudentInput = z.infer<typeof registerStudentSchema>;
export type RegisterParentInput = z.infer<typeof registerParentSchema>;
export type RegisterTeacherInput = z.infer<typeof registerTeacherSchema>;
export type RegisterRoleInput = z.infer<typeof registerRoleSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordConfirmInput = z.infer<typeof resetPasswordConfirmSchema>;
export type VerifyEmailInput = z.infer<typeof verifyEmailSchema>;
export type ResendVerificationInput = z.infer<typeof resendVerificationSchema>;
