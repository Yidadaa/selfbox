import { z } from "zod";
import { messages } from "@/i18n/en";

export function validateCredentials(
  email: string,
  password: string,
  confirmation?: string,
) {
  if (!z.email().safeParse(email.trim()).success || !password)
    return messages.invalidForm;
  if (confirmation !== undefined) {
    if (password.length < 8 || password.length > 128)
      return messages.passwordLength;
    if (password !== confirmation) return messages.passwordMismatch;
  }
  return null;
}

export function authErrorMessage(code?: string) {
  if (code === "INVALID_EMAIL_OR_PASSWORD") return messages.invalidCredentials;
  if (code === "USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL")
    return messages.accountExists;
  return messages.authError;
}
