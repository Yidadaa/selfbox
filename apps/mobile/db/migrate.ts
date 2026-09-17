import { drizzle } from "drizzle-orm/expo-sqlite/driver";
import { migrate } from "drizzle-orm/expo-sqlite/migrator";
import type { SQLiteDatabase } from "expo-sqlite";
import * as schema from "./schema";

export async function migrateDatabase(
  database: SQLiteDatabase,
  migrations: Parameters<typeof migrate>[1],
) {
  database.execSync("PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;");
  const db = drizzle(database, { schema });
  await migrate(db, migrations);
  return db;
}
