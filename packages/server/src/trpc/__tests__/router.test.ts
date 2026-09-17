import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { expect, test } from "vitest";
import type { AuthSession } from "../../auth";
import { createDatabase } from "../../db";
import { createTestCaller, createTestUser } from "../../lib/test";
import { createTRPCContext } from "../context";
import { appRouter } from "../router";

// createDatabase 在测试 setup 中被替换为 PGlite。
const db = createDatabase("postgresql://test:test@localhost/test");

test("public health does not look up a session", async () => {
  const caller = createTestCaller({
    getSession: async () => {
      throw new Error("unexpected session lookup");
    },
  });
  expect(await caller.health()).toEqual({ status: "ok" });
});

test("protected procedures reject anonymous callers", async () => {
  const caller = createTestCaller();
  await expect(caller.user.me()).rejects.toMatchObject({
    code: "UNAUTHORIZED",
  });
});

test("authenticated user response never includes session tokens", async () => {
  const user = await createTestUser({
    id: "alice",
    name: "Alice",
    email: "alice@example.com",
    emailVerified: true,
  });
  const caller = createTestCaller({ user });
  expect(await caller.user.me()).toEqual({
    id: "alice",
    name: "Alice",
    email: "alice@example.com",
    emailVerified: true,
    image: null,
  });
});

test("session lookup is deduplicated within a request and isolated across requests", async () => {
  const user = await createTestUser({ name: "Alice" });
  const alice: AuthSession = {
    user,
    session: {
      id: "session-alice",
      userId: user.id,
      token: "private-session-token",
      expiresAt: new Date(Date.now() + 60_000),
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  };
  let calls = 0;
  const headers = new Headers({ cookie: "session=alice" });
  const first = createTRPCContext({
    db,
    headers,
    getSession: async (requestHeaders) => {
      calls += 1;
      expect(requestHeaders.get("cookie")).toBe("session=alice");
      return alice;
    },
  });
  const second = createTRPCContext({
    db,
    headers: new Headers(),
    getSession: async () => null,
  });
  const results = await Promise.all([
    first.getSession(),
    first.getSession(),
    second.getSession(),
  ]);
  expect(calls).toBe(1);
  expect(results).toEqual([alice, alice, null]);
});

test("authentication errors do not grant access", async () => {
  const caller = createTestCaller({
    getSession: async () => {
      throw new Error("authentication unavailable");
    },
  });
  await expect(caller.user.me()).rejects.toMatchObject({
    code: "INTERNAL_SERVER_ERROR",
  });
});

test("HTTP adapter returns 401 for an unauthenticated protected query", async () => {
  const response = await fetchRequestHandler({
    endpoint: "/api/trpc",
    req: new Request("http://localhost/api/trpc/user.me"),
    router: appRouter,
    createContext: () =>
      createTRPCContext({
        db,
        headers: new Headers(),
        getSession: async () => null,
      }),
  });
  expect(response.status).toBe(401);
});
