import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";
import { createDatabaseEnv } from "./env/database";

const vercelUrl = process.env.VERCEL_URL;

export const env = createEnv({
  extends: [createDatabaseEnv()],
  server: {
    BETTER_AUTH_SECRET: z.string().min(32),
    BASE_URL: z
      .url()
      .refine(
        (value) => value.startsWith("http://") || value.startsWith("https://"),
        "BASE_URL must use HTTP or HTTPS",
      ),
  },
  runtimeEnv: {
    BETTER_AUTH_SECRET: process.env.BETTER_AUTH_SECRET,
    BASE_URL:
      process.env.BASE_URL || (vercelUrl ? `https://${vercelUrl}` : undefined),
  },
  emptyStringAsUndefined: true,
});
