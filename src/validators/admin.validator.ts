import { z } from "zod";

export const rejectionSchema = z.object({
  reason: z.string().optional(),
});

export type RejectionInput = z.infer<typeof rejectionSchema>;
