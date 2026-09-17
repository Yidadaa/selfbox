# @repo/toolchain

集中管理共享开发配置：

- `biome/base.json`：代码检查、格式化和导入排序，由根目录 `biome.json` 加载。
- `typescript/base.json`：TypeScript 基础配置。
- `typescript/nextjs.json`：Next.js 配置。
- `typescript/expo.json`：Expo 项目规则，与应用安装的 `expo/tsconfig.base` 一起继承。
- `typescript/react-library.json`：React 组件库配置。

TypeScript 配置通过 `@repo/toolchain/typescript/<文件名>.json` 继承。
