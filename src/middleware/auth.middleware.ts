import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt";
import { UnauthorizedError } from "../utils/errors";
import { prisma } from "../utils/prisma";

export async function authenticate(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new UnauthorizedError("Authentication token is missing or malformed.");
    }

    const token = authHeader.split(" ")[1];
    const payload = verifyAccessToken(token);

    // Fetch user from DB to verify current status and identity
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        firstName: true,
        middleName: true,
        lastName: true,
        email: true,
        role: true,
        status: true,
      },
    });

    if (!user || user.status !== "ACTIVE") {
      throw new UnauthorizedError("Account is inactive or no longer exists.");
    }

    // Attach authenticated user payload to request
    req.user = user;

    next();
  } catch (error) {
    next(error);
  }
}
