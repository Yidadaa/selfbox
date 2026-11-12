# 错误账本 (Mistakes Ledger)

> 格式：`- [日期] [领域] 现象 -> 根因 -> 铁律`。只记高信息熵条目。

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
