# Server 约定

## 结构与配置

- 按 `src/trpc`、`src/db`、`src/auth` 划分模块，通过工厂函数接收应用配置；不读取 `process.env`，不加载 `.env`，不依赖应用代码。
- 服务实例、Drizzle CLI 配置和实际环境变量由各应用管理。

## 接口与测试

- 服务端业务逻辑放在本包，应用的 Route Handlers 仅挂载框架适配器。
- 受保护的 tRPC 接口使用 `protectedProcedure` 校验会话。
- 任何 tRPC router 相关逻辑都必须有对应的测试覆盖，并使用本包 `src/lib/test` 下的测试套件进行测试；测试文件放在对应模块的 `__tests__/` 目录，例如 `src/trpc/__tests__/router.test.ts`。
