# 项目约定

目录专属约定见各应用和共享包下的 `AGENTS.md`。

## 技术与结构

- 使用 Node.js 24+、pnpm 和 Turborepo 管理 TypeScript monorepo；pnpm 版本以根目录 `package.json` 为准。
- 路径命名保持精简，禁止 `foo/foo-bar.ts` 这类目录名与文件名前缀重复的模式；例如使用 `dashboard/client.tsx`，禁止 `dashboard/dashboard-client.tsx`。
- 开发配置集中在 `packages/toolchain`。
- 环境变量由各 `apps/*` 独立校验和管理；`.env*`、服务实例、Drizzle CLI 配置和 Turbo 环境变量声明均归属应用，禁止在根目录或共享包集中配置实际环境变量。

## 开发与文档

- 所有测试文件必须放在对应模块或目录下的 `__tests__/` 目录，禁止与源代码文件同级混放；例如 `src/lib/__tests__/utils.test.ts`。
- 客户端 UI 组件不新增测试，除非用户显式要求；所有端的逻辑模块都必须有对应的测试覆盖，至少包含正常路径（happy path）测试。
- Biome 统一负责代码检查、格式化和导入排序。
- 代码变更后运行 `pnpm lint`、`pnpm check-types`；涉及构建、依赖或样式链路时运行 `pnpm build`。
- README 类文档和项目约定使用精简中文撰写，重点记录目录、常用命令和重要决策。
- UI 文字遵循项目的 i18n 规范。
