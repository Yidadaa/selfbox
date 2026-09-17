import { loadEnvConfig } from "@next/env";
import { defineConfig } from "drizzle-kit";
import { createDatabaseEnv } from "./env/database";

loadEnvConfig(process.cwd());
const env = createDatabaseEnv();

export default defineConfig({
  dialect: "postgresql",
  schema: "../../packages/server/src/db/schema/index.ts",
  out: "../../packages/server/src/db/migrations",
  dbCredentials: { url: env.DATABASE_URL },
});
