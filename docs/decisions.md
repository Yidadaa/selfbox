# 架构决策记录 (ADR)

### [ADR-045] AI 错误气泡使用正文内联操作

- **背景**：配置缺失与请求失败的恢复动作排在气泡外，独立触控高度与小号按钮字体使错误状态排版割裂。
- **决策**：错误说明、去设置/重试及关闭统一放进气泡内的同一 Text.rich 段落；操作使用 baseline 对齐的 WidgetSpan + 无内边距 TextButton，沿用正常 AI 消息正文样式和固定正文 strut，自然换行。行内按钮按本次交互要求使用文字高度，WidgetSpan 负责字体缩放，内部 Text 避免重复缩放。
- **影响**：恢复设置、重试当前问题和关闭错误的行为不变；不再显示气泡外按钮或关闭图标。测试与真实字体截图覆盖明暗主题、中英文、280dp 大字换行和基线。

### [ADR-044] 短时记忆按模型上下文百分比分配

- **背景**：固定历史消息数量无法反映模型上下文大小或长短消息的实际成本，需要按当前模型的容量调整短时记忆。
- **决策**：以 `shortTermMemoryPercent` 保存 10–60 的整数百分比，默认 20；预算为模型完整 `maxInputTokens × percent ~/ 100`，不先扣除输出再计算比例。旧 `historyTurns` 不具备等价换算，读取时忽略并使用 20%，其余设置保留；持久化仅写新字段，越界新值在解码及编辑时归一化。Sheet 第一行是 1% 步进的 standard GlassSlider 和当前百分比，第二行仅用居中的大号数字显示实时 token 预算，未选择模型时显示未设置；取消、保存位于底部两个等宽列。滑块草稿经 reactive_forms + Luthor 校验，仅保存时落盘。
- **影响**：Agent 每批读取 64 条、按时间与 ID 倒序连续累加，下一条放不下即停止，不再限制总消息数；当前问题去重后始终保留，禁止混入问题之后的新消息。简单估算按每 3 个 ASCII 字符约 1 token、每个非 ASCII BMP 字符约 1 token、每个增补字符约 2 tokens 累加取整，每条另计 8 tokens 的消息封装；用户文本含时间/ID/附件标记，AI 文本不加用户前缀。历史目标包含当前问题，并受扣除系统文本和输出预算后的剩余空间约束；发送前恢复时间顺序、合并同角色消息，保留原协议兼容处理。截图和测试覆盖模型容量变化、精确边界、跨批次、失败、明暗主题与窄屏。

### [ADR-043] Agent 步骤与回复固定左锚点

- **背景**：思考与工具卡宽度不同，默认居中的 AnimatedSwitcher 在旧卡移除时使新卡横跳；最终回复还沿用了用户发送的右侧入场轨迹。
- **决策**：状态切换的叠放和尺寸动画统一左下对齐，保持 560ms 淡化与主题定义的纯纵向位移。已持久化的 AI 回复采用同一左下锚点和纵向位移，用户消息保留原发送轨迹。消息行的入场配置与长按操作独立到 ChatTimelineMessageRow。
- **影响**：新旧状态同时存在及快速打断时均不得改变左边缘；测试按 16ms 采样真实表面坐标，覆盖明暗主题、中英文、280/390dp 和最终回复，截图夹具保留切换中间帧供复查。替代 ADR-038 中未明确锚点的切换约定。

### [ADR-042] Header、Dialog 与 AI Composer 光晕契约

- **背景**：标准标题横向撑满且与按钮大小不一致，弹层取消/删除描边突兀；AI 彩边包住开关和附件，在键盘开合时偏离输入玻璃。
- **决策**：标准标题按文本取宽、固定 48dp，页面图标按钮统一 48dp。共享动作改用无描边的轻柔填充，删除使用淡红语义。AI 标识改为输入 + Tab 玻璃背后的四团淡彩光晕，按同一 `LiquidShape` 裁切，开关/附件预览在外；12 秒循环中珊瑚暖色始终保留在左侧。光晕以 700ms 渐显/旋转放大入场、500ms 退场，玻璃 tint 同步插值。浅色模式以同一形状绘制 1dp 白细边，暗色只保留库自带高光。AI/AI 待命使用 400ms 位移淡化与宽度过渡。
- **影响**：替代 ADR-038 的彩色描边与 ADR-041 的动作按钮描边；动画只重绘独立背景层，关闭 AI 时停止循环，减少动态效果时使用静态光晕。测试覆盖动画反转、区域裁切、16 个相位的暖色保留、键盘/失焦/多行输入与明暗主题。

