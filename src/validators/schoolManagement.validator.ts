import { z } from "zod";

export const createClassSchema = z.object({
  grade: z.number().int().min(1).max(12),
  section: z.string().min(1).max(5),
});

export const createSubjectSchema = z.object({
  name: z.string().min(2).max(100),
});

export const assignStudentSchema = z.object({
  studentId: z.string().uuid(),
  classId: z.string().uuid(),
  academicYear: z.string().optional(),
});

export const assignTeacherSchema = z.object({
  teacherId: z.string().uuid(),
  classId: z.string().uuid(),
  subjectId: z.string().uuid(),
  academicYear: z.string().optional(),
});

export type CreateClassInput = z.infer<typeof createClassSchema>;
export type CreateSubjectInput = z.infer<typeof createSubjectSchema>;
export type AssignStudentInput = z.infer<typeof assignStudentSchema>;
export type AssignTeacherInput = z.infer<typeof assignTeacherSchema>;
