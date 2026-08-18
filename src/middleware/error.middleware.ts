import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/errors";

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void {
  // Handle AppError custom exceptions
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
      },
    });
    return;
  }

  // Handle Zod Schema Validation Errors
  if (err instanceof ZodError) {
    const issueMessages = err.issues.map((issue) => issue.message).join(", ");
    res.status(400).json({
      error: {
        code: "BAD_REQUEST",
        message: issueMessages || "Invalid input payload",
      },
    });
    return;
  }

  // Log unexpected runtime errors securely without exposing stack traces to clients
  console.error("Unhandled Error:", err);

  res.status(500).json({
    error: {
      code: "INTERNAL_ERROR",
      message: "An internal server error occurred.",
    },
  });
}