### [ADR-034] Markdown 子级标记与父级正文对齐

- **背景**：默认列表在已缩进的正文内再次按层级增加 24dp，四级列表在手机消息气泡内可溢出，且两位编号导致同级正文错位。
- **决策**：通过 `flutter_smooth_markdown` 公开的 `BuilderRegistry` 统一覆盖 list 布局；子级标记左边缘对齐父级正文起始位置，标记与正文间距使用主题 Token。同级编号按实测最宽标记统一右对齐，内联正文继续调用库的渲染器，保留加粗、链接与任务勾选状态。
- **影响**：AI 消息、思考串流、记忆阅读及编辑预览使用同一 builder；不修改 pub cache、不替换 Markdown 引擎，运行中字体缩放和主题变化会重新计算标记宽度。

### [ADR-035] 历史图片浏览与媒体压缩

- **背景**：图片查看器只在当前消息的图片间切换，缺少历史缩略图导航；原图直接入库会增大本地存储和视觉模型请求负担。
- **决策**：消息仓库按时间升序提供去重后的全部历史图片路径；查看器以懒构建 PageView 浏览，并提供可横向滚动的懒构建缩略图栏。MediaStore 在 isolate 中按方向修正并将长边限制到 2048px，以 JPEG quality 85 保存模型使用的主图，同时生成长边 320px、quality 70 的 `.thumb.jpg` 旁车文件；删除图片时一并删除旁车文件。
- **影响**：数据库仍只保存主图相对路径，不需要 ObjectBox schema 迁移；旧图片没有缩略图时，预览栏回退为解码主图。无法解码的格式或损坏图片返回校验失败，不会写入半成品。缩放后的主图供 AI 图片读取路径复用。

### [ADR-036] Chat Shell 玻璃层预算

- **背景**：Chat 页面和 Shell 重复创建 `GlassScaffold`，且固定头像、导航按钮、AI 开关与键盘附件按钮使用 premium，Debug/Profile 下会触发多层高成本玻璃渲染与性能监控。
- **决策**：Shell 只负责画布、分支栈和浮动停靠区，不再额外创建 `GlassScaffold`；页面保留自己的 scaffold 和顶部渐隐。Chat 固定控件使用 standard，premium 留给独立悬浮操作。
- **影响**：Chat 首屏应只有一个 `GlassScaffold`；其顶部滚动边界由页面自身控制。独立图片查看器关闭按钮仍可使用 premium。

### [ADR-033] 底部 Dock 使用主题化 Chrome 玻璃层

- **背景**：聊天输入框和 Tab 停靠区过于透明，消息滚动到其下方时前后景对比不足。
- **决策**：输入表面与 Tab Dock 使用独立 `GlassContainer` layer，继续采用 standard 质量，并从当前 `AppGlassTheme` 读取更强的 `chromeBlur` 和亮度专属 `chromeTint`。
- **影响**：浅色使用高不透明度白色遮罩，深色使用高不透明度深色遮罩；两种遮罩都维持前景文字 AA 对比度。仅固定底部控件增加模糊层，滚动消息卡片不增加 shader。

### [ADR-032] 已添加模型的真实可用性探测

- **背景**：模型目录可拉取不代表某个模型可调用；用户需要在配置面板中直接确认服务商密钥与模型请求是否可用。
- **决策**：配置面板提供“测试模型”，从当前设置重新读取已启用模型和系统密钥，经现有 SDK 模型工厂发起一次不带工具的短文本请求；20 秒超时、不重试，成功或失败都释放客户端。探测结果仅作为面板临时状态展示，不保存回复、聊天消息或设置。领域层通过 `ModelProbe` 隔离网络，顶层 Riverpod Provider 组合设置仓库与聊天模型工厂，避免设置页面引用其他 Feature 的内部实现。
- **影响**：测试成功表示该模型完成一次实际请求，不代表所有能力（图片、思考）均可用；接口错误和缺失密钥按现有本地化故障文案显示。探测会产生一次服务商 API 请求。

