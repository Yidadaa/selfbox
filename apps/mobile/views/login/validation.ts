import { z } from "zod";
import type { Messages } from "@/i18n";
import { messages } from "@/i18n/en";

export function validateCredentials(
  email: string,
  password: string,
  confirmation?: string,
  copy: Messages = messages,
) {
  if (!z.email().safeParse(email.trim()).success || !password)
    return copy.invalidForm;
  if (confirmation !== undefined) {
    if (password.length < 8 || password.length > 128)
      return copy.passwordLength;
    if (password !== confirmation) return copy.passwordMismatch;
  }
  return null;
}

export function authErrorMessage(code?: string, copy: Messages = messages) {
  if (code === "INVALID_EMAIL_OR_PASSWORD") return copy.invalidCredentials;
  if (code === "USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL")
    return copy.accountExists;
  return copy.authError;
}
