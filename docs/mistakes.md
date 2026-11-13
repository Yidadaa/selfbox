# 错误账本 (Mistakes Ledger)

> 格式：`- [日期] [领域] 现象 -> 根因 -> 铁律`。只记高信息熵条目。

- [2026-11-13] [ScreenshotFixture] 独立截图夹具找不到 addTearDown -> 测试工具不通过其他夹具文件隐式导出 -> 使用测试生命周期 API 的文件显式导入 flutter_test。
- [2026-11-13] [InlineAction] 大字行内按钮重复放大、纯按钮行多出行距 -> WidgetSpan 自动缩放且占位行使用独立字体指标 -> 内部 Text 禁用重复缩放，段落固定正文 StrutStyle，以真实高度和字母基线测试。
- [2026-11-13] [Lint] FontFeature、RenderBox 新增独立导入后触发冗余导入 -> material.dart 已导出这些符号 -> 直接使用现有 Flutter 导入，并保持静态分析零问题。
- [2026-11-13] [ToastTest] 底部保存按钮重试被 Toast 遮挡 -> 推进自动关闭计时后退场动画尚未完成 -> 时间推进后继续 pumpAndSettle，确认覆盖层已退出再点击底部动作。
- [2026-11-13] [Freezed] 设置迁移改用块体 fromJson 后丢失 JSON 生成方法 -> Freezed 依赖箭头式 fromJson 识别序列化入口 -> 保留生成工厂，字段归一化使用 JsonKey 转换器。
- [2026-11-13] [Slang] 带变量的新文案生成成普通字符串 -> 忽略项目 `string_interpolation: braces` 配置而写成 `$value` -> 新文案变量统一使用 `{value}`，生成后检查调用签名。
- [2026-11-13] [SliderTest] 点击轨道后百分比不变 -> GlassSlider 仅通过水平拖动更新数值，点击只触发按压反馈 -> 交互测试使用真实拖动验证数值与实时预算。
- [2026-11-13] [PowerShell] 测试拆分脚本因 `_Env` / `_env` 重复键解析失败 -> PowerShell Hashtable 键不区分大小写 -> 大小写敏感的 Dart 符号重命名使用有序字符串对和带单词边界的 .NET 正则。
- [2026-11-13] [SliderSemantics] 自定义百分比语义触发 increase 断言 -> 带 value 的可调节点还必须声明 increasedValue / decreasedValue -> 当前值、增减后的值和动作统一按实际百分比生成。
- [2026-11-13] [SemanticsTest] 全量测试报告额外 SemanticsHandle 未释放 -> testWidgets 已启用语义，addTearDown 晚于该句柄门禁 -> 直接使用现有语义树；额外句柄须在测试体内释放。
- [2026-11-13] [MemorySheet] 280dp 大字体英文标题被省略 -> 标题与两个动作争用一行宽度且固定两行 -> 窄屏标题与动作分行，允许标题按字体度量完整换行，测试与真实字体截图共同验收。
- [2026-11-13] [TokenBudget] 统一按字符串长度除三会低估中文历史 -> 中文与 ASCII 共用同一字符成本 -> 按 Unicode 标量分别估算 ASCII、BMP 非 ASCII 与增补字符，端到端预算用例必须包含长中文消息。

- [2026-11-13] [AgentTransition] 工具卡先出现在思考卡右侧再向左跳 -> AnimatedSwitcher 默认居中叠放宽度不同的前后卡片，旧卡移除后重新取宽 -> 状态切换的 Stack 与 AnimatedSize 统一左下锚点，逐帧验证全部存活表面的左坐标。
- [2026-11-13] [ReplyEntrance] 最终 AI 回答从右侧漂入 -> 复用了用户发送的横向位移与右下缩放锚点 -> AI 入场只保留纵向位移并以左下缩放，测试实际消息表面而非仅检查动画参数。
- [2026-11-13] [ToolLabel] 280dp 英文工具状态横向溢出 -> 工具标签未参与 Row 的宽度约束 -> 标签使用 Flexible、单行省略，窄屏下保留图标和 pending 指示器。
- [2026-11-13] [Lint] 时间线拆出消息行后留下数据层未用 import -> 依赖随组件职责迁移但旧导入未删除 -> 拆文件时同步清理导入，再跑全量分析。

