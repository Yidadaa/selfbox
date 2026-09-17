# Toolchain 约定

- 集中管理共享开发配置，按 `biome`、`typescript` 分类。
- Biome 统一负责代码检查、格式化和导入排序。
- 应用的实际环境变量和 Turbo 环境变量声明由各应用管理，不放入本包。
