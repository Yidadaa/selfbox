import { randomUUID } from "node:crypto";
import type { AuthSession } from "../../auth";
import { createDatabase } from "../../db";
import { type ContextOptions, createTRPCContext } from "../../trpc/context";
import { appRouter } from "../../trpc/router";

export interface TestCallerOptions extends Partial<ContextOptions> {
  user?: AuthSession["user"];
}

export function createTestCaller({
  user,
  db = createDatabase("unused"),
  headers = new Headers(),
  getSession = async (): Promise<AuthSession | null> => {
    if (!user) return null;

    const now = new Date();
    // 仅构造上下文会话，不创建认证数据库记录或登录 cookie。
    return {
      user,
      session: {
        id: randomUUID(),
        userId: user.id,
        token: randomUUID(),
        expiresAt: new Date(now.getTime() + 60 * 60 * 1_000),
        createdAt: now,
        updatedAt: now,
      },
    };
  },
}: TestCallerOptions = {}): ReturnType<typeof appRouter.createCaller> {
  return appRouter.createCaller(createTRPCContext({ db, headers, getSession }));
}