- [2026-11-13] [MarkdownList] 二级缩进过大且四级在手机气泡内溢出 -> 库在父级正文列内再次叠加 `listLevel * listIndent` -> 通过共享 list builder 按父级标记列右边缘递进，使用真实布局坐标覆盖静态与串流渲染。

- [2026-11-13] [Dialog] 删除服务商后弹窗退出动画中读取翻译报已卸载 context -> Dialog builder 捕获了页面 context，删除触发页面卸载后仍可重建 -> 打开弹窗前固定翻译等值，builder 不查询外层页面 context。
- [2026-11-12] [FlutterSDK] 首次测试调用系统 Flutter 导致 SDK 约束解析失败 -> 未优先使用仓库 SDK -> Flutter/Dart 命令统一从 `.tools/flutter/bin/` 执行。
- [2026-11-12] [ChatHeader] 资料入口把头像和昵称横向排列且分离 -> 实现时未按 ref-chat 逐项核对构图 -> 头像必须在昵称胶囊上方并与胶囊重叠，测试锁定纵向位置与中心线。

- [2026-11-12] [HeaderTest] `Pressable` 的父级语义标签 finder 未匹配 -> 子 Text 语义参与节点合并 -> widget 导航测试用稳定 key 锁定点击目标，语义测试单独断言对外标签。

- [2026-11-12] [MessageGlass] AI 消息仍呈实色卡片 -> AI 与用户文字共用 ColoredBox 背景 -> AI 表面独立使用 standard GlassContainer，不在玻璃下保留不透明衬底；明暗主题同时锁定材质、外置 footer 与长按契约。

- [2026-11-12] [Composer] 发送圆形右留白 14dp、上下 6dp -> 修正输入高度时仅去掉垂直 padding，遗留右侧 8dp -> 键盘态同时去掉右 padding，保留 48dp 热区；空 / 可发送态均测实际圆形三侧留白。

- [2026-11-12] [Keyboard] 收键盘后 Tab 延迟出现造成二次纵向跳动 -> 编辑布局只依赖 inset > 0，忽略失焦信号 -> 焦点用 hook 响应，失焦即恢复导航；实际键盘 inset 继续负责避让，测试覆盖归零前后高度与中途重新聚焦。
- [2026-11-12] [FocusTest] unfocus 后单次 pump 仍看到旧布局 -> FocusManager 在帧后微任务通知监听器 -> 先 pump 分发焦点，再 pump 绘制响应帧，不用 settle 掩盖恢复时机。

- [2026-11-12] [Composer] 键盘态附件圆钮 48dp，右侧输入面 64dp -> 输入行保留上下各 8dp padding，旧测试仅比较中心线 -> 分离态去掉额外垂直 padding，同步最大编辑高度预算；测试同时检查单行输入与圆钮顶底边和 48dp 触控热区。

- [2026-11-12] [Patch] 新增 import 落到文件尾导致编译失败 -> 无上下文的空替换块匹配到 EOF -> import 修改必须绑定已有文件头上下文。
- [2026-11-12] [MessageTest] 大字体长图文在窄屏 fixture 垂直溢出 -> 直接把可增长消息放入固定高度页面，未模拟生产滚动列表约束 -> 消息长内容测试使用可滚动父级，单独断言横向边界。

