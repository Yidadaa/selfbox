# Web 约定

## 技术与结构

- 使用 Next.js App Router；共享 Web 组件、工具函数和主题放在 `packages/ui`，业务组件放在本应用内。
- 所有客户端页面统一放在 `views/` 下，按业务模块组织；禁止放入 `components/` 或 `comps/`。`app/` 仅保留路由入口及必要的客户端加载边界，通用组件仍放在组件目录。
- 环境变量使用 `@t3-oss/env-nextjs` 独立校验和管理。
- 应用入口地址统一使用 `BASE_URL`；显式配置优先，否则使用 `https://${VERCEL_URL}`。本地或非 Vercel 环境需显式配置，解析逻辑保留在本应用的环境变量模块。

## 渲染与数据交互

- 禁止使用 Next.js Server Actions，除非开发者显式要求。
- 面向 SEO 的页面优先使用 SSR（服务端渲染）。
- `/` 保留为公开 landing，不挂载用户登录态或 dashboard Provider。
- `/dashboard` 在 `page.tsx` 服务端校验会话，仅通过认证后加载 dashboard；未登录时加载公开登录／注册界面。界面通过客户端 `next/dynamic({ ssr: false })` 加载 React Router 声明式 `HashRouter`；子页面使用 hash 路由（如 `/dashboard#/activity`），不新增对应的 Next.js 子路由，不执行页面内容 SSR 或业务数据预取。
- 大多数页面的前后端数据交互完全通过 tRPC 完成；禁止绕过 tRPC，使用裸 Next.js App Router 接口进行业务数据交互。
- Route Handlers 仅用于挂载 tRPC 和 Better Auth 等框架适配器，业务逻辑放在 `packages/server` 服务模块。

## 组件与样式

- 统一使用 shadcn/ui（Base UI、`base-nova`、neutral 配色、Lucide 图标）；本应用的 `components.json` 与 `packages/ui/components.json` 保持一致的风格设置。
- 在仓库根目录执行 `pnpm ui:add <组件名>`；共享组件通过 `@repo/ui/components/*` 引用，生成组件后运行 `pnpm lint:fix`。
- 页面使用 Tailwind CSS v4 工具类；通过 `@repo/ui/globals.css` 引入共享主题，暗色主题使用 `dark` 类。
- 通过 `next/font/google` 加载 Geist 和 Geist Mono，供共享主题的 `font-sans` 与 `font-mono` 使用。
