import { expect, test } from "vitest";
import { registrationSchema } from "../registration";

const valid = {
  email: "new-user@example.com",
  password: "valid-password",
  confirmPassword: "valid-password",
};

test("registration accepts only email and matching passwords", () => {
  expect(registrationSchema.safeParse(valid).success).toBe(true);
});

test("different passwords are rejected on the confirmation field", () => {
  const result = registrationSchema.safeParse({
    ...valid,
    confirmPassword: "another-password",
  });
  expect(result.success).toBe(false);
  if (!result.success) {
    expect(result.error.issues).toContainEqual(
      expect.objectContaining({
        path: ["confirmPassword"],
        message: "Your passwords do not match.",
      }),
    );
  }
});

test.each(["", "invalid", "user@"])("rejects invalid email %s", (email) => {
  expect(registrationSchema.safeParse({ ...valid, email }).success).toBe(false);
});

test.each([0, 7, 129])("rejects password length %i", (length) => {
  const password = "a".repeat(length);
  expect(
    registrationSchema.safeParse({
      ...valid,
      password,
      confirmPassword: password,
    }).success,
  ).toBe(false);
});

test.each([8, 128])("accepts password boundary length %i", (length) => {
  const password = "a".repeat(length);
  expect(
    registrationSchema.safeParse({
      ...valid,
      password,
      confirmPassword: password,
    }).success,
  ).toBe(true);
});