- [2026-11-12] [Placeholder] 中文输入提示低于正文约 5.6dp -> Material dense 字体使用 ideographic，Cupertino 基线叠层对齐时 RenderParagraph 固定返回 alphabetic，RenderEditable 返回所请求基线 -> 输入正文与提示统一 alphabetic；测试必须检查提示实际位置，不能只检查编辑框中心。
- [2026-11-12] [RenderTest] 直接转换 EditableText.renderObject 或在布局外调用 getDistanceToBaseline 报错 -> 外层渲染对象不是 RenderEditable，基线访问受布局阶段断言约束 -> 通过 EditableTextState.renderEditable 取编辑渲染器；诊断基线使用渲染器实际计算方法。
- [2026-11-12] [PlaceholderTest] 输入提示原文后 find.text 仍命中两个控件 -> Cupertino 用 Visibility 保留提示布局，finder 也匹配 EditableText 正文 -> 输入态断言 controller 内容与几何，清空态断言提示实际位置。

- [2026-11-12] [RoutingTest] 二级页改为根 Navigator 后全量测试仍断言文件详情显示 Tab -> 旧契约未同步更新 -> 路由行为调整时同步检查跨 Feature 页面测试。

- [2026-11-12] [Test] `byType(Skeletonizer)` 找不到骨架组件 -> 工厂构造返回内部子类，byType 精确匹配运行时类型 -> 用 `byWidgetPredicate((widget) => widget is Skeletonizer)` 验证公开契约。
- [2026-11-12] [PowerShell] 文本替换写入字面量 `\n` 导致 Dart 解析失败 -> PowerShell 单引号不展开换行 -> 多行源码使用 apply_patch 编辑。

- [2026-11-12] [ObjectBox] 运行代码生成重置已提交的 Entity UID -> build.yaml 排除 lib/gen/** 导致 canRead(model.json) 为 false -> 只排除 lib/gen/**/*.dart，保留模型 JSON 为输入；生成后必须确认 UID diff 为空。

- [2026-11-12] [Layout] 小屏键盘 + 六行草稿 + 附件把停靠区顶到标题并挤爆空态 -> 只限制行数、未计算剩余高度 -> 输入最大高度扣除键盘/安全区/标题/附件，空态用可滚动 SliverFillRemaining。

