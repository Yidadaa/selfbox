import { randomUUID } from "node:crypto";
import { user } from "../../db/schema";
import { testDb } from "./database";

export async function createTestUser(
  overrides: Partial<typeof user.$inferInsert> = {},
) {
  const [createdUser] = await testDb
    .insert(user)
    .values({
      id: randomUUID(),
      name: "Test User",
      email: `test-${randomUUID()}@example.com`,
      ...overrides,
    })
    .returning();

  if (!createdUser) throw new Error("创建测试用户失败");
  return createdUser;
}
