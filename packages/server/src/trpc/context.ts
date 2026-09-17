import "server-only";

import type { AuthSession } from "../auth";
import type { Database } from "../db";

export interface ContextOptions {
  db: Database;
  headers: Headers;
  getSession: (headers: Headers) => Promise<AuthSession | null>;
}

export function createTRPCContext({ db, headers, getSession }: ContextOptions) {
  let session: Promise<AuthSession | null> | undefined;

  return {
    db,
    headers,
    // 每个请求单独缓存；公开接口无需查询认证数据库。
    getSession: () => (session ??= getSession(headers)),
  };
}

export type TRPCContext = ReturnType<typeof createTRPCContext>;
