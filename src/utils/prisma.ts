import { PrismaClient } from "@prisma/client";

// Shared singleton instance of PrismaClient Creating a single instance prevents your application from opening multiple database connection pools on every request.
export const prisma = new PrismaClient();