### [ADR-031] 服务商目录与已添加模型分离

- **背景**：自动拉取的全部模型直接堆在服务商页面，目录较长时难以查找，也无法区分可用模型与用户已配置模型。
- **决策**：保存新服务商后拉取目录，但页面初始只展示已添加模型（0 个）。未添加模型留在目录中，通过带搜索、多选和懒构建列表的半屏面板批量启用；首个启用模型自动成为当前模型。已添加行可快速设置图片、思考与等级，名称打开半屏配置上下文预算和删除。删除只关闭模型，目录项保留以便重新添加。
- **影响**：目录刷新保留已启用模型配置与上游临时缺失的已启用项；选择器和配置面板使用随明暗主题变化的不透明表面，确认删除仍走项目自有 Dialog。目录合并用集合成员查找，避免长目录平方级扫描。

### [ADR-029] 项目自有 Dialog 作为唯一模态操作表面

- **背景**：消息、记忆和服务商操作仍通过 GlassActionSheet 呈现，而清除数据已使用不透明自有 Dialog；不同弹层的渲染成本与布局不一致。
- **决策**：确认操作统一使用 `AppConfirmDialog`，多操作菜单使用 `AppActionDialog`，两者共用不透明主题表面、34dp 圆角和 48dp 胶囊按钮。移除业务代码中的 GlassActionSheet；选择器继续使用 Bottom Sheet + Picker。弹窗文案在打开前读取，避免页面卸载后 builder 再访问旧 context。
- **影响**：业务页面不得调用 Liquid Dialog / GlassActionSheet 或直接构造其他 Dialog。新增模态操作样式先扩展项目自有组件并测试明暗模式、取消与确认行为；保留现有 Bottom Sheet 选择器。

### [ADR-030] 顶部渐隐由共享页面组件绘制

- **背景**：`GlassScaffold` 的顶部渐隐优先使用异步捕获的背景纹理，主题色参数只用于回退；运行中切换明暗主题时可能短暂显示旧浅色纹理。
- **决策**：`AppPageScaffold` 关闭依赖库的顶部边缘效果，并在全屏滚动内容上方、玻璃标题栏下方绘制取自当前 `AppGlassTheme.canvasGradient.first` 的渐隐；高度沿用安全区、标题栏和 20dp 延伸，且不拦截触控。
- **影响**：主题切换直接触发渐隐重绘，不依赖纹理捕获时机；页面内容继续在标题栏下滚动，玻璃背景采样和其他控件保持原有路径。

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
- **决策**：AppGlassTheme 定义 AI/图片实色表面及对比文字、Dialog 操作填充色和危险操作色，按亮度切换。AppPageScaffold 的顶部过渡最终由 ADR-030 接管。确认 Dialog 与模型/历史轮次 Picker Sheet 保持原布局与圆角，但底色、文字和选中背景取主题 Token；两类 Picker 共用布局。
- **影响**：浅色模式 AI/图片卡片仍为纯白，深色模式使用不透明深灰蓝；弹层不启用实时模糊。新增非玻璃表面必须从主题取颜色并覆盖双模式测试。

### [ADR-022] 设置流程的统一 Liquid Surface

- **背景**：设置列表的玻璃分组默认 12dp 圆角，服务商详情的 solid 分组默认为 26dp 且浅色模式呈纯白，跨页视觉不一致。
- **决策**：设置、服务商与模型配置中的卡片和分组统一使用默认 `GlassSurfaceStyle.glass`、`GlassQuality.standard` 与 `AppRadius.lg`（28dp）圆角；输入控件仍采用独立的内嵌表面。
- **影响**：这些页面的卡片继续继承全局明暗玻璃主题；后续新增设置分组须沿用相同材质与圆角。

### [ADR-023] 首次欢迎与用户记忆