- [2026-11-12] [DartFix] 指定 directives_ordering 的批量 fix 仍把 flutter_test 移到运行时依赖 -> 同级 lib 测试触发 pubspec 自动修复 -> 优先手动整理 import；批量 fix 后必须审查 pubspec diff。
- [2026-11-12] [Semantics] AI 胶囊添加可见标签后无法按语义名定位 -> Pressable label 与 Text 合并成重复名称 -> 已有明确语义标签的装饰性文本用 ExcludeSemantics。

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
- [2026-11-12] [Android] `Failed to find target with hash string 'android-37'` -> 插件要求 compileSdk 37，旧 AGP 不识别 `android-37.0` 包 -> 升级 AGP（9.5.1）并同步 Gradle 版本，app 的 compileSdk 设为不低于插件要求。
- [2026-11-12] [Android] release 构建提示缺少 `CupertinoIcons` 字体 -> 依赖库用了 Cupertino 图标但项目未引入 -> 添加 `cupertino_icons` 依赖，否则图标为方块。
- [2026-11-12] [MuMu] `adb connect 127.0.0.1:16384/7555` 被拒 -> Hyper-V 模式下 adb 监听在模拟器自身 IP -> 用 `MuMuManager.exe info -v all` 查 `adb_host_ip:adb_port` 再连接。
- [2026-11-12] [Android] release 包 AI 请求全部失败 -> Flutter 模板只在 debug/profile manifest 声明 `INTERNET` -> 主 manifest 必须显式声明 `INTERNET`。
- [2026-11-12] [Android] 只按 `android-x64` 构建的 APK 在 arm64 真机必崩 -> 插件自带各 ABI 的 .so，出现不完整的 `arm64-v8a` 目录，系统据此选择 arm64 却找不到 libflutter.so -> 按目标设备 ABI 构建，或不加 `--target-platform` 打全量包。
- [2026-11-12] [Xiaomi] `adb install` 报 `INSTALL_FAILED_USER_RESTRICTED` -> HyperOS 默认禁止 USB 安装 -> 开发者选项开启「USB 安装」，安装时在手机上点允许。
- [2026-11-12] [Keyboard] 真机弹出键盘后输入框跳到屏幕顶部 -> 页面 `GlassScaffold` 默认按键盘缩小 body，输入框又手动上移键盘高度，重复计算 -> 自行跟随键盘的页面传 `resizeToAvoidBottomInset: false`，并用 `tester.view.viewInsets` 写测试锁定「输入框底边 = 键盘顶边 - 间距」。
- [2026-11-12] [Dart] 同级测试混用相对与 package 导入后同名接口不可赋值 -> 两种 URI 创建不同库身份 -> 测试被测模块统一使用 package:selfbox 导入。
- [2026-11-12] [DartFix] 定向 dart fix 仍将 flutter_test 移至 dependencies:any -> pubspec 自动修复将 lib 内测试视作运行时依赖 -> 检查并恢复 flutter_test 为 sdk dev_dependency，禁止对整个工作区盲目 apply。
- [2026-11-12] [LiquidGlass] GlassButton.custom 内未设 TextStyle 导致红色测试字形与裁切 -> 未继承 Material 正文主题 -> 显式使用主题字体、48dp 高度和 capsule shape，截图验收。
- [2026-11-12] [Riverpod] Widget fixture 重复 override 同一 provider 报错 -> 默认替身和 overrides 同时注入 -> 可替换仓库作为 fixture 的显式可选参数传入。
- [2026-11-12] [WidgetTest] find.byType(Skeletonizer) 找不到骨架 -> 工厂返回私有实现类型 -> 用 widget is Skeletonizer 与 enabled 判定实际行为。
- [2026-11-12] [Focus] 点击输入框旁的 AI 按钮使键盘收起 -> CupertinoTextField 默认将按钮判为 outside tap 并 unfocus -> 用 TextFieldTapRegion 将相邻输入控制纳入同一点击组，保留页面空白处收键盘手势。
- [2026-11-12] [Composer] 自定义输入行后键盘态附件按钮低 8dp、消息点击不收键盘 -> 外层 Row 按底边对齐且原生文本框未显式处理 outside tap -> 输入与附件按中心线排布，onTapOutside 主动取消焦点。
- [2026-11-12] [AgentLog] SDK 的 ToolResult 流事件把工具 Map 结果序列化为文本，业务错误被误记为成功 -> 在 AgentTools 执行包装处检查结构化结果的 error 键，仅把状态写入 Talker。
- [2026-11-12] [Layout] 输入区单行截图出现六行高空白 -> CupertinoTextField 设置 maxLines:6 但省略 minLines 时按六行占位，外层 Flexible 又放大空白 -> 明确 minLines:1、只约束编辑文本高度，并测单行输入面高度。
- [2026-11-12] [Chat] 顶栏下方出现生硬的消息滚动边界 -> 把顶部避让加在列表外层，裁掉了玻璃按钮背后的滚动内容 -> 滚动视口保持全屏，仅给内容设置顶部内边距。
- [2026-11-12] [DialogTest] 窄屏大字测试找不到清除入口且背景页溢出 -> 整页缩放混淆了弹层与页面的布局错误 -> Dialog 单独渲染测试，内部可滚动；集成测试保留正常字号。
- [2026-11-13] [DarkMode] AI/图片卡片、Dialog 与 Picker Sheet 深色模式仍为白色 -> 业务组件固定浅色值，顶部过渡还回退到 Cupertino 背景色 -> 非玻璃表面统一从明暗主题取色，GlassScaffold 显式接收画布过渡色。
- [2026-11-13] [SettingsSurface] 服务商卡片浅色模式变纯白且设置列表圆角不统一 -> solid 表面默认不透明，glass 分组默认仅 12dp 圆角 -> 设置流程使用默认 glass、standard 与统一圆角 Token。
- [2026-11-13] [Lint] 显式写 `GlassSurfaceStyle.glass` 触发冗余参数告警 -> 该值是卡片默认材质 -> 省略参数，并用 Widget 测试锁定 glass 渲染路径。
- [2026-11-13] [AgentPrompt] 新增用户上下文后编译找不到命名参数 -> 把姓名与语言误传给 `AgentTools` -> 用户上下文只传给 `buildAgentInstructions`，先运行局部分析再测 UI。
- [2026-11-13] [MarkdownEditor] 编辑页在 GlassScaffold 内崩溃找不到 Material -> `SmoothMarkdownEditor` 的源码输入框内部使用 Material TextField -> 用透明 Material 提供组件上下文。
- [2026-11-13] [ChatTest] 欢迎页改用反向 ListView 后旧测试仍查找 CustomScrollView -> 测试需跟随实际滚动结构并断言视口仍从顶部开始。
- [2026-11-13] [MemoryEditor] 中文源码显示方块 -> Markdown 编辑器默认 monospace 缺少中文字形 -> 源码模式显式传入主题正文字体，并用截图检查中英文。
- [2026-11-13] [MemoryButton] 自定义玻璃按钮中文显示方块 -> 子 Text 未设置主题样式 -> `GlassButton.custom` 的文本须显式取主题 TextStyle。
- [2026-11-13] [MemoryConflict] AI 更新记忆后旧草稿覆盖新内容 -> 编辑页重建时以最新文件原文校验旧草稿 -> 保存校验必须固定为打开编辑页时的原文。
- [2026-11-13] [AgentLog] 实时片段加入 Riverpod 状态会进入 Talker -> 全局观察器默认记录完整状态值 -> Agent 状态 Provider 必须从通用日志中过滤，另以测试锁定正文不入日志。
- [2026-11-13] [ProviderHeaders] 编辑服务商 Headers 用例在浅色主题断言深色 Sheet 背景 -> 测试期望与实际亮度不一致 -> Bottom Sheet 颜色断言必须跟随测试显式设置的主题亮度。
- [2026-11-13] [Lint] 合并状态动画后留下未使用的私有组件 `key` 参数 -> 参数只服务于旧控件结构 -> 改动组件职责后运行静态分析并移除无用构造参数。
- [2026-11-13] [Lint] 模型默认值测试显式传入默认参数触发冗余参数告警 -> 测试应直接断言默认构造后的字段值。
- [2026-11-13] [WidgetTest] 首条发送后立即查找气泡失败 -> 消息流在零时长 pump 后才交付下一帧 -> 推进一帧再断言入场组件。
- [2026-11-13] [WidgetTest] 图片发送测试挂起 -> 选图流程写真实文件，fake-async 不推进 I/O -> 用 `tester.runAsync` 执行选图。
- [2026-11-13] [Flutter] `SizeTransition.axisAlignment` 静态分析报警 -> SDK 已弃用该参数 -> 用 `alignment: Alignment.bottomCenter` 保留底部锚点。
- [2026-11-13] [fpdart] 测试替身的 `TaskEither.fromEither(switch)` 推断出 `dynamic` 失败类型 -> 分支泛型未被上下文锁定 -> 直接返回明确的 `TaskEither<AppFailure, Unit>`。
- [2026-11-13] [SlangTest] 清除语言偏好的单测报 WidgetsBinding 未初始化 -> 恢复设备语言会读取平台 locale -> 独立 Provider 测试先初始化 `TestWidgetsFlutterBinding`。
- [2026-11-13] [SettingsReset] 清除 AI 配置误删通用偏好 -> 旧实现递归删除整个 `config` 目录 -> 仓库只删除自己拥有的配置文件，并由总重置流程清除通用偏好。
- [2026-11-13] [SettingsReset] 缩小配置删除范围后 `.tmp` 仍残留 -> 原子写入的临时文件也属于同一仓库 -> `clearAll` 同时删除正式文件和对应 `.tmp`。
- [2026-11-13] [ChatTab] 切回聊天首帧消息从 Tab 下方弹起 -> Shell 共用 Dock 高度被较矮的普通 Tab 覆盖，测量回调下一帧才恢复 -> 各分支独立缓存并提供底部避让，逐帧断言气泡位置。
- [2026-11-13] [EmptyStateTest] 纯文本占位改动后旧测试仍要求图标和空玻璃分组 -> 测试锁定了被替换的视觉结构 -> 同步迁移断言，并用有内容的数据继续验证真实分组样式。
- [2026-11-13] [ImageTest] 缺失本地图片的错误占位在 widget 测试中未出现 -> `Image.file` 的磁盘失败由异步图片流回调触发 -> 纯 widget 布局测试使用无效相对路径直接验证不可用图片分支。
- [2026-11-13] [TopFade] 暗色模式顶部渐隐偶尔保持白色 -> `GlassScrollEdgeEffect` 优先绘制异步捕获的背景纹理，`backgroundColor` 只控制回退渐变 -> 共享页面关闭该顶部效果，直接从当前主题画布色绘制渐隐并测试运行中切换。
- [2026-11-13] [WidgetTest] 小屏键盘用例点击不到添加模型按钮 -> 缩小视口后按钮落在页面可见区域外 -> 先打开待测面板再模拟小屏与键盘，单独断言面板避让和溢出。
- [2026-11-13] [Lint] 模型探测新增重复 SDK 导入与非 const 的测试结果 -> `ai_sdk_dart` 已导出所需 provider 类型，`Right(unit)` 可常量化 -> 依赖入口只导入一次并在提交前跑完整静态分析。
- [2026-11-13] [StreamMarkdownTest] 首帧查找流式正文失败 -> 组件节流并在后续帧重绘 -> Widget 测试推进节流帧后检查渲染结果。
- [2026-11-13] [ThinkingScroll] 思考 Markdown 增长后仍停在顶部 -> 仅监听滚动指标未覆盖内层内容重排 -> 用 `SizeChangedLayoutNotifier` 在内容变高后滚到末尾。
- [2026-11-13] [Screenshot] 思考截图拍到滚动中途的截断文字 -> 截图夹具只推进了动效起始帧 -> 捕获前继续推进滚动完成帧。
- [2026-11-13] [Lint] `MarkdownConfig(enableHtml: false)` 触发冗余默认参数告警 -> 库默认即禁用 HTML -> 保持默认配置并用静态分析守门。
- [2026-11-13] [FlutterTest] 并行启动多个 Flutter 测试命令导致共享 `build/test_cache` 的 dill 文件冲突 -> 测试编译器写入同一缓存 -> Flutter 测试命令串行运行。
- [2026-11-13] [MediaStore] 图片优化接入后旧 Controller 测试仍用随机字节并断言原始扩展名 -> 解码失败会按设计拒绝损坏图片且统一输出 JPEG -> 图片夹具必须使用可解码样本，并断言压缩后的 JPEG 属性。
- [2026-11-13] [WidgetTest] 新增循环 pending 动效后 `pumpPage` 的 `pumpAndSettle` 超时 -> 夹具默认等待动画静止 -> 无限循环状态测试使用 `settle: false` 并固定推进帧。
- [2026-11-13] [GlassPerformance] 服务商配置页交互控件继承主题的 premium 质量导致滚动与切换成本叠加 -> 交互式玻璃控件必须显式使用 `GlassQuality.standard`，并以 Widget 测试锁定页面预算。
- [2026-11-13] [Toolchain] 全局 SDK 导致求解失败，递归查找又误判项目 SDK 缺失 -> 搜索未命中不代表路径不存在 -> 先直接验证并使用 `.tools/flutter/bin/flutter.bat`，不要用全局 SDK 格式化或分析项目。
- [2026-11-13] [AiChrome] 彩边围住开关和留白且键盘态错位 -> Shell 包裹整个 Composer Column，RRect 也不等于玻璃 superellipse -> 背景/浅色细边只绑定输入玻璃的实际 bounds，并复用同一 LiquidShape。
- [2026-11-13] [AiGlow] 动画中珊瑚色移出后只剩冷色，显得塑料 -> 暖色中心摆幅超过自身边缘距离且颜色叠加太浓 -> 暖色锚点固定在左侧第三分区、降低透明度，并对紧凑/完整高度扫描整个循环相位。
- [2026-11-13] [Screenshot] 组件库新预览文字显示为红色裁切块 -> 裸 Text 未继承正文主题 -> 自绘控制内的 Text 必须显式取主题 TextStyle，生成截图后逐张验收。
- [2026-11-13] [SheetActions] 320dp 模型选择器标题行右侧溢出 20dp -> 两个按内容取宽的文字动作挤满整行 -> 关闭使用共享图标按钮，确认动作受 Flexible 宽度约束，标题单行截断并验证操作区边界。
- [2026-11-13] [ToastTypography] Toast 文本出现黄色双下划线 -> Overlay 在页面 Material 之外，局部 TextStyle 继承 MaterialApp 错误样式 -> Navigator 上方显式提供主题 DefaultTextStyle，并断言最终 RichText 样式。
- [2026-11-13] [ArtworkTest] 插画尺寸测试得到全屏大小，搜索路由找不到素材 -> 根 home 强约束与误用路由字面量 -> 独立插画测试用 Center 解除紧约束，页面测试核对强类型路由。
- [2026-11-13] [BrandLint] 插画批量接入后 import 顺序和单行条件触发 lint -> 自动插入未遵守现有排序和大括号规范 -> 格式化之外仍需运行 analyzer 并修正静态检查。
- [2026-11-13] [DartFix] dart fix 把同级测试的 flutter_test 移成 hosted any，导致求解失败 -> 自动 dependency 修复不适配本项目 lib 内测试约定 -> 审查 pubspec diff，flutter_test 必须保留 dev_dependencies 的 sdk:flutter。
- [2026-11-13] [IllustratedState] Chat 错误态触发布局异常 -> SliverFillRemaining 无滚动体会查询 LayoutBuilder 的 intrinsic 尺寸 -> 可自适应滚动的错误态直接在约束后的 Padding 内布局，避免 intrinsic 依赖；无界列表内不嵌套 ScrollView。
- [2026-11-13] [ScreenshotTheme] 截图夹具报 Provider 重复覆盖 -> pumpApp 已注入初始偏好 -> 明暗截图通过测试平台亮度切换，不重复覆盖 initialAppPreferencesProvider。
- [2026-11-14] [WelcomeMascot] 键盘完全收起时输入 Dock 再次变高 -> 插画尺寸仅依赖 inset，晚于输入框失焦恢复 -> 插画与输入框共同依据 keyboardOpen && focusNode.hasFocus 切换布局。
- [2026-11-14] [Arm64APK] 仅指定 target-platform android-arm64 的 APK 仍含其他 ABI -> AAR 依赖的 JNI 文件未被该参数过滤 -> arm64 交付必须同时使用 --split-per-abi，并用 aapt 核验所有 lib 路径。
- [2026-11-14] [AgentProfileTest] push 路由测试仍读到 /chat、模型提示词断言只读到历史 -> imperative 路由不一定改 RouteInformation，SDK 系统提示词与 messages 分离 -> 页面跳转断言目标 Widget；系统身份断言 prompt.system。
- [2026-11-14] [AvatarGrid] 窄屏大字英文 Working/Sleeping 被拆成两行 -> 固定三列不考虑文字缩放 -> 根据 textScaler 和最小 tile 宽度选择 2–4 列，截图验收真实字体。
- [2026-11-14] [ScriptEdit] UTF-8 Dart 被默认 GBK 读取失败，按缩进查找替换又误跨测试块 -> 文件编码和结构边界未显式固定 -> 脚本读写指定 UTF-8，用完整语法片段替换并检查 diff；formatter 失败不得继续测试或提交。
- [2026-11-14] [SlangTest] locale.build().app 编译失败 -> 当前生成接口 build 返回 Future -> 多语言独立实例测试 await locale.build() 后读取字段。
