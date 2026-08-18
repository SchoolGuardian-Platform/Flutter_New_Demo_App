import bcrypt from 'bcrypt';
import crypto from 'crypto';
const SALT_ROUNDS = 10;

export async function verifyPassword(password: string,hash: string): Promise<boolean> {
    return await bcrypt.compare(password,hash);
}

export async function hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password,SALT_ROUNDS);
}

export function generateRandomToken(): string {
  return crypto.randomBytes(40).toString("hex");
}

// Hashes a refresh token string using SHA-256 before saving to PostgreSQL
export async function hashToken(token: string): Promise<string> {
  return crypto.createHash("sha256").update(token).digest("hex");
}