- **背景**：空聊天与空记忆的占位卡片缺乏引导；用户需要直接维护记忆文件。
- **决策**：消息库为空时仅在 UI 渲染三条临时 AI 气泡，不写入数据库或 Agent 历史。启动时在记忆仓库创建根目录 `user.md`，资料保存后仅同步其开头的姓名状态句，保留其他内容；完整改写过的文件不再自动覆盖。Agent 每轮提示词读取当前资料和应用语言，并提供本地时间、时区与简短对话风格。手动编辑使用 `SmoothMarkdownEditor`，仓库 `replace` 比较打开时原文，以拒绝并发覆盖。
- **影响**：清除全部数据后立即重建无昵称的 `user.md`；编辑页固定打开时的原文作为并发校验基准，冲突时保留草稿并提示重新打开文件。记忆新增入口浮于 tab 栏上方，编辑页由根路由覆盖 tab。

### [ADR-024] Agent 单行实时预览与日志边界

- **背景**：固定“思考中”与跳动圆点无法表明 Agent 是否持续运行；流状态进入 Riverpod 日志会暴露推理与回复片段。
- **决策**：仅将推理和回复流的最新逻辑行作为有界临时状态展示，换行与工具/步骤切换丢弃旧片段；状态气泡用纯文本横向尾随视图与连续轻动效，同阶段 token 更新不重启动画。最终完整答复仍只在回合成功后入库。应用层 Riverpod 观察器排除 `assistantControllerProvider`，手写的回合和工具元数据日志继续保留。
- **影响**：实时片段只存在于当前 UI 状态，不写入消息库或 Talker；新增 Agent 状态字段时须保持日志过滤测试。

### [ADR-025] 已发送消息的时间线入场动效

- **背景**：发送成功后气泡立即出现在倒序列表中，缺少从输入区进入时间线的连续反馈。
- **决策**：Composer 仅在持久化成功后发布新消息 ID；聊天列表只给该 ID 的行加 360ms 高度展开、右下方上滑、淡入与轻微回弹，完成后移除动画包装。倒序列表以消息 ID 和日期为稳定 key，发送时滚至最新消息。动效参数集中在 `AppMotion`。
- **影响**：首次欢迎消息切换、快速连发及图片消息沿用同一入场路径；历史消息与 AI 回复不重播。新行局部隔离重绘，列表项不增加玻璃层。

### [ADR-026] 通用主题与语言偏好

- **背景**：应用只能跟随系统明暗模式和设备语言，用户无法在设置页固定主题或语言。
- **决策**：通用偏好独立保存于 `config/ui_preferences.json`，先写临时文件再原子替换；主题默认为系统，语言在首次选择前跟随设备。启动前读取并应用偏好，运行时由 Riverpod 控制器在保存成功后更新 `ThemeMode` 与 Slang locale。“通用”作为根导航二级页覆盖 tab；主题和语言复用模型/历史轮数的 bottom sheet picker。
- **影响**：清除所有数据时同时重置偏好与当前界面；AI 设置仓库只删除自己的配置文件和临时文件，避免部分重置时误删通用偏好。存储统计仍将两类配置归入 `config`。

### [ADR-027] 各 Tab 分支独立保留底部避让

- **背景**：聊天输入 Dock 比普通 Tab 容器高；共享测量值在切换 Tab 时被覆盖，返回聊天的首帧列表底部 padding 从 246dp 暂降为 130dp，随后再次布局，造成消息气泡弹跳。
- **决策**：Shell 分别缓存聊天 Dock 与普通 Tab Dock 的实测高度，并为 IndexedStack 的每个分支提供对应的 ShellScope；聊天输入增长时仍按实测高度更新。
- **影响**：隐藏的聊天列表不再消费其他分支的 Dock 高度；切回聊天的首帧与稳定帧保持同一消息位置。

### [ADR-028] 空状态使用纯文本占位

