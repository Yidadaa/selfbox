# Web 应用

## 开发设置

要求 Node.js 24+ 和 pnpm 11.25+。在仓库根目录安装依赖：

```sh
pnpm install
```

在 `apps/web/.env.local` 配置：

```env
DATABASE_URL=postgresql://...
BETTER_AUTH_SECRET=至少 32 个字符的密钥
BASE_URL=http://localhost:3000
```

`BASE_URL` 未配置时，部署环境会使用 `VERCEL_URL` 自动生成；本地开发建议显式设置。可用以下命令生成认证密钥：

```sh
openssl rand -base64 32
```

## 常用命令

```sh
pnpm dev:web                         # 启动开发服务器
pnpm --filter web build              # 构建
pnpm --filter web lint               # 检查代码
pnpm --filter web check-types        # 类型检查
pnpm --filter web test               # 运行测试
pnpm --filter web db:generate        # 生成迁移
pnpm --filter web db:migrate         # 执行迁移
pnpm --filter web db:push            # 直接同步 schema
pnpm --filter web db:studio          # 打开 Drizzle Studio
```

开发服务器地址：http://localhost:3000
