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
- [2026-11-12] [ObjectBox] 首次生成报 `objectbox-model.json` PathNotFound，建目录后仍失败 -> 生成器不创建 `output_dir`，且 build_runner 缓存了失败结果 -> 首次先 `mkdir -p lib/gen/database` 再 `dart run build_runner clean && dart run build_runner build`。
- [2026-11-12] [Riverpod+ObjectBox] `@riverpod` 返回 `Store` 时生成失败 -> riverpod_generator 早于 objectbox.g.dart 运行，看不到其 re-export 的类型 -> 类型直接从 `package:objectbox/objectbox.dart` 导入，`objectbox.g.dart` 只 `show openStore`。
- [2026-11-12] [fpdart] `Order` 同名冲突 -> fpdart 与 ObjectBox 都导出 `Order` -> 数据层 `import 'package:fpdart/fpdart.dart' hide Order;`。
- [2026-11-12] [LiquidGlass] ActionSheet 动作里 `Navigator.pop` 弹掉了页面路由 -> `showGlassActionSheet` 执行动作后自动关闭 -> 动作回调禁止再 pop。
- [2026-11-12] [Test] `GlassTabBar` 标签 `find.text` 命中两个 -> 选中/未选中两层各画一次 -> 限定 `descendant(of: GlassTabBar)` 后取 `.first`。
- [2026-11-12] [Test] 文件图片在 widget 测试/截图中永不加载，`runAsync` 里 precache 死等 -> fake-async 区内启动的 I/O 永不完成 -> 在 `pumpApp` 之前于 `runAsync` 中预热 ImageCache；交互测试改用非图片 finder。
- [2026-11-12] [IO] Windows 上同一文件出现正反斜杠混用两种路径，图片缓存失配 -> `p.join(root, 'media/x')` 保留了正斜杠 -> 相对路径按 `p.posix.split` 拆段后 `p.joinAll` 生成原生分隔符。
- [2026-11-12] [Test] 截图中 GlassTabBar 标签渲染为方块 -> 无样式文本回退到测试字体 `FlutterTest` -> 截图工具为 `FlutterTest`/`Ahem`/`Roboto` 加载系统 CJK 字体，标签样式从主题显式传入。
- [2026-11-12] [Shell] Python heredoc 含中文时按 GBK 解码失败，后续 `git commit` 仍执行 -> Windows 控制台编码 + 命令未用 `&&` 串联 -> 多语言脚本写成 UTF-8 文件后 `python -X utf8 file.py`；提交前的步骤一律 `&&` 串联。
- [2026-11-12] [Stream] `async*` + `await for` 广播流的 watch 在取消订阅时卡死测试 -> 生成器挂在内部 await，cancel 等待其退出 -> 生产代码的 watch 一律用 `StreamController(onListen/onCancel)` 显式管理订阅并串行刷新。
- [2026-11-12] [Python] 脚本里写 Dart 字符串 `'\n'` 被写成真实换行 -> 多层转义 -> 含 Dart 转义的内容用编辑工具直接写文件，不经脚本拼接。
- [2026-11-12] [LiquidGlass] `GlassListTile` 标题/分组标题、`GlassListTile.chevron` 不随 Material 主题 -> 组件用默认 Cupertino 文本与图标字体 -> 显式传 `titleStyle`/`subtitleStyle`/header 样式（主题 Token），箭头用 Material 图标。
- [2026-11-12] [JSON] 嵌套 freezed 模型 `toJson` 后 `fromJson` 报 `_X is not a subtype of Map` -> json_serializable 默认不递归序列化 -> `build.yaml` 全局 `explicit_to_json: true`。
- [2026-11-12] [Forms] `luthor` 与 `reactive_forms` 都导出 `Validator` -> 同名冲突 -> 桥接文件 `import 'package:luthor/luthor.dart' as lu;`，错误 key 用 luthor `IssueCode.name`，UI 统一映射文案。
- [2026-11-12] [LiquidGlass] `GlassSegmentedControl` / `GlassGroupedSection` 默认文本与 16pt 横向 margin 不随主题 -> 组件内部默认值 -> 显式传 `selectedTextStyle`/`unselectedTextStyle`，分组统一 `margin: AppInsets.section` 与页面边距对齐。
- [2026-11-12] [Agent] 被新问题取代的旧回合仍把回复写入时间线 -> 入库在“是否仍为当前回合”检查之前 -> 先 `await answer`，校验 run id，再持久化。
- [2026-11-12] [Test] `flutter_animate` 的 `delay`/`repeat` 在 widget 测试结束后留下 pending Timer -> 动画库内部用 Timer 实现延迟 -> 无限循环动画用 `useAnimationController` + 相位偏移自行驱动。
- [2026-11-12] [Test] `streamText` 在 widget 测试 fake-async 中永不完成 -> SDK 流水线依赖真实事件循环 -> 循环交替 `tester.runAsync(短延迟)` 与 `pump`，直到结果落库。
