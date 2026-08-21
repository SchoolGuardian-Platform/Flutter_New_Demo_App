import { z } from "zod";

export const createTeacherNoteSchema = z.object({
  studentId: z.string().uuid("Invalid student ID format."),
  title: z.string().min(1, "Title is required.").max(200),
  content: z.string().min(1, "Content is required."),
});

export const updateTeacherNoteSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().min(1).optional(),
});

export type CreateTeacherNoteInput = z.infer<typeof createTeacherNoteSchema>;
export type UpdateTeacherNoteInput = z.infer<typeof updateTeacherNoteSchema>;
