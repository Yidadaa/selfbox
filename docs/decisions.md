# 架构决策记录 (ADR)

### [ADR-016] 首页输入与导航共用完整 Liquid 表面

- **背景**：首页原有输入框与 Tab 是两条独立悬浮栏；参考 ref-chat / ref-input 要求收起时合并、键盘打开时拆分。
- **决策**：Shell 统一持有 ChatComposer 与 AppDockTabs、实测停靠区高度，并通过 ShellScope 向页面传递底部避让。导航通过 Widget 插槽放入 GlassTextField.bottom，共用一层玻璃；键盘态隐藏导航并分离附件按钮。当前 liquid_glass_widgets 1.17.2 的 full shader 管线名为 GlassQuality.premium，底座、输入框、AI 胶囊、附件按钮显式使用该档位。
- **影响**：聊天页不再计算第二份键盘/导航偏移；bottom 插槽常驻、输入组件 Key 稳定以保留焦点与选区。输入最大高度扣除安全区、标题、键盘与附件，时间线跟随实测高度。Tab 保持 go_router 分支切换，不引入业务状态或新依赖。

### [ADR-017] ObjectBox 模型 JSON 必须参与构建输入

- **背景**：UI 任务的代码生成门禁发现 `lib/gen/**` 的排除规则令 ObjectBox 无法读取已提交模型，重新生成了实体与属性 UID。
- **决策**：恢复原模型，排除范围改为 `lib/gen/**/*.dart`；模型 JSON 保持为 source input。
- **影响**：生成代码仍全部输出至 lib/gen；无数据库结构改动时，objectbox-model.json 的 UID 必须保持不变。

### [ADR-001] Flutter 工具链本地化至 `.tools/`

- **背景**：机器上已有全局 Flutter（`C:\dev\flutter`），版本可能与项目要求漂移；需要可复现、项目私有的工具链。
- **决策**：Flutter stable（当前 3.47.9 / Dart 3.13.7）解压至 `.tools/flutter`，`.tools/` 加入 `.gitignore`。所有命令通过 `.tools/flutter/bin/flutter` / `dart` 执行，或先 `export PATH="$PWD/.tools/flutter/bin:$PATH"`。
- **影响**：升级 Flutter = 替换 `.tools/flutter` 目录并更新本 ADR；CI 需按同一版本安装。

### [ADR-002] 所有生成代码收敛至 `lib/gen/`

- **背景**：`*.g.dart` / `*.freezed.dart` 散落在业务目录会污染代码审查与搜索。
- **决策**：
  - `build.yaml` 用 `build_extensions` 把 `freezed` 与 `source_gen|combining_builder`（json_serializable、riverpod_generator、retrofit_generator 等）映射到 `lib/gen/{{}}`；`sources` 排除 `lib/**/__tests__/**` 与 `lib/gen/**/*.dart`，保留 ObjectBox 模型 JSON（ADR-017）。
  - `flutter_gen` → `lib/gen/assets/`；`objectbox` → `output_dir: gen/database`；`slang` → `lib/gen/i18n/`。
  - 业务源码的 `part` 用相对路径指向 `lib/gen/...`。
- **影响**：每次 `build_runner` 后必须确认 `lib/gen/` 之外无生成文件；`lib/gen/` 提交进版本库还是忽略见 ADR-005。

### [ADR-003] 测试与被测代码同级放在 `__tests__/`，`test/all_tests_test.dart` 作为唯一聚合入口

