# 架构决策记录 (ADR)

### [ADR-022] 设置确认使用原生白色弹层

- **背景**：清除数据确认的全屏 glass action sheet 使用自有渲染层，弹出时有明显卡顿及文字装饰异常；历史轮次更适合连续数值选择。
- **决策**：清除确认使用白色 `AppConfirmDialog`，保持 34dp 圆角和确认/取消语义。布局沿用 Liquid Dialog 的 320dp 宽度、左对齐标题、16dp 操作区边距及两个等宽 48dp 胶囊按钮；文案放不下时纵向排列，内容过高时可滚动。历史轮次使用白色 `ModalBottomSheet` 与 `CupertinoPicker`，可选 0–100 并仅在保存时写入。
- **影响**：这两个设置流程不依赖 Liquid Glass shader；清除确认显式关闭文字装饰，选择器支持保存与取消。

### [ADR-021] 聊天顶部资料入口与消息搜索

- **背景**：聊天顶部需要呈现个人资料身份，并提供设置和消息历史的快捷入口。
- **决策**：聊天页顶部使用左右 premium 玻璃图标按钮及中心纵向头像 / 昵称控件；56dp 圆头像绘制在较小字号的昵称玻璃胶囊前方，两者重叠且整体居中可点击。聊天滚动视口从屏幕顶部开始，初始内容用顶部内边距避让头像栏，滚动时可透过玻璃按钮。资料进入根 Navigator 的资料编辑页，设置切换到 Me 分支，搜索进入根 Navigator 的独立页面并调用既有 `MessageRepository.find`。
- **影响**：消息搜索沿用 `MessageQuery` 的分词匹配并限制最多 100 条；空查询不读取全量历史。顶部视觉仍由共享 `AppPageScaffold` 承载，通过可选 `titleContent` 定制中心区域。

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

### [ADR-018] 消息相册与个人资料 / 数据重置边界

- **背景**：聊天需要 iMessage 蓝色气泡、内置时间与多图堆叠；个人设置增加资料、存储与独立 AI 页面。
- **决策**：图片消息限制单图 224×180dp，最多绘制 3 张堆叠卡片，保留完整相册并通过 PageView 浏览。发送蓝色使用 #006FE6 保持白字 AA 对比度。个人资料存 ObjectBox 独立 ProfileEntity，头像存 media 相对路径。存储重置由 core 组合边界等待 composer、取消并排空 AI 回合、等待设置写入后，调用跨仓库领域服务清除密钥、配置、消息、记忆、资料和图片。
- **影响**：不删除正在打开的 ObjectBox 目录，统计明确包含预分配空间；清除失败可重试。子页面使用强类型路由，资料 / 存储 / 关于覆盖底部栏。版本从 package_info_plus 读取安装包元数据。玻璃控制与分组使用 premium（full）管线。

### [ADR-019] 固定控件玻璃预算、二级页与 Agent 调用日志

- **背景**：输入栏与 Tab 边距不统一，部分二级页仍显示 Tab；设置列表和表单的 full 玻璃层过重，Agent 调用缺少可查看的轨迹。
- **决策**：停靠区统一 16dp 左右与安全区外底距，输入行用标准玻璃表面和垂直居中的文本框；仅独立悬浮按钮使用 premium，固定表单按钮、分组和导航表面使用 standard。所有二级路由由根 Navigator 覆盖底部栏。Agent 回合与工具状态写入全局 Talker，设置提供 TalkerScreen 入口。
- **影响**：日志只含回合编号、消息 ID、工具名和状态，不记录正文、工具参数、结果或密钥；Talker 历史仅在当前进程保留。本文更新 ADR-018 中原先的 premium 范围。
- **输入基线补充**：聊天正文与 placeholder 从同一 bodyLarge 派生并显式统一 alphabetic，避免中文主题 ideographic 与 RenderParagraph 基线实现差异导致提示下移；不改变全局中文排版。
- **键盘态尺寸补充**：分离的附件圆钮与单行输入面统一 48dp；输入面移除上、下、右额外 padding，保留左侧文字内边距、发送热区与多行自然增长，并按实际 padding 计算编辑高度预算。发送圆形 36dp 位于 48dp 热区中央，单行时上、下、右可见留白均为 6dp；测试测量实际圆形边缘，不能只比较热区或中心线。
- **收键盘时机补充**：ChatComposer 通过 useListenable 响应 FocusNode；仅在键盘存在且输入持有焦点时使用编辑布局，失焦立即启动导航展开。高度预算与 Shell 底部定位仍消费实际 inset，避免收起期间提前忽略键盘；键盘归零不再二次展开导航，重新聚焦可直接恢复编辑布局。
- **表面与底部画布更新**：AI 消息与图片框使用无阴影的纯白 RoundedSuperellipse 卡片，不执行 Liquid Glass shader；我方消息保留蓝色气泡，发送按钮沿用同一 bubbleMine token。footer 使用单独更低不透明度 token。浅色全局画布渐变保持底部暖白色终点。

