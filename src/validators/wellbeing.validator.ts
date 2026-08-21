import { z } from "zod";

export const uploadUsageSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid date format, must be YYYY-MM-DD"),
  screenTimeMinutes: z.number().int().min(0, "Screen time cannot be negative").max(1440, "Screen time cannot exceed 24 hours"),
  apps: z.array(
    z.object({
      appName: z.string().min(1, "App name is required").max(100, "App name is too long"),
      packageName: z.string().max(100).optional(),
      usageMinutes: z.number().int().min(0, "Usage minutes cannot be negative").max(1440, "Usage minutes cannot exceed 24 hours"),
    })
  ).optional(),
});

export const updateLimitSchema = z.object({
  dailyScreenTimeMinutes: z.number().int().min(0, "Daily screen time limit cannot be negative").max(1440, "Daily screen time limit cannot exceed 24 hours"),
  enabled: z.boolean().optional(),
});

export type UploadUsageInput = z.infer<typeof uploadUsageSchema>;
export type UpdateLimitInput = z.infer<typeof updateLimitSchema>;
