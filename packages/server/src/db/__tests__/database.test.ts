import { eq } from "drizzle-orm";
import { beforeEach, expect, test, vi } from "vitest";
import { createTestUser, testDb } from "../../lib/test";
import { createDatabase } from "..";
import { session, user } from "../schema";

const db = createDatabase("postgresql://unused:unused@localhost/unused");

beforeEach(async () => {
  expect(await db.select().from(user)).toEqual([]);
  expect(await db.select().from(session)).toEqual([]);
});

test("database factory uses PGlite for both relative and package imports", async () => {
  const { createDatabase: createFromPackage } = await import("@repo/server/db");
  expect(vi.isMockFunction(createDatabase)).toBe(true);
  expect(createFromPackage("unused")).toBe(testDb);
  const createdUser = await createTestUser();
  expect(await db.query.user.findFirst()).toEqual(createdUser);
});

test("createTestUser persists unique users with database defaults", async () => {
  const first = await createTestUser();
  const second = await createTestUser();

  expect(first.id).not.toBe(second.id);
  expect(first.email).not.toBe(second.email);
  expect(first).toMatchObject({
    name: "Test User",
    emailVerified: false,
    image: null,
    createdAt: expect.any(Date),
    updatedAt: expect.any(Date),
  });
  expect(await db.select().from(user)).toHaveLength(2);
});

test("createTestUser accepts overrides and PostgreSQL enforces uniqueness", async () => {
  const overrides = {
    id: "custom-user",
    name: "Alice",
    email: "alice@example.com",
    emailVerified: true,
    image: "https://example.com/avatar.png",
    createdAt: new Date("2026-01-01T00:00:00Z"),
    updatedAt: new Date("2026-01-02T00:00:00Z"),
  };
  expect(await createTestUser(overrides)).toEqual(overrides);
  await expect(
    createTestUser({ email: overrides.email }),
  ).rejects.toMatchObject({
    cause: { code: "23505" },
  });
});

test("migrations enforce foreign keys and cascading deletes", async () => {
  const sessionData = {
    id: "test-session",
    token: "test-token",
    userId: "missing-user",
    expiresAt: new Date(Date.now() + 60_000),
  };
  await expect(db.insert(session).values(sessionData)).rejects.toMatchObject({
    cause: { code: "23503" },
  });

  const createdUser = await createTestUser();
  await db.insert(session).values({ ...sessionData, userId: createdUser.id });
  expect(
    await db.query.user.findFirst({ with: { sessions: true } }),
  ).toMatchObject({ id: createdUser.id, sessions: [{ id: sessionData.id }] });
  await db.delete(user).where(eq(user.id, createdUser.id));
  expect(await db.select().from(session)).toEqual([]);
});
