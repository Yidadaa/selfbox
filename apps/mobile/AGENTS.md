# Mobile 约定

- 使用 Expo SDK 57；调整 Expo 配置前查阅 https://docs.expo.dev/versions/v57.0.0/ 。
- 原生 UI 使用 HeroUI Native + Uniwind，样式入口为 `global.css`，不导入 Web 的 shadcn / DOM 组件。
- 所有 UI 有限使用 heroui native，使用组件之前先读文档：https://heroui.com/native/llms.txt
- 页面安全区统一使用 `components/safe-area.tsx`，确保 Uniwind 的布局和主题样式生效。
- 列表卡片和 Surface 禁止阴影；图标禁止添加底色，选中态使用图标颜色、描边或勾选标记。
- `app/` 仅放路由入口与布局，页面实现放在 `views/`，文案集中在 `i18n/`。
- 配置 schema 集中在 `env/schema.ts`；`EXPO_PUBLIC_*` 必须静态读取，构建期兼容 `BASE_URL` / `VERCEL_URL`。自动开发主机、`/dev` 和地址覆盖仅用于开发版。
- 会话存入 SecureStore，普通设置通过 Zustand + AsyncStorage 持久化。
