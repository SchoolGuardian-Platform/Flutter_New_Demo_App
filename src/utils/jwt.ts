import jwt, { SignOptions } from "jsonwebtoken";
import dotenv from "dotenv";
import { Role } from "@prisma/client";
import { UnauthorizedError } from "./errors";

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || "defualt-jwt-scret-key-change-me";
const JWT_EXPIRES_IN = (process.env.JWT_EXPIRES_IN || "15m") as SignOptions["expiresIn"];

export interface JwtPayload {
    sub: string; // user ID
    role: Role; // user role()
}

export function generateAccessToken(userId: string, role: Role):
    string {
    const payload: JwtPayload = { sub: userId, role };
    return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

export function verifyAccessToken(token: string): JwtPayload {
    try {
        const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
        if (!decoded || !decoded.sub || !decoded.role) {
            throw new UnauthorizedError("Invalid token payload.");
        }
        return decoded;
    } catch (error) {
        throw new UnauthorizedError("Invalid or expired access token.");
    }
}