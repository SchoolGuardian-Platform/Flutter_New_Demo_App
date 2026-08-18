import { z } from "zod";
import { AssessmentType } from "@prisma/client";

export const createGradeSchema = z.object({
  studentId: z.string().uuid("Invalid student ID format."),
  subject: z.string().min(1, "Subject is required.").max(100),
  assessmentType: z.nativeEnum(AssessmentType),
  score: z.number().min(0, "Score cannot be negative."),
  maxScore: z.number().min(0, "Max score cannot be negative."),
  term: z.string().max(50).optional(),
  academicYear: z.string().max(20).optional(),
  comment: z.string().max(500).optional(),
}).refine((data) => data.score <= data.maxScore, {
  message: "Score cannot be greater than max score.",
  path: ["score"], // Attach error to the score field
});

export const updateGradeSchema = z.object({
  subject: z.string().min(1).max(100).optional(),
  assessmentType: z.nativeEnum(AssessmentType).optional(),
  score: z.number().min(0).optional(),
  maxScore: z.number().min(0).optional(),
  term: z.string().max(50).optional().nullable(),
  academicYear: z.string().max(20).optional().nullable(),
  comment: z.string().max(500).optional().nullable(),
}).refine((data) => {
  // If both are provided in update, validate. If only one is provided, we can't fully validate here
  // without DB data, but we can still reject if they provide bad pairs.
  if (data.score !== undefined && data.maxScore !== undefined) {
    return data.score <= data.maxScore;
  }
  return true;
}, {
  message: "Score cannot be greater than max score.",
  path: ["score"],
});

export type CreateGradeInput = z.infer<typeof createGradeSchema>;
export type UpdateGradeInput = z.infer<typeof updateGradeSchema>;
