import { fileURLToPath } from "node:url";
import { PGlite } from "@electric-sql/pglite";
import { sql } from "drizzle-orm";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import * as schema from "../../db/schema";

// Vitest 默认隔离测试文件，每个文件拥有独立的内存数据库。
const client = new PGlite();
export const testDb = drizzle({ client, schema });

export async function migrateTestDatabase() {
  await migrate(testDb, {
    migrationsFolder: fileURLToPath(
      new URL("../../db/migrations", import.meta.url),
    ),
  });
}

export async function resetTestDatabase() {
  const { rows } = await client.query<{ tablename: string }>(
    "SELECT tablename FROM pg_tables WHERE schemaname = 'public'",
  );
  if (rows.length === 0) return;

  const tables = rows.map(({ tablename }) => sql.identifier(tablename));
  await testDb.execute(
    sql`TRUNCATE TABLE ${sql.join(tables, sql`, `)} RESTART IDENTITY CASCADE`,
  );
}

export async function closeTestDatabase() {
  await client.close();
}
