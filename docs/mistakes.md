# 错误账本 (Mistakes Ledger)

> 格式：`- [日期] [领域] 现象 -> 根因 -> 铁律`。只记高信息熵条目。

- [2026-11-12] [Toolchain] 自动权限模式下执行新下载的 `.tools/flutter` 被拦截 -> 工具链落地后先由用户确认/授权 -> 需要 `.claude/settings.json` 允许 `Bash(./.tools/flutter/bin/*)` 或用户手动跑一次。
- [2026-11-12] [Pub] `objectbox_generator` 稳定版与新版 analyzer 冲突导致求解失败 -> 生成器链 analyzer 主版本不一致 -> 新增生成器先 `pub add --dry-run` 单独探测，冲突时查各版本 `analyzer` 约束再定版（见 ADR-007）。
- [2026-11-12] [BuildRunner] `build_runner build -d` 报 options removed -> build_runner 2.16 移除 `--delete-conflicting-outputs` -> 直接 `dart run build_runner build`。
- [2026-11-12] [Test] `flutter test` 报 test 目录无用例 -> 聚合文件 `all_tests.dart` 不以 `_test.dart` 结尾 -> 聚合入口必须叫 `test/all_tests_test.dart`。
- [2026-11-12] [Riverpod] `ProviderContainer.test` 在 `lib/**/__tests__` 触发 `invalid_use_of_visible_for_testing_member` -> analyzer 只把 `test/` 视为测试目录 -> 用 `ProviderContainer(...)` + `addTearDown(container.dispose)`；`Override` 类型需 `import 'package:hooks_riverpod/misc.dart'`。
- [2026-11-12] [Slang] zh-CN `setLocaleSync` 抛 `_DeferredNotLoadedError` -> slang 默认 deferred 加载非基准语言 -> `slang.yaml` 设 `lazy: false`（ADR-009），每个页面测试必须覆盖全部 `AppLocale.values`。
- [2026-11-12] [LiquidGlass] 首页卡片被玻璃 AppBar 遮挡 -> `GlassScaffold` 默认 `extendBody`，不给 body 注入 padding -> 可滚动 body 必须自行 inset `MediaQuery.paddingOf(context).top + AppSizes.appBarHeight`，并有测试锁定 `GlassAppBar` 默认高度 == Token。
- [2026-11-12] [Lint] `toolbarHeight: AppSizes.appBarHeight` 触发 `avoid_redundant_argument_values` -> 值等于包默认值 -> 不传参，改用契约测试锁定默认值与 Token 一致。
