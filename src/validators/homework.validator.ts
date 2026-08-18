import { z } from "zod";

export const createHomeworkSchema = z.object({
  classId: z.string().uuid("Invalid class ID format."),
  subject: z.string().min(1, "Subject is required.").max(100),
  title: z.string().min(1, "Title is required.").max(200),
  description: z.string().min(1, "Description is required."),
  dueDate: z.string().or(z.date()).transform((val) => new Date(val)),
});

export const updateHomeworkSchema = z.object({
  subject: z.string().min(1).max(100).optional(),
  title: z.string().min(1).max(200).optional(),
  description: z.string().min(1).optional(),
  dueDate: z.string().or(z.date()).transform((val) => new Date(val)).optional(),
});

export type CreateHomeworkInput = z.infer<typeof createHomeworkSchema>;
export type UpdateHomeworkInput = z.infer<typeof updateHomeworkSchema>;
