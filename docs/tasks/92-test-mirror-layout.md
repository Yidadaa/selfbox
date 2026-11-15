# 92 - Flutter 镜像测试目录

## 目标

测试按 `lib/` 结构镜像到 `test/`，共享夹具集中在 `test/support/`，使用 Flutter 原生发现与文件级并发；产品逻辑和业务断言保持不变。

## Checklist

- [x] 阅读迁移指引、工程规范与记忆文档；确认迁移前工作区干净。
- [x] 记录现有完整回归的用例数、退出码与 wall clock 基线。
- [x] 按实际清单用 git mv 迁移测试及夹具，统一产品代码包导入，删除聚合入口与生成器。
- [x] 同步活规范、分析与生成配置，新增 ADR 并为历史约定标注替代关系。
- [x] 验证文件映射、导入有效性与业务断言不变；确认源码无测试依赖。
- [x] 代码生成、全量格式化、静态分析、独立文件及原生完整回归通过，记录性能实测。
- [x] 审查最终差异与提交范围。

## 基线

- 指引中的数量为历史快照；实际为 141 个测试文件、3 个局部 support 文件、12 个共享夹具。
- 另有 TLS 的 2 个 PEM 测试资源同步镜像迁移；共 git mv 158 个文件。
- 聚合入口另含 1 个注册表完整性测试；删除入口时同步删除该基础设施检查，业务用例数单独比较。
- SDK 使用 `.tools/flutter`，所有门禁设置 TEMP/TMP 为仓库内 `.tools/task-temp`；生成及迁移后验证沿用 `.tools/pub-cache`。
- 基线命令：`flutter test --no-pub --reporter expanded`；日志 `.tools/task-temp/test-migration-before.log`。
- 基线退出码 0：849 项通过，其中 848 项业务测试、1 项聚合注册检查；wall clock 145.95 秒，runner 显示测试阶段 60 秒。

## 验证结果

- Slang/build_runner 成功，生成文件全部位于 `lib/gen/`，ObjectBox model JSON 无差异。
- 全量 `dart format .`：447 个文件，0 changes。
- 单文件 `provider_model_flow_test.dart`：5 项全部通过。
- 精确比对 158 个迁移文件及所有保留的 tool Dart 文件：只修改导入、图标扫描中失效的测试目录跳过条件、夹具释放说明与 TLS 资源路径；业务测试正文及断言不变，产品源码无变更。
- `test/` 保留 141 个测试文件和 3 个局部 support；`lib/` 无测试文件、support 文件及 flutter_test/mocktail 导入，活规范与代码无旧入口引用。历史 ADR、错误账本及覆盖记录按要求保留并标注现行规范。
- 默认完整回归期间观察到 8 个 flutter_tester 进程，同时验证原生文件级并发实际生效。
- 恢复依赖 lint 后发现浏览器测试直接导入传递依赖；将已有锁定的 `url_launcher_platform_interface` 2.3.2 声明为 dev_dependency，不升级包或修改测试。
- 自动审批拒绝旧空目录清理（仅返回 blocked by policy），停止清理；迁移文件已完成，宿主残留空目录不进入 Git。
- `flutter analyze --no-pub`：No issues found，覆盖 test/support、截图工具与 smoke 工具；依赖 lint 由 flutter_lints → lints/core 默认启用。
- 默认 `flutter test --no-pub --reporter expanded`（不传文件路径、不覆盖并发参数）：848 项全部通过，退出码 0；日志 `.tools/task-temp/test-migration-after.log`。
- `git diff --check` 通过；历史任务仅为任务 01 添加现状注记，其他历史任务无变更。所有依赖版本不变，lockfile 仅将已有平台接口标记为 direct dev。

## 耗时与解释

| 运行 | 测试文件 | 业务用例 | 聚合注册检查 | Wall clock | Runner 测试阶段 |
| --- | --- | --- | --- | --- | --- |
| 迁移前聚合入口 | 141 | 848 | 1 | 145.95 秒 | 60 秒 |
| 迁移后原生发现 | 141 | 848 | 0 | 115.92 秒 | 104 秒 |

这是同机、同 SDK、同测试命令的一次迁移前后记录，不是受控性能基准：两次编译/缓存状态不同，迁移后运行期间还执行了静态分析。总耗时减少约 30 秒，但 runner 阶段增加约 44 秒，不能将总耗时差直接归因于并行加速。文件级并发已实证生效；本轮保留默认并发，不合并测试或调整断言来追求跑分。

## 宿主残留

- [ ] 清理 30 个旧测试目录及原共享夹具目录（自动审批阻止；均无残留测试文件，Git 不跟踪空目录）。