- **背景**：通用空状态和零散无内容页面使用玻璃卡片、图标与大字，干扰页面层级；搜索页未输入与无结果的提示不够贴切。
- **决策**：共享 EmptyState 只渲染内容区域居中的小字号弱化色文本，不绘制图标或玻璃背景；错误操作独立置于文本下方。服务商无模型与 404 也移除占位卡片。搜索未输入显示“搜索你的碎碎念”，无结果显示“没有搜索到消息”，英文保持对应语义。
- **影响**：新增空状态沿用同一文本组件；图片预览在深色画布上使用深色主题的浅色文字 Token 保持可读性。聊天首页的欢迎气泡属于正常对话内容，不受空状态规范影响。

### [ADR-029] 思考 Markdown 窗口与最终回复延迟展示

- **背景**：单行纯文本思考预览无法显示模型的 Markdown 结构；最终回复逐字预览使气泡频繁重排。
- **决策**：思考状态保留当前步骤的累积 Markdown，超过 8192 UTF-16 单元时保留安全的末尾 4096 单元并开启新串流段；`StreamMarkdown` 在最多三行的窗口内增量渲染，内容尺寸变化后平滑滚到底部，上下边缘使用透明度渐隐。回复串流仅切换为“正在输入”及三个错峰跳动的点，完整回复成功结束后才写入消息并一次渲染。常规 Markdown 六级标题统一为正文加 1dp、半粗；思考标题与正文同字号、半粗。
- **影响**：替代 ADR-024 的单行预览约定。实时思考只留在受日志过滤的临时状态；步骤切换必须重置 Markdown 流，失败或取消时不发布部分回复。

### [ADR-030] Chat 固定控件的玻璃等级

- **背景**：Chat 顶部操作按钮和底部 AI 开关需要更明显的玻璃层次；头像背景与输入附件按钮保持较低开销。
- **决策**：设置、搜索和 AI 开关使用 `GlassQuality.premium`；顶部头像背景与附件按钮继续使用 `GlassQuality.standard`。
- **影响**：固定区域最多保留这三个 premium 控件，避免把高开销玻璃扩散到列表项或整块输入区域；相关 Widget 测试锁定等级分配。

### [ADR-037] Agent 思考与工具状态的 pending 动效

- **背景**：思考内容与工具调用会持续一段时间，仅靠滚动文本或静态标签不易感知任务仍在运行。
- **决策**：思考和工具状态统一显示 hook 驱动的错峰跳动点；思考 Markdown 单独使用 14sp、1.4 行高及降低透明度的主题前景色，普通 AI 回复样式不变。
- **影响**：动画生命周期随 Widget 自动结束，不使用会在测试后遗留 Timer 的循环动画；新增进行中状态沿用共享 pending 指示器。

### [ADR-038] AI 状态卡片与输入区动效契约

- **背景**：AI 思考、工具调用和最终回复的状态切换缺少连续反馈；AI 模式与普通输入状态区分度不足，键盘态附件按钮的材质也与输入框不一致。
- **决策**：思考卡片固定为“图标 + 状态”与最多三行滚动 Markdown 两行结构；pending 表面使用一次性横向高光脉冲，有思考文本时隐藏右侧跳动点。工具、思考和最终输入状态统一使用 560ms 淡入并轻微上移的切换。AI 回复持久化成功后发布一次性消息 ID，时间线仅为该 ID 播放底部滑入动画。AI 模式通过低开销流彩边框标记输入区、Tab dock 和 AI 开关；键盘态附件按钮复用输入框 blur 与 tint，并由同一 `TextFieldTapRegion` 接管点击。
- **影响**：历史消息不会重复播放入场动画；固定控件只保留边框动画，不增加列表项玻璃层；标准页面顶部 button/title 统一使用 48dp toolbar 基线并写入 UI 规范。

### [ADR-039] 服务商配置控件的玻璃质量预算

- **背景**：服务商配置页同时包含格式选择、模型能力开关、思考等级和顶部操作按钮；这些交互控件在高版本玻璃主题下若继承 premium，会在表单滚动和状态切换时叠加高成本渲染。
- **决策**：服务商配置页内的 `GlassSegmentedControl`、`GlassSwitch` 和 `GlassIconButton` 全部显式使用 `GlassQuality.standard`；外层卡片与模型分组继续使用 standard liquid surface，单个模型状态仍由局部 Hook 状态驱动。
- **影响**：该页面不再依赖主题对交互控件的隐式质量回退；新增服务商页内玻璃控件必须显式选择 standard 或更低质量，并通过 Widget 测试锁定质量预算。