### [ADR-020] 消息元信息外置与图片轻玻璃框

- **背景**：时间 / AI 标记需要显示在气泡外底部；图片不再被发送方实色消息背景包裹。
- **决策**：MessageBubble 按消息方向排列独立图片堆叠、可选文字气泡和单一 footer；元信息统一使用 foregroundMuted。图片每层采用 standard GlassContainer、4dp 内边距与 16dp 外圆角 / 12dp 内圆角，通过测试锁定默认圆角契约；堆叠区域使用 RepaintBoundary。
- **影响**：图文消息的文字单独显示为气泡，footer 位于整条消息内容底部；纯图片无实色气泡。保留最多 3 层堆叠、完整张数、预览与长按。本决策替代 ADR-018 的气泡内时间布局。
- **AI 表面补充**：AI 文字 / 图片说明使用 GlassContainer、GlassQuality.standard 与 MessageTokens.radius 圆角，无旧 bubbleOther 实色衬底；外层 RepaintBoundary 隔离滚动重绘。玻璃材质继承主题，正文沿用主题前景色，footer 在容器外。用户发送气泡仍采用蓝色连续尾部轮廓。

### [ADR-021] 非玻璃表面跟随系统明暗模式

- **背景**：消息卡片与弹层为性能改用不透明表面后，固定白色在深色模式下刺眼；GlassScaffold 的顶部滚动过渡未收到画布颜色，回退色可能与背景不符。
- **决策**：AppGlassTheme 定义 AI/图片实色表面及对比文字、Dialog 操作填充色和危险操作色，按亮度切换。AppPageScaffold 将画布首色传给 GlassScaffold 作为顶部过渡目标。确认 Dialog 与模型/历史轮次 Picker Sheet 保持原布局与圆角，但底色、文字和选中背景取主题 Token；两类 Picker 共用布局。
- **影响**：浅色模式 AI/图片卡片仍为纯白，深色模式使用不透明深灰蓝；弹层不启用实时模糊。新增非玻璃表面必须从主题取颜色并覆盖双模式测试。

### [ADR-022] 设置流程的统一 Liquid Surface

- **背景**：设置列表的玻璃分组默认 12dp 圆角，服务商详情的 solid 分组默认为 26dp 且浅色模式呈纯白，跨页视觉不一致。
- **决策**：设置、服务商与模型配置中的卡片和分组统一使用默认 `GlassSurfaceStyle.glass`、`GlassQuality.standard` 与 `AppRadius.lg`（28dp）圆角；输入控件仍采用独立的内嵌表面。
- **影响**：这些页面的卡片继续继承全局明暗玻璃主题；后续新增设置分组须沿用相同材质与圆角。

### [ADR-023] 首次欢迎与用户记忆

- **背景**：空聊天与空记忆的占位卡片缺乏引导；用户需要直接维护记忆文件。
- **决策**：消息库为空时仅在 UI 渲染三条临时 AI 气泡，不写入数据库或 Agent 历史。启动时在记忆仓库创建根目录 `user.md`，资料保存后仅同步其开头的姓名状态句，保留其他内容；完整改写过的文件不再自动覆盖。Agent 每轮提示词读取当前资料和应用语言，并提供本地时间、时区与简短对话风格。手动编辑使用 `SmoothMarkdownEditor`，仓库 `replace` 比较打开时原文，以拒绝并发覆盖。
- **影响**：清除全部数据后立即重建无昵称的 `user.md`；编辑页固定打开时的原文作为并发校验基准，冲突时保留草稿并提示重新打开文件。记忆新增入口浮于 tab 栏上方，编辑页由根路由覆盖 tab。
