"use client";

import { Button } from "@repo/ui/components/button";
import {
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
} from "@repo/ui/components/field";
import { Input } from "@repo/ui/components/input";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { type FormEvent, useState } from "react";
import { Link as RouterLink } from "react-router";
import { authClient } from "@/lib/auth";
import { registrationSchema } from "./registration";

export function LoginPage({ isSignUp = false }: { isSignUp?: boolean }) {
  const queryClient = useQueryClient();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isSubmitting) return;

    const formData = new FormData(event.currentTarget);
    const email = String(formData.get("email") ?? "").trim();
    const password = String(formData.get("password") ?? "");
    setError(null);

    if (isSignUp) {
      const validation = registrationSchema.safeParse({
        email,
        password,
        confirmPassword: String(formData.get("confirmPassword") ?? ""),
      });
      if (!validation.success) {
        setError(
          validation.error.issues[0]?.message ??
            "Check your details and try again.",
        );
        return;
      }
    }

    setIsSubmitting(true);

    try {
      const result = isSignUp
        ? await authClient.signUp.email({
            email,
            password,
            // Better Auth 必须提供 name；用邮箱前缀作为初始显示名，无需额外输入。
            name: email.split("@")[0] || "Expo Starter user",
          })
        : await authClient.signIn.email({ email, password });

      if (result.error) {
        const messages: Record<string, string> = {
          INVALID_EMAIL_OR_PASSWORD:
            "The email or password is incorrect. Please try again.",
          USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL:
            "An account with this email already exists. Please log in.",
          PASSWORD_TOO_SHORT: "Use at least 8 characters for your password.",
          PASSWORD_TOO_LONG:
            "Use no more than 128 characters for your password.",
          INVALID_EMAIL: "Enter a valid email address.",
        };
        setError(
          messages[result.error.code ?? ""] ??
            (isSignUp
              ? "Unable to create your account. Please try again later."
              : "Unable to log in. Please try again later."),
        );
        return;
      }

      await queryClient.cancelQueries();
      queryClient.clear();
      // 重新请求 page.tsx，让服务端以新会话重新执行 auth guard。
      window.location.replace("/dashboard");
    } catch {
      setError("Unable to connect. Check your connection and try again.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="flex min-h-svh flex-col items-center justify-center gap-6 bg-background p-6 md:p-10">
      <div className="flex w-full max-w-sm flex-col gap-6">
        <form
          aria-labelledby="login-heading"
          aria-busy={isSubmitting}
          onSubmit={handleSubmit}
        >
          <FieldGroup>
            <div className="flex flex-col items-center gap-2 text-center">
              <Link
                href="/"
                aria-label="Expo Starter home"
                className="mb-2 rounded-md text-3xl font-semibold tracking-[-0.075em] outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
              >
                expo-starter.
              </Link>
              <h1 id="login-heading" className="text-xl font-bold">
                {isSignUp
                  ? "Create your Expo Starter account"
                  : "Welcome to Expo Starter"}
              </h1>
              <FieldDescription>
                {isSignUp
                  ? "Get started with your email and password."
                  : "Log in with your email and password."}
              </FieldDescription>
            </div>
            <Field>
              <FieldLabel htmlFor="email">Email</FieldLabel>
              <Input
                id="email"
                name="email"
                type="email"
                placeholder="m@example.com"
                autoComplete="email"
                autoCapitalize="none"
                spellCheck={false}
                required
                disabled={isSubmitting}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="password">Password</FieldLabel>
              <Input
                id="password"
                name="password"
                type="password"
                autoComplete={isSignUp ? "new-password" : "current-password"}
                minLength={isSignUp ? 8 : undefined}
                maxLength={isSignUp ? 128 : undefined}
                required
                disabled={isSubmitting}
              />
            </Field>
            {isSignUp && (
              <Field>
                <FieldLabel htmlFor="confirmPassword">
                  Confirm password
                </FieldLabel>
                <Input
                  id="confirmPassword"
                  name="confirmPassword"
                  type="password"
                  autoComplete="new-password"
                  minLength={8}
                  maxLength={128}
                  required
                  disabled={isSubmitting}
                />
                <FieldDescription>
                  Use 8–128 characters. Both passwords must match.
                </FieldDescription>
              </Field>
            )}
            {error && (
              <p role="alert" className="text-sm text-destructive">
                {error}
              </p>
            )}
            <Field>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting
                  ? isSignUp
                    ? "Creating account…"
                    : "Logging in…"
                  : isSignUp
                    ? "Create account"
                    : "Log in"}
              </Button>
            </Field>
          </FieldGroup>
        </form>
        <FieldDescription className="text-center">
          {isSignUp ? "Already have an account? " : "Don’t have an account? "}
          {isSubmitting ? (
            <span>{isSignUp ? "Log in" : "Sign up"}</span>
          ) : (
            <RouterLink to={isSignUp ? "/login" : "/signup"}>
              {isSignUp ? "Log in" : "Sign up"}
            </RouterLink>
          )}
        </FieldDescription>
        <FieldDescription className="px-6 text-center">
          <Link href="/">Back to Expo Starter</Link>
        </FieldDescription>
      </div>
    </main>
  );
}
