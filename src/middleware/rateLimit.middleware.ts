import rateLimit from "express-rate-limit";
import { Request, Response } from "express";

/**
 * Login Rate Limiter: 5 attempts per 15 minutes per IP + Email combination.
 */
export const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP + email to 5 requests per windowMs
  keyGenerator: (req: Request): string => {
    const email = req.body && req.body.email ? req.body.email.toLowerCase().trim() : "";
    return `${req.ip}_${email}`;
  },
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      error: {
        code: "RATE_LIMITED",
        message: "Too many login attempts. Please try again later.",
      },
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
  validate: {
    keyGeneratorIpFallback: false,
  },
});
