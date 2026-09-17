import "server-only";

import { createTRPCContext } from "@repo/server/trpc";
import { getServices } from "@/lib/server";

export function createContext(headers: Headers) {
  const { db, auth } = getServices();
  return createTRPCContext({
    db,
    headers,
    getSession: (requestHeaders) =>
      auth.api.getSession({
        headers: requestHeaders,
        // RSC 不能写 cookie；会话刷新由 Better Auth 的同源路由负责。
        query: { disableRefresh: true },
      }),
  });
}
