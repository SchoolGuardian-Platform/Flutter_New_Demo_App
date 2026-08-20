import { z } from "zod";
import { AppointmentStatus } from "@prisma/client";

export const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid date format. Expected YYYY-MM-DD")
  .refine((val) => !isNaN(Date.parse(val)), "Invalid date");

export const timeSchema = z
  .string()
  .regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, "Invalid time format. Expected HH:MM");

// Zod schema for POST /appointments/slots
export const createSlotSchema = z.object({
  date: dateSchema,
  startTime: timeSchema,
  endTime: timeSchema,
});

// Zod schema for POST /appointments/book
export const bookAppointmentSchema = z.object({
  slotId: z.string().min(1, "Slot ID is required"),
  studentId: z.string().min(1, "Student ID is required"),
  reason: z.string().optional(),
});

// Zod schema for PATCH /appointments/:appointmentId/status (Teacher accepts/cancels)
export const updateAppointmentStatusSchema = z.object({
  status: z.enum([AppointmentStatus.ACCEPTED, AppointmentStatus.CANCELLED_BY_TEACHER]),
});

export type CreateSlotInput = z.infer<typeof createSlotSchema>;
export type BookAppointmentInput = z.infer<typeof bookAppointmentSchema>;
export type UpdateAppointmentStatusInput = z.infer<typeof updateAppointmentStatusSchema>;
