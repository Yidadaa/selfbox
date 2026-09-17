# UI 约定

## 组件与结构

- 本包提供共享 Web 组件、工具函数和主题；业务组件放在各应用内。
- 统一使用 shadcn/ui（Base UI、`base-nova`、neutral 配色、Lucide 图标）；本包的 `components.json` 与 `apps/web/components.json` 保持一致的风格设置。
- 在仓库根目录执行 `pnpm ui:add <组件名>`；共享组件通过 `@repo/ui/components/*` 引用，生成组件后运行 `pnpm lint:fix`。

## 样式与主题

- 使用 Tailwind CSS v4 工具类；共享主题位于 `src/styles/globals.css`，通过 `@repo/ui/globals.css` 导出。
- 新增使用本包样式的应用时，补充共享样式的 `@source` 路径；暗色主题使用 `dark` 类。
- 共享主题将 Web 应用加载的 Geist 和 Geist Mono 映射到 `font-sans` 与 `font-mono`，保留系统字体回退。
