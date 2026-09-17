import { z } from "zod";

export const registrationSchema = z
  .object({
    email: z.email("Enter a valid email address.").trim(),
    password: z
      .string()
      .min(8, "Use at least 8 characters for your password.")
      .max(128, "Use no more than 128 characters for your password."),
    confirmPassword: z.string(),
  })
  .refine(({ password, confirmPassword }) => password === confirmPassword, {
    message: "Your passwords do not match.",
    path: ["confirmPassword"],
  });
