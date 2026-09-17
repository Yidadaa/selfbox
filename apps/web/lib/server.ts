import "server-only";

import { createAuth } from "@repo/server/auth";
import { createDatabase } from "@repo/server/db";
import { env } from "@/env";

function createServices() {
  const db = createDatabase(env.DATABASE_URL);
  const auth = createAuth({
    db,
    secret: env.BETTER_AUTH_SECRET,
    baseURL: env.BASE_URL,
  });
  return { db, auth };
}

let services: ReturnType<typeof createServices> | undefined;

export function getServices() {
  services ??= createServices();
  return services;
}
