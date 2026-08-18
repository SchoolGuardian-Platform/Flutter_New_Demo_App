import { z } from "zod";
import { AttendanceStatus } from "@prisma/client";

export const createAttendanceSchema = z.object({
  studentId: z.string().uuid("Invalid student ID format."),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format."),
  status: z.nativeEnum(AttendanceStatus),
  note: z.string().max(255).optional(),
});

export const updateAttendanceSchema = z.object({
  status: z.nativeEnum(AttendanceStatus).optional(),
  note: z.string().max(255).optional().nullable(),
});

export type CreateAttendanceInput = z.infer<typeof createAttendanceSchema>;
export type UpdateAttendanceInput = z.infer<typeof updateAttendanceSchema>;
