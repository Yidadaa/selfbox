import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

// 函数形式让 Drizzle CLI 先加载当前应用的 .env 文件。
export function createDatabaseEnv() {
  return createEnv({
    server: {
      DATABASE_URL: z
        .url()
        .refine(
          (value) =>
            value.startsWith("postgres://") ||
            value.startsWith("postgresql://"),
          "DATABASE_URL must be a PostgreSQL connection URL",
        ),
    },
    runtimeEnv: { DATABASE_URL: process.env.DATABASE_URL },
    emptyStringAsUndefined: true,
  });
}
