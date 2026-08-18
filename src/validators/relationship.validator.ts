import { z } from "zod";
import { RelationshipType } from "@prisma/client";

export const createRelationshipSchema = z
  .object({
    studentId: z.string().optional(),
    studentEmail: z.string().email().optional(),
    relationshipType: z.nativeEnum(RelationshipType),
  })
  .refine((data) => data.studentId || data.studentEmail, {
    message: "Either studentId or studentEmail must be provided",
    path: ["studentId"],
  });

export type CreateRelationshipInput = z.infer<typeof createRelationshipSchema>;
