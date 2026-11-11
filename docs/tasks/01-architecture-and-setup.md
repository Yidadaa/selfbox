# 01 - Architecture & Setup

> 目标：可复现工具链 + 代码生成全部收敛 `lib/gen/` + 同级 `__tests__` 桥接 + 核心基建（Theme / Error / Logger / Router / i18n / Assets）。

## 工具链

- [x] Flutter stable 3.47.9（Dart 3.13.7）安装至 `.tools/flutter`，`.tools/` 已忽略（ADR-001）
- [x] `flutter create`（android / ios / macos / windows / linux，org `com.yidadaa`）

## 工程配置

- [x] `pubspec.yaml` 依赖安装（运行时 + dev，最新可解析版本；例外见 ADR-007 / ADR-008）
- [x] `build.yaml`：freezed / combining_builder 输出至 `lib/gen/`，排除 `__tests__`
- [x] `slang.yaml` → `lib/gen/i18n/`（`lazy: false`，ADR-009）；`flutter_gen` → `lib/gen/assets/`；`objectbox.output_dir: gen/database`
- [x] `analysis_options.yaml`：strict-casts / strict-inference / strict-raw-types，关闭 `depend_on_referenced_packages`，排除 `lib/gen` 与 `.tools`
- [x] `.gitignore`：`.tools/`、`lib/gen/`（保留 `objectbox-model.json`，ADR-005）、`.env`

## 测试桥接

- [x] `tool/gen_all_tests.dart` 生成 `test/all_tests_test.dart`（命名原因见 ADR-003）
- [x] 聚合文件内置「注册表与磁盘同步」守卫测试
- [x] 共享夹具 `lib/core/testing/app_widget_tester.dart`（390x844 + 安全区 + 固定语言）

## 核心基建（测试先行）

- [x] `core/theme/__tests__/app_theme_test.dart` → Token（8pt 网格 / 同心圆角 / 触控 48dp）、明暗主题扩展挂载、WCAG AA 对比度、统一转场、统一回弹滚动
- [x] `core/theme/`：`AppSpacing` / `AppSizes` / `AppRadius` / `AppMotion` / `AppGlassTheme` / `AppTheme` / `AppScrollBehavior`
- [x] `core/error/__tests__/app_failure_test.dart` → 相等性、`fromError`、`TaskEither.tryCatch` 集成、`isRetryable` 穷尽分支
- [x] `core/error/app_failure.dart`（`@freezed sealed`）
- [x] `core/logger/__tests__/talker_provider_test.dart` → keepAlive 单例、`main` 注入覆盖、错误入历史
- [x] `core/logger/talker_provider.dart`（`main` 注入 + Riverpod / Route observer + 全局错误捕获）
- [x] `core/widgets/__tests__/app_canvas_test.dart` → 明暗渐变、全幅铺满
- [x] `core/widgets/app_canvas.dart`
- [x] `core/router/__tests__/app_router_test.dart` → `/` 渲染首页、未知路径 404、返回按钮 ≥48dp 且回到首页
- [x] `core/router/`：go_router_builder 强类型路由 + `appRouterProvider` + `NotFoundPage`
- [x] `features/home/presentation/pages/__tests__/home_page_test.dart` → en / zh-CN 渲染、玻璃结构、内容不被 AppBar 遮挡、AppBar 高度契约
- [x] `features/home/presentation/pages/home_page.dart`
- [x] `main.dart` / `app.dart`：ProviderScope + TranslationProvider + LiquidGlassWidgets.wrap + Talker

## 门禁

- [x] `dart run slang` && `dart run build_runner build`，确认 `lib/gen/` 之外无生成文件
- [x] `flutter analyze` 0 issues
- [x] `flutter test` 39/39 通过
- [x] `flutter build windows --debug` 成功（原生插件可编译）
- [ ] 真机 / 模拟器（Android、iOS）冒烟运行

## 延后（首个需要它的 Feature 落地时完成，避免推测性基建）

- [ ] `core/database/`：ObjectBox `Store` Provider（需至少一个 `@Entity`）+ 临时目录 Store 测试（注意 ADR-007 preview）
- [ ] `core/network/`：Dio + Talker 拦截器、WebSocket 指数退避重连 / 心跳
- [ ] `core/env/`：`@Envied` 配置（需 `.env` 与具体变量）
- [ ] `core/theme/`：`flutter_smooth_markdown` 的 `MarkdownStyleSheet` / `MarkdownEditorThemeData` Token 映射
- [ ] `GlassTabBar.bottom` + `StatefulShellRoute` 底部悬浮玻璃导航（≥2 个顶级 Tab 时）
- [ ] 平台权限声明（`permission_handler` / `record` 使用时，Android/iOS 对等 + ADR）
- [ ] Skeletonizer 加载态 / 空态 / 错误态组件（首个异步列表落地时）
