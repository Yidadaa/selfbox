import { afterAll, beforeAll, beforeEach, vi } from "vitest";
import type { Database } from "../../db";
import {
  closeTestDatabase,
  migrateTestDatabase,
  resetTestDatabase,
} from "./database";

vi.mock("server-only", () => ({}));

vi.mock(import("../../db"), async () => {
  const { testDb } = await import("./database");
  return {
    // 驱动专属 API 不同；类型转换仅限测试替换边界，业务查询仍由 Drizzle 执行。
    createDatabase: vi.fn(
      (_databaseUrl: string) => testDb as unknown as Database,
    ),
  };
});

beforeAll(migrateTestDatabase);
beforeEach(resetTestDatabase);
afterAll(closeTestDatabase);