- **背景**：Flutter 工具链默认只扫描 `test/`，而规范要求测试与代码同级。
- **决策**：测试写在 `lib/**/__tests__/*_test.dart`；聚合入口命名为 **`test/all_tests_test.dart`**（偏离 AGENTS.md 的 `all_tests.dart`：`flutter test` 只收集 `*_test.dart`，否则裸跑 `flutter test` 找不到任何用例）。它以 `import ... as tN;` 引入每个测试文件并在 `main()` 中 `group(path, tN.main)`，末尾自带「注册表 == 磁盘扫描」守卫测试。`tool/gen_all_tests.dart` 扫描目录重写该文件并 `dart format`。`analysis_options.yaml` 关闭 `depend_on_referenced_packages`。共享测试夹具在 `lib/core/testing/app_widget_tester.dart`（390x844 视口、刘海/横条安全区、固定语言、完整 Provider + Glass 作用域）。
- **影响**：新增测试文件后运行 `dart run tool/gen_all_tests.dart`，遗漏时守卫测试会失败；单个测试可直接 `flutter test lib/.../__tests__/x_test.dart`。`@visibleForTesting` 成员（如 `ProviderContainer.test`）在 `lib/**/__tests__` 中会被 analyzer 报警，改用 `ProviderContainer(...)` + `addTearDown(container.dispose)`。测试代码未被 `main.dart` 引用，会被 tree-shaking 剔除。

### [ADR-004] Pragmatic Feature-First 分层，拒绝透传 UseCase

- **背景**：教条式 Clean Architecture 会产生大量一行透传类。
- **决策**：Presentation 的 `@riverpod` Controller 直接调用 Domain `Repository` 接口；仅跨多个 Repository 的编排或可复用领域算法才进入 `domain/services/`。仅在架构边界（Repository、平台网关）定义 `abstract interface class`。
- **影响**：Code review 时拒绝单方法透传类与单实现内部接口。

### [ADR-005] `lib/gen/` 不纳入版本库

- **背景**：生成文件体积大、易产生无意义的合并冲突，且可由工具链完全重建。
- **决策**：`lib/gen/` 写入 `.gitignore`，例外：`lib/gen/database/objectbox-model.json` 必须提交（ObjectBox 依赖它保持实体/属性 UID 稳定，丢失会导致 schema 迁移错误）。
- **影响**：clone 后必须先执行 `dart run slang && dart run build_runner build` 才能编译（build_runner 2.16 已移除 `-d`）。

### [ADR-006] Liquid Glass 统一设计 Token

- **背景**：Android 与 iOS 共用一套视觉，禁止 `Platform.isIOS` 分叉；业务组件禁止硬编码间距/圆角/模糊/时长。
- **决策**：`lib/core/theme/` 定义 `AppSpacing`（4/8/12/16/20/24/32/40/48）、`AppSizes`（48dp 触控热区、AppBar 高度、图标尺寸）、`AppRadius`（含同心圆角 `concentric(outer, padding)`）、`AppMotion`（按压 0.97 / 120ms / easeOutCubic）、`AppGlassTheme`（`ThemeExtension`，承载三层景深的模糊/透明度/描边）。`AppTheme.dark()` / `AppTheme.light()` 挂载全部扩展；全局 `AppScrollBehavior` 统一 `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`；全平台统一 `GlassPageTransitionsBuilder` 转场。页面统一用 `GlassScaffold` + `AppCanvas`（渐变画布），刷新式玻璃控件（`GlassButton`）不得嵌套在玻璃卡片内。
- **影响**：新增视觉参数一律先加 Token 与对应 `__tests__` 断言，再在组件中引用。

### [ADR-007] ObjectBox 使用 6.0.0-preview.6（精确锁定）

- **背景**：ObjectBox 稳定版 `objectbox_generator` 5.3.2 依赖 `analyzer <11`，而 freezed 4 / json_serializable 6.15 / build_runner 2.16 / riverpod_generator 4 要求 `analyzer ^14`，版本求解无解。
- **决策**：`objectbox` / `objectbox_flutter_libs` / `objectbox_generator` 精确锁定 `6.0.0-preview.6`（支持 `analyzer <14.5`，因此 analyzer 解析为 14.4.0）。不降级其余代码生成器。
- **影响**：ObjectBox 6 稳定版发布后立即升级并移除精确锁定；首个 `@Entity` 落地时需验证 preview 的生成产物、`objectbox-model.json` 与 Store 打开流程，并补齐临时目录 Store 测试。

