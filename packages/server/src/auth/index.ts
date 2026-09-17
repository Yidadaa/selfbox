import "server-only";

import { drizzleAdapter } from "@better-auth/drizzle-adapter";
import { expo } from "@better-auth/expo";
import { betterAuth } from "better-auth";
import type { Database } from "../db";
import * as schema from "../db/schema";

export interface AuthOptions {
  db: Database;
  secret: string;
  baseURL: string;
}

export function createAuth({ db, secret, baseURL }: AuthOptions) {
  return betterAuth({
    appName: "Expo Starter",
    secret,
    baseURL,
    trustedOrigins: ["*"],
    database: drizzleAdapter(db, {
      provider: "pg",
      schema,
      // Neon HTTP 不支持交互式事务。
      transaction: false,
    }),
    emailAndPassword: { enabled: true },
    plugins: [expo()],
  });
}

export type Auth = ReturnType<typeof createAuth>;
export type AuthSession = Auth["$Infer"]["Session"];
