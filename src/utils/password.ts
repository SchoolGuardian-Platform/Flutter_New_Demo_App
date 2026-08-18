import { hashPassword, verifyPassword, generateRandomToken, hashToken } from "./hash";

/**
 * Validates password strength:
 * - At least 8 characters long
 * - At least one uppercase letter
 * - At least one lowercase letter
 * - At least one digit
 * - At least one special character
 */
export function isStrongPassword(password: string): boolean {
  if (!password || password.length < 8) {
    return false;
  }
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[^A-Za-z0-9]/.test(password);

  return hasUppercase && hasLowercase && hasNumber && hasSpecial;
}

export { hashPassword, verifyPassword, generateRandomToken, hashToken };
