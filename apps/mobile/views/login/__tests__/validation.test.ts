import { expect, test } from "vitest";
import { messages } from "@/i18n/en";
import { authErrorMessage, validateCredentials } from "../validation";

test("accepts login and matching registration credentials", () => {
  expect(validateCredentials(" alice@example.com ", "password123")).toBeNull();
  expect(
    validateCredentials("alice@example.com", "password123", "password123"),
  ).toBeNull();
});
test("rejects invalid emails, missing passwords and invalid registration", () => {
  expect(validateCredentials("alice", "password123")).toBe(
    messages.invalidForm,
  );
  expect(validateCredentials("alice@example.com", "")).toBe(
    messages.invalidForm,
  );
  expect(validateCredentials("alice@example.com", "short", "short")).toBe(
    messages.passwordLength,
  );
  expect(
    validateCredentials("alice@example.com", "password123", "different"),
  ).toBe(messages.passwordMismatch);
});
test("maps known auth errors and uses a generic fallback", () => {
  expect(authErrorMessage("INVALID_EMAIL_OR_PASSWORD")).toBe(
    messages.invalidCredentials,
  );
  expect(authErrorMessage("USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL")).toBe(
    messages.accountExists,
  );
  expect(authErrorMessage("UNKNOWN")).toBe(messages.authError);
});