### [ADR-040] Vercel AI Gateway 推理摘要自动配置

- **背景**：Vercel AI Gateway 使用 OpenAI 兼容接口转发多个上游模型；仅设置 SDK 通用 reasoning 等级不足以要求 GPT、Gemini、Claude 或 DeepSeek 返回可展示的 reasoning 摘要，而且不同上游的参数嵌套位置不同。
- **决策**：当服务商 `baseUrl` 的主机严格为 `ai-gateway.vercel.sh`、模型启用思考能力且接口不是 Anthropic Messages 时，由纯 Dart 配置器按模型 ID 生成 `ProviderOptions`。GPT Responses 使用 `openai.reasoning.{effort,summary:auto}`，Chat Completions 使用 `openai.reasoning_summary`；Gemini 将 `thinkingConfig` 放入 `openai.providerOptions.google` 与 `vertex`；Claude 固定预算或 adaptive thinking、DeepSeek 使用各自的 `openai` reasoning 结构。请求统一通过 `ai_sdk_dart 3.1.0` 的 `streamText(providerOptions:)` 传入，已有 reasoning delta 事件链路负责展示摘要。
- **影响**：普通 OpenAI URL、未启用思考、未知模型和 Messages 服务商不会注入 Gateway 参数；新增模型供应商映射必须补充配置器单测与 SDK 请求契约测试。Gateway 的真实可用性仍取决于上游模型和密钥，配置器只负责生成协议参数。

### [ADR-041] 弹层操作按钮与自建组件库

- **背景**：自定义 Dialog 和设置 Sheet 中的确认、取消、保存、删除操作使用了多种 Material 按钮，圆角、触控高度与边框对比度不一致；共享组件缺少集中预览入口。
- **决策**：`AppActionButton` 与 `AppActionIconButton` 统一承载弹层和表单 action，提供 primary、secondary、destructive 主题变体，采用胶囊圆角、48dp 最小触控区和主题派生的低对比度纯色描边。所有共享 UI 原子组件在“我的 > 开发工具 > 组件库 UI”提供真实组件预览。
- **影响**：Dialog / Sheet 中不再直接构造 Material action button；新增共享组件需要补充预览与同级 Widget 测试，并覆盖适用的明暗主题和语义变体。

### [ADR-046] 提交前统一格式化 Dart 代码

- **背景**：提交前若只格式化局部文件，未格式化的 Dart 代码可能进入版本库，导致代码风格和审查结果不一致。
- **决策**：每次 `git commit` 前必须在仓库根目录使用本地工具链执行 `.\\tools\\flutter\\bin\\dart.bat format .`，覆盖项目全部 Dart 代码，并在提交前检查格式化产生的 diff。
- **影响**：后续修改或代码生成完成后若再次产生 Dart 变更，必须重新执行全量格式化；格式化失败时不得提交。

### [ADR-047] Asset kit 品牌与状态插画

- **背景**：用户要求使用已有 asset-kit 统一应用 Logo、头像及状态页；本次明确需求替代 ADR-028 对这些页面仅用纯文本的约定。
- **决策**：原始素材保留在 docs/design，prepare_brand_assets.dart 生成按显示尺寸缩小的透明 PNG、各平台图标及 Android/iOS 启动素材。AppArtwork 通过 FlutterGen 类型化引用、固定布局与按 DPR 限制解码；EmptyState 按可用高度缩放插画并允许滚动。欢迎页保留三条临时气泡，错误消息的行内操作保持原交互。
- **影响**：Android/iOS 使用同一小狗品牌与明暗启动底色，未新增权限；空状态与真实内容共用主题文本，组件库展示全部素材。修改源素材后需重新运行生成脚本。

### [ADR-048] Overlay 默认正文样式

