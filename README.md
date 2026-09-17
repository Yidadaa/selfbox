# expo-starter

基于 Next.js、React 和 TypeScript 的 monorepo，使用 pnpm 与 Turborepo 管理，集成 shadcn/ui、Tailwind CSS v4 和 Biome。

## 目录

- `apps/web`：Web 应用。
- `apps/mobile`：Expo 移动应用，集成 HeroUI Native、Better Auth 和 tRPC，详见 [Mobile 文档](apps/mobile/README.md)。
- `packages/ui`：共享组件、工具函数和主题样式。
- `packages/server`：tRPC、Drizzle / Neon 数据库和 Better Auth 服务模块。
- `packages/toolchain`：Biome 与 TypeScript 共享配置。

## 开发

环境：Node.js 24+、pnpm 11.25.0。在仓库根目录执行：

```sh
pnpm install
cp apps/web/.env.example apps/web/.env.local # 填写 Web 应用的数据库和认证配置
pnpm dev           # 启动开发服务，访问 http://localhost:3000
pnpm dev:mobile    # 单独启动 Expo Go 开发服务
pnpm dev:web       # 单独启动 Web 开发服务
pnpm build         # 生产构建
pnpm lint          # 检查代码、格式和导入顺序
pnpm lint:fix      # 自动修复
pnpm format        # 格式化
pnpm check-types   # 类型检查
pnpm test          # Vitest 服务层测试（内存 PGlite，无需数据库配置）
pnpm ui:add dialog # 添加 shadcn 组件
pnpm --filter @repo/server test:watch # 监听服务层测试
pnpm db:generate   # 生成数据库迁移
pnpm db:migrate    # 应用迁移至 Web 应用配置的数据库
pnpm db:push       # 将 schema 直接同步至 Web 应用配置的数据库
pnpm db:studio     # 启动数据库管理界面
```

共享组件生成到 `packages/ui/src/components`，主题配置位于 `packages/ui/src/styles/globals.css`。生成组件后运行 `pnpm lint:fix`。

Biome 暂不格式化 Markdown 和 YAML。

环境变量归属各 `apps/*`；不要在根目录或 `packages/server` 放置 `.env`。详细接入方式见 [Web 文档](apps/web/README.md) 和 [服务包文档](packages/server/README.md)。
