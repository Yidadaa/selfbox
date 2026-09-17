/// <reference types="node" />
import { readFileSync } from "node:fs";
import { DatabaseSync, type SQLInputValue } from "node:sqlite";
import type { SQLiteDatabase } from "expo-sqlite";
import journal from "../migrations/meta/_journal.json";

// 测试直接读取 CLI 产物；原生构建由 Babel 将同一批 SQL 内联。
export const generatedMigrations = {
  journal,
  migrations: Object.fromEntries(
    journal.entries.map((entry) => [
      `m${String(entry.idx).padStart(4, "0")}`,
      readFileSync(
        new URL(`../migrations/${entry.tag}.sql`, import.meta.url),
        "utf8",
      ),
    ]),
  ),
};

// 用真实 SQLite 执行 Expo Drizzle 驱动生成的 SQL，仅适配原生桥接方法。
export function openTestDatabase(path = ":memory:") {
  const sqlite = new DatabaseSync(path);
  const adapter = {
    execSync: (sql: string) => sqlite.exec(sql),
    getFirstSync: <T>(sql: string) =>
      (sqlite.prepare(sql).get() as T | undefined) ?? null,
    withTransactionSync: (task: () => void) => {
      sqlite.exec("BEGIN");
      try {
        task();
        sqlite.exec("COMMIT");
      } catch (error) {
        sqlite.exec("ROLLBACK");
        throw error;
      }
    },
    prepareSync: (sql: string) => ({
      executeSync: (params: SQLInputValue[]) => {
        const statement = sqlite.prepare(sql);
        const result = statement.run(...params);
        return {
          changes: Number(result.changes),
          lastInsertRowId: Number(result.lastInsertRowid),
          getAllSync: () => statement.all(...params),
          getFirstSync: () => statement.get(...params),
        };
      },
      executeForRawResultSync: (params: SQLInputValue[]) => ({
        getAllSync: () => {
          const statement = sqlite.prepare(sql);
          statement.setReturnArrays(true);
          return statement.all(...params);
        },
      }),
    }),
  };
  return { sqlite, adapter: adapter as unknown as SQLiteDatabase };
}