- **背景**：GlassToast.show 创建独立 OverlayEntry，只捕获玻璃及 Cupertino 主题；文本局部样式继承 MaterialApp 的黄色双下划线回退值。
- **决策**：在 MaterialApp.builder 中给 Navigator 及其 Overlay 提供主题 bodyMedium DefaultTextStyle，明确 decoration:none；保留 Liquid Glass Toast 的位置、交互、动画与自动关闭。
- **影响**：所有现有 Toast 调用直接获修复，无需修改依赖缓存；真实应用测试覆盖全部 Toast 类型和明暗主题的最终 RichText 样式及退场。

### [ADR-049] 欢迎小狗锚定输入框

- **背景**：聊天顶部已有用户头像，再叠欢迎插画会重复视觉焦点；默认头像缺少可读的实心背景。
- **决策**：默认头像以当前 bubbleOther 不透明主题色绘制圆形底板，图像保持 contain。欢迎插画移入 Composer 的 Stack，在输入玻璃之前绘制，底部 30% 与输入框重叠，双手位于上沿之外；居于输入区偏左，避开右侧 AI 开关。键盘聚焦态缩小，按输入实际左右边界定位；附件和已有消息时隐藏。
- **影响**：Shell 对整个 Composer 实测高度，消息底部自动避让；失焦时插画与 Tab 同步恢复，避免键盘 inset 归零后的第二次尺寸变化。测试覆盖明暗、280/390dp、键盘及首次发送，截图检查手部与玻璃遮挡关系。

### [ADR-050] Agent 资料与用户称呼分离

- **背景**：聊天与“我的”顶部应代表 Agent，资料页同时配置用户希望被如何称呼；旧版记录已有用户昵称和头像。
- **决策**：保留 UserProfile/ProfileEntity 的 nickname、avatar 及 ObjectBox UID，追加 agentName、agentAvatar。旧昵称继续用于 user.md 状态及提示词中的用户称呼，旧头像保留但不作为 Agent 展示。Agent 未自定义名字时存空值，以 Slang 显示中文“小懒”/英文“Dozy”，提示词通过注入的默认名字获取同一值。资料表单支持独立用户称呼，Agent 名字必填且两者最多 40 字符。
- **影响**：预设使用稳定 preset: 标识映射本地生成素材，工作/娱乐等七种头像统一保留实色圆形底板；底部选择器末尾才提供圆形相册入口。选择只更新草稿，保存后生效，关闭或相册取消保留原值。改用预设时只删除仓库自有且不再被资料引用的头像文件。默认引导迁移只替换受控首行，保留私人记忆正文。

### [ADR-051] 小懒应用名称与启动图标渐变

- **背景**：应用对外名称改为“小懒”，图标需要与蓝耳小狗协调的蓝到白纵向背景。
- **决策**：中英文应用标题和各平台可见名称统一为“小懒”；保留 applicationId、bundle identifier、Dart 包名和存储路径以延续现有安装数据。图标生成脚本以 #8CB9EE → #FFFFFF 的逐行线性插值生成背景；Android 自适应图标独立背景层与安全区前景组合，其他平台输出合成图标。
- **影响**：Android/iOS 同步品牌更新，不新增权限。发布保持 0.3.0+3 并使用同一签名，通过 --split-per-abi 构建 arm64 包；检查包内名称、ABI 和签名后交付。

### [ADR-052] 输入区键盘态共享过渡进度

- **背景**：插画尺寸直接切换；Tab 的 AnimatedSize 在收拢开始时就移除内容，无法看到退出动画。
- **决策**：键盘可见且输入聚焦共同驱动 280ms easeInOutCubic 的可打断进度；同一进度同步控制欢迎插画的尺寸、横向位置和顶部占位，以及 Tab 的高度裁切/透明度、附件入口宽度和输入内边距。Tab 退场完成后再移除，过渡期间不接受点击和读屏焦点。插画按完整尺寸固定解码缓存，避免逐帧重新解码。
- **影响**：保留双手露在输入框上方的 30% 叠放关系，预留最大插画高度用于小屏多行上界；失焦即恢复 Tab，快速反向从当前进度继续。减少动态效果时直接使用最终布局，AI 文本也跳过零时长 AnimatedSize，避免布局阶段自触发。
