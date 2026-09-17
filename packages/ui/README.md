# @repo/ui

共享 shadcn/ui 组件库，使用 Base UI、Tailwind CSS v4 和 `base-nova` 风格。

- `src/components/`：组件，通过 `@repo/ui/components/*` 引用。
- `src/lib/`：工具函数，如 `@repo/ui/lib/utils` 中的 `cn`。
- `src/styles/globals.css`：共享主题，通过 `@repo/ui/globals.css` 引入。

在仓库根目录运行 `pnpm ui:add <组件名>` 添加组件，再运行 `pnpm lint:fix`。

暗色主题通过 HTML 元素上的 `dark` 类启用。新增应用时，将其源码目录加入共享样式的 `@source`。