### [ADR-008] 依赖版本受上游约束的已知滞后

- **背景**：要求使用最新版本，但部分包被上游约束卡住。
- **决策**：接受以下滞后，不引入 `dependency_overrides`：`cached_network_image` 3.4.1（`flutter_smooth_markdown` 要求 `^3`）；`talker_flutter` 5.1.16 与 `flutter_secure_storage` 10.x（`screen_capturer_windows` 要求 `win32 <6`）。其余直接依赖均为当前最新可解析版本。
- **影响**：上游放开约束后执行 `flutter pub outdated` 复查并升级。

### [ADR-009] i18n 关闭延迟加载 (`slang.yaml: lazy: false`)

- **背景**：slang 默认将非基准语言生成为 deferred library，`LocaleSettings.useDeviceLocaleSync()` / `setLocaleSync()` 对 zh-CN 直接抛 `_DeferredNotLoadedError`，中文设备启动即崩溃。
- **决策**：`lazy: false`，所有语言随主包加载（文案体积极小）。
- **影响**：若未来语言包体积显著增大，再改为异步 `useDeviceLocale()` 并在启动流程中 `await`。

### [ADR-010] v0 数据存储布局与测试替身

- **背景**：消息、图片、记忆文件三类数据需要可测试、可迁移，且 ObjectBox 原生异步查询在 widget 测试的 fake-async 区中无法完成。
- **决策**：所有持久化数据位于 `AppPaths.root`（应用支持目录下 `selfbox/`）：`objectbox/`、`media/`（消息图片，库内只存 `media/<uuid>.ext` 相对路径）、`memory/`（agent 记忆 Markdown 树）。`appPathsProvider` / `appStoreProvider` 在 `main()` 中覆写。Repository 层测试用临时目录真实 Store（需 `dart run tool/fetch_objectbox_native.dart` 下载宿主库）；Widget / Provider 测试用 `FakeMessageRepository`（`lib/core/testing/`）。
- **影响**：路径必须经 `MediaStore.resolve` 校验，拒绝越界（模型工具参数可控）；设计评审截图通过 `flutter test tool/screenshots --update-goldens` 生成到 `tool/screenshots/out/`（不入库）。

### [ADR-011] AI 服务商配置与密钥存储

- **背景**：需支持 chat completions / responses / messages 三种接口格式，可拉取并逐个配置模型；API Key 属敏感凭据。
- **决策**：`AiSettings`（服务商、模型能力与预算、当前模型、历史轮数）以 JSON 存于 `config/ai_settings.json`（先写临时文件再 rename 保证原子性）；API Key 仅存系统钥匙串（`SecretStore` → `flutter_secure_storage`），表单从不回显，留空即保留。模型列表经 Retrofit `GET {baseUrl}/models` 拉取（OpenAI 用 Bearer，Anthropic 用 `x-api-key` + `anthropic-version`），合并时保留已有配置，上游消失但已启用的模型不删除。Dio 日志不打印请求头与请求体。表单规则以 luthor Schema 定义于领域层（`AiSettingsSchema`），经 `luthorValidator` 接入 reactive_forms。
- **影响**：`AiSettingsService`（跨设置仓库与模型目录的编排）是唯一写入口；新增接口格式需同时扩展 `ApiFormat`、鉴权头映射与语言模型工厂。

### [ADR-012] AI 模式 Agent 设计

