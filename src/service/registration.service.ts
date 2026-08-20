import { Role, AccountStatus, Gender } from "@prisma/client";
import { prisma } from "../utils/prisma";
import { hashPassword, isStrongPassword } from "../utils/password";
import { BadRequestError } from "../utils/errors";
import { generateAndSendVerificationToken } from "./emailVerification.service";

export interface RegisterUserInput {
  firstName: string;
  middleName: string;
  lastName: string;
  dateOfBirth?: string | Date;
  gender: Gender;
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword?: string;
  role: Role;
}

export interface RegisterStudentInput {
  firstName: string;
  middleName: string;
  lastName: string;
  dateOfBirth: string;
  gender: Gender;
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword?: string;
}

export interface RegisterParentInput {
  firstName: string;
  middleName: string;
  lastName: string;
  gender: Gender;
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword?: string;
}

export interface RegisterTeacherInput {
  firstName: string;
  middleName: string;
  lastName: string;
  dateOfBirth?: string;
  gender: Gender;
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword?: string;
}

/**
 * Registers a new user (Student, Parent, or Teacher).
 * Validates fields, checks duplicate email, hashes password,
 * and sets default status to PENDING.
 */
export async function registerUser(input: RegisterUserInput) {
  if (input.role === Role.ADMIN) {
    throw new BadRequestError("Admin registration is not allowed through public registration endpoints.", "ADMIN_REGISTRATION_FORBIDDEN");
  }

  if (input.confirmPassword && input.password !== input.confirmPassword) {
    throw new BadRequestError("Password and confirm password do not match.", "PASSWORD_MISMATCH");
  }

  const normalizedEmail = input.email ? input.email.toLowerCase().trim() : "";

  if (!normalizedEmail || !normalizedEmail.includes("@")) {
    throw new BadRequestError("Invalid email address format.", "INVALID_EMAIL");
  }

  if (!input.password || !isStrongPassword(input.password)) {
    throw new BadRequestError(
      "Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.",
      "WEAK_PASSWORD"
    );
  }

  let parsedDob: Date | null = null;
  if (input.dateOfBirth) {
    parsedDob = new Date(input.dateOfBirth);
    if (isNaN(parsedDob.getTime())) {
      throw new BadRequestError("Invalid dateOfBirth format. Must be a valid date string (YYYY-MM-DD).", "INVALID_DATE");
    }
    if (parsedDob > new Date()) {
      throw new BadRequestError("Date of birth cannot be a future date.", "FUTURE_DATE_NOT_ALLOWED");
    }
  }

  // Check duplicate email
  const existingUser = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });

  if (existingUser) {
    throw new BadRequestError("An account with this email already exists.", "DUPLICATE_EMAIL");
  }

  const passwordHash = await hashPassword(input.password);

  const user = await prisma.user.create({
    data: {
      firstName: input.firstName.trim(),
      middleName: input.middleName.trim(),
      lastName: input.lastName.trim(),
      dateOfBirth: parsedDob,
      gender: input.gender,
      email: normalizedEmail,
      phoneNumber: input.phoneNumber,
      passwordHash,
      role: input.role,
      status: AccountStatus.UNVERIFIED,
    },
    select: {
      id: true,
      firstName: true,
      middleName: true,
      lastName: true,
      dateOfBirth: true,
      gender: true,
      email: true,
      phoneNumber: true,
      role: true,
      status: true,
      createdAt: true,
    },
  });

  // Send email verification link
  await generateAndSendVerificationToken(user);

  return user;
}

export async function registerStudent(input: RegisterStudentInput | (RegisterUserInput & { role?: Role })) {
  return registerUser({ ...input, role: Role.STUDENT });
}

export async function registerParent(input: RegisterParentInput | (RegisterUserInput & { role?: Role })) {
  return registerUser({ ...input, role: Role.PARENT });
}

export async function registerTeacher(input: RegisterTeacherInput | (RegisterUserInput & { role?: Role })) {
  return registerUser({ ...input, role: Role.TEACHER });
}

