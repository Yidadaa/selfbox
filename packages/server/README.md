# 服务模块

`@repo/server` 提供 TypeScript 源码导出，不单独启动 HTTP 服务，不读取环境变量。应用通过工厂函数注入配置。

## 目录

- `src/trpc`：请求上下文、公开 / 受保护 procedure、根 router 和按业务划分的 `routers`。
- `src/db`：`createDatabase(databaseUrl)`、Drizzle schema 与迁移文件；使用 Neon HTTP 驱动。
- `src/auth`：`createAuth({ db, secret, baseURL })`，通过 Drizzle adapter 持久化用户、会话、账户和验证数据，启用邮箱密码认证。
- `src/lib/test`：PGlite 生命周期、`createTestUser` 和 `createTestCaller` 测试工具，不作为服务包 API 导出。
- `src/lib/test/setup.ts`：注册 Vitest mock 和数据库生命周期钩子。

导入路径：`@repo/server/trpc`、`@repo/server/db`、`@repo/server/db/schema`、`@repo/server/auth`。客户端仅允许 `import type` 引用服务类型；运行时代码通过 `server-only` 隔离。

## 约定

- 服务实例由应用创建；请求上下文与会话缓存按请求隔离，不使用全局用户状态。
- Better Auth 使用 `trustedOrigins: ["*"]` 接受任意来源域名的认证请求；浏览器 CORS 与 Cookie 策略仍独立生效。
- `health` 只检查 tRPC 可用性，不探测数据库；`user.me` 使用 `protectedProcedure`，返回用户资料，不返回会话 token。
- 新业务 router 放入 `src/trpc/routers` 并注册到根 router；所有受保护操作复用 `protectedProcedure`。
- Neon HTTP 不支持交互式事务，认证适配器显式关闭事务。需要跨语句原子操作时应先切换到支持事务的驱动。
- schema 与迁移在本包共享；迁移配置和目标数据库归各应用。执行 `pnpm --filter web db:generate` / `db:migrate`，不要在本包加载应用 `.env`。

## 验证

测试文件统一放在对应模块的 `__tests__/` 目录，例如 `src/trpc/__tests__/router.test.ts`，不与源代码文件同级混放。

```sh
pnpm test                            # 通过 Turbo 运行测试
pnpm --filter @repo/server test       # 仅运行服务包测试
pnpm --filter @repo/server test:watch # 监听模式
pnpm check-types                     # 检查所有工作区
```

Vitest 在 setup 中 mock `server-only` 和 `createDatabase`，后者返回使用共享 schema 的 PGlite Drizzle 实例，不读取环境变量或连接外部数据库。每个测试文件独立创建内存库，通过 `src/db/migrations` 建表；每个用例前清空 `public` 中的所有表，保留迁移记录，文件结束后关闭数据库。同一文件内不要使用 `test.concurrent`，以免清理和写入相互干扰。

`createTestUser(overrides?)` 插入并返回完整用户记录，自动生成唯一 ID 和邮箱，可覆盖 schema 的插入字段；默认保留数据库的 `emailVerified: false`，不创建密码账户或会话。测试需要真实认证流程时调用 `createAuth` 的 API，示例见 `src/auth/__tests__/auth.test.ts`。

工具统一从 `src/lib/test` 导入，依赖 Vitest setup。`createTestCaller(options?)` 返回根 router 的 caller，默认匿名；传入 `user` 构造上下文会话，也可覆盖 `db`、`headers`、`getSession`。显式 `getSession` 优先于 `user`。每个 caller 独立缓存会话；构造的会话不写入数据库，不生成登录 cookie。

```ts
// src/trpc/__tests__/example.test.ts
import { expect, test } from "vitest";
import { createTestCaller, createTestUser } from "../../lib/test";

test("读取当前用户", async () => {
  const user = await createTestUser({ name: "Alice", emailVerified: true });
  const caller = createTestCaller({ user });
  expect(await caller.user.me()).toMatchObject({ id: user.id, name: "Alice" });
});
```

测试覆盖数据库约束、认证持久化、tRPC 鉴权和请求隔离。PGlite 验证 PostgreSQL 查询语义，不验证 Neon HTTP 传输或其驱动专属 API；生产代码仍须遵守 Neon HTTP 的事务限制。

参考：[tRPC App Router](https://trpc.io/docs/client/nextjs/app-router-setup)、[Drizzle + Neon](https://orm.drizzle.team/docs/get-started/neon-new)、[Better Auth Next.js](https://better-auth.com/docs/integrations/next)、[Vitest 模块 mock](https://vitest.dev/guide/mocking/modules.html)、[Drizzle + PGlite](https://orm.drizzle.team/docs/get-started/pglite-new)。