- **背景**：AI 模式需在全部聊天记录上检索作答、维护文件式记忆；UI 只显示最新工具调用与“正在输入”，最终文本整体渲染。
- **决策**：`AssistantAgent`（`chat/domain/services`）用 `ai_sdk_dart` `streamText` 多步工具循环（`maxSteps: 16`，总超时 3 分钟）。工具：`search_messages` / `read_messages` / `view_image`（仅视觉模型）/ `memory_list` / `memory_read` / `memory_search` / `memory_create` / `memory_patch`（强制 unified diff）/ `memory_delete`；工具失败以 `{"error"}` 返回给模型自行纠正。历史为最近 `historyTurns+1` 条消息（用户笔记带 `[#id 时间]` 前缀、AI 为 assistant，同角色合并、首条必为 user），按 `maxInputTokens - maxOutputTokens` 粗估裁剪。`view_image` 的图片经 `prepareStep` 在工具结果后注入一条 user 图片消息（工具结果只能携带文本）。流事件仅用于状态：`ToolInputStart` → 工具类别，首个 `TextDelta` → typing；最终取最后一步文本一次性入库为 AI 消息。`AssistantController` 状态机 `idle → working(activity) → idle | failed(failure, question)`，新问题取消旧问题且旧回复不入库。`LanguageModelFactory` 为网络边界（测试用 `ScriptedLanguageModel`）。
- **影响**：新增工具需同步 `AgentToolKind.ofTool` 与状态文案；widget 测试中 SDK 流需 `tester.runAsync` 交替推进。

### [ADR-013] 平台权限：相册

- **背景**：笔记可附图片（`image_picker`，仅从相册选择）。
- **决策**：iOS `Info.plist` 声明 `NSPhotoLibraryUsageDescription`（未声明会在首次选图时崩溃）。Android 使用系统 Photo Picker，无需运行时权限与 Manifest 声明，双端行为对等：均为用户点击图片按钮时才弹出系统选择器（Just-in-Time）。macOS 选图走系统打开面板，沙盒 entitlements 待桌面端需要时补充。
- **影响**：新增相机拍照时需同时补 `NSCameraUsageDescription` 与 Android `CAMERA` 权限并更新本 ADR。

### [ADR-014] Android 构建：compileSdk 37 / AGP 9.5.1 / Gradle 9.6.0

- **背景**：`permission_handler_android` 14.x 要求以 API 37 编译；SDK 仅提供 `platforms;android-37.0`，模板自带 AGP 9.1.0 无法解析 `compileSdk = 37`，且 app 端还需 compileSdk ≥ 37。
- **决策**：AGP 升至 9.5.1（随之 Gradle wrapper 升至 9.6.0），`android/app/build.gradle.kts` 固定 `compileSdk = 37`（targetSdk 仍跟随 Flutter 默认）。新增 `cupertino_icons`：liquid_glass_widgets 内部引用 Cupertino 图标字体，缺失会显示方块。
- **影响**：Flutter 默认 compileSdk 升到 ≥37 后可改回 `flutter.compileSdkVersion`。Release 包暂用 debug 签名，发布前需配置正式签名。

### [ADR-015] Android release：正式签名、网络权限、仅声明用到的权限

- **背景**：要装到真机长期使用；debug 签名的 APK 日后换正式签名只能卸载重装，会丢失本地笔记与记忆。模板 release manifest 缺少 `INTERNET`；`record` 插件合并进 `RECORD_AUDIO`，v0 并不录音。
- **决策**：release 用本地私钥签名：keystore 在 `%USERPROFILE%/.selfbox-signing/selfbox-release.jks`，`android/key.properties`（已 gitignore）提供路径与密码；缺少该文件时回退 debug 签名以保证新克隆可构建。主 manifest 声明 `INTERNET`，并以 `tools:node="remove"` 移除 `RECORD_AUDIO`，录音功能落地时再按 Just-in-Time 恢复并更新本 ADR。真机为 arm64，用 `--target-platform android-arm64` 构建（只打 x86_64 时插件仍会塞入不完整的 arm64 目录，arm64 设备启动即崩溃）。
- **影响**：keystore 与密码丢失后将无法覆盖安装更新——务必备份 `.selfbox-signing/` 与 `android/key.properties`。
