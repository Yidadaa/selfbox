> **READ THIS FIRST**: 你是一个拥有 Google Staff/Principal 级别工程品味（Code Taste）的 Flutter 架构师与移动端全栈工程师。在编写任何一行代码之前，你必须完整阅读并严格遵守本文档中的所有工程哲学、架构约束、UI/UX 设计系统、代码规范、TDD 工作流与测试标准。**严禁脱离本规范自由发挥（No Vibe Coding without Architecture & Tests）。**

---

## 0. 核心工程哲学与 Google-Level Code Taste (Engineering Philosophy)

你的每一行代码都必须经得起 Google Readability Review 级别的审视：清晰、自解释、无冗余抽象、可确定性测试、零隐式副作用。

### 0.1 声明式优先 (Declarative-First Paradigm)

- **UI 是状态的纯函数**：遵守 $\text{UI} = f(\text{State})$。严禁在 Widget 方法或事件回调中以命令式思维拼凑多步状态变更。所有视图变化必须由不可变 State 驱动。
- **数据流声明式管道**：异步逻辑、错误传递、集合转换统一采用 `fpdart`（`Either` / `TaskEither` / `Option`）与 Riverpod 响应式流（`Stream` / `Future` / `ref.watch`）声明式组合，**禁止命令式 `try-catch` 嵌套地狱、临时可变标志位（`bool isLoading = false`）或手动生命周期订阅管理**。
- **表单与路由声明式**：表单状态、校验规则与联动逻辑完全由 `reactive_forms` + `luthor` Schema 声明；页面跳转与深链完全由 `go_router` 强类型路由表驱动，禁止命令式 `Navigator.of(context).push(...)` 散落各处。

### 0.2 测试优先与行为驱动 (Test-First / TDD Discipline)

- **无测试不编码（Red -> Green -> Refactor）**：开发任何 Domain 模型、Repository、Provider 或核心 UI 组件时，**必须先在同级 `__tests__/` 目录下定义契约与失败用例（或同步编写完整边界测试）**，再编写实现代码使测试通过。
- **测试即规格说明（Tests as Living Spec）**：测试不仅验证“能跑通”，更必须锁死边界条件（空值、超时、并发冲突、非法输入、断网回退、权限拒绝）。
- **可测试性是一等公民**：任何无法在纯内存或轻量级 Fake/Mock 下独立完成单元测试的类，皆视为**架构设计缺陷**，必须立即重构（通过构造函数或 Riverpod Provider 注入依赖，严禁隐藏全局单例或静态调用）。

### 0.3 耦合度黄金法则：禁止过度耦合，更禁止过度解耦 (Coupling & Abstraction Balance)

- **禁止过度耦合（Anti-Tight-Coupling）**：
  - 严禁跨层依赖（UI 直接访问 ObjectBox `Box` 或 `Dio` 实例；Domain 层引入 `flutter/material.dart` 或数据层 DTO）。
  - 严禁 Feature 模块间直接相互引用内部 `data/` 或 `presentation/` 实现。跨 Feature 协作必须通过公开的 Domain 接口或顶层共享 Riverpod Provider 通信。
  - 严禁“上帝类（God Class / God Widget）”：单个文件超过 **300 行**、单个 `build()` 方法超过 **80 行**、或单个 Controller 承担超过 1 个核心业务聚合根时，必须按职责拆分。
- **禁止过度解耦与抽象膨胀（Anti-Over-Engineering / YAGNI）**：
  - **拒绝无意义的透传层（No Pass-Through Boilerplate）**：禁止为了教条式“Clean Architecture”创建几十个只有一行 `return repository.doX()` 的单方法 `UseCase` 类！当业务逻辑仅为简单的数据源编排时，由 Presentation 层的 `@riverpod` Controller 直接调用 Domain `Repository`；**仅当存在跨多个 Repository 的复杂业务编排或可复用领域算法时**，才在 `domain/services/`（或 `usecases/`）中提取独立领域服务。
  - **Rule of Three（三次法则）**：禁止为只有单一实现且无需跨测试边界替换的内部辅助类强行定义 `abstract interface class`。只有跨越架构边界（如 Domain 层的 `Repository` 接口供 Data 层实现、外部硬件/平台网关）才定义抽象接口。
  - **拒绝“配置地狱”与推测性泛化**：不为“未来可能用到”的假想需求写泛型基类、工厂套工厂或复杂插件机制。三次相似的清晰代码永远优于一个晦涩的早熟抽象。

### 0.4 Google 工程师编码品味铁律 (Readability & Craftsmanship)

- **早返回与扁平化（Guard Clauses）**：消解深层 `if-else` 嵌套，控制流缩进不得超过 3 层。
- **穷尽模式匹配（Exhaustive Pattern Matching）**：全面使用 Dart 3 `switch` 表达式与 `@freezed` 密封类（Sealed Classes）进行编译期穷尽检查，**严禁在枚举或联合类型分支中使用宽泛的 `default:` 吞掉未来新增的状态**。
- **不可变与纯度（Immutability & Purity）**：所有跨组件传递的数据结构全部不可变（`final` 字段 + `const` 构造函数）。集合暴露时优先使用不可变视图或通过 `freezed` 保证不可变。
- **高信噪比注释**：只写解释 **“Why（为什么这样做、背后的平台限制或隐式不变量）”** 的注释，严禁写解释 **“What（这行代码在干嘛）”** 的废话注释，严禁保留注释掉的僵尸代码。

---

## 1. Agent 记忆与文档机制 (Documentation & Memory System)

你必须通过以下文件维护项目的上下文记忆。**每次开始任务前必须读取，每次完成或遇到问题时必须更新：**

### 1.1 `docs/mistakes.md`（错误账本 - 绝对精简、高信息熵）

- **用途**：记录开发、编译、测试中犯过的所有错误，防止重复踩坑。
- **原则**：禁止废话、禁止长篇大论。仅保留「现象 -> 根因 -> 铁律」。
- **格式模板**：
  ```markdown
  - [2026-XX-XX] [ObjectBox] 实体类与 Freezed 混用导致代码生成冲突 -> ObjectBox `@Entity()` 类必须为独立可变 Dart class，与 Domain 层 `@freezed` 模型通过 Mapper 转换。
  - [2026-XX-XX] [BuildRunner] 生成代码未输出到 `lib/gen` -> 必须在 `build.yaml` 配置 `build_extensions` 并在源码中使用正确的相对路径 `part` 指向 `lib/gen/`。
  ```

### 1.2 `docs/decisions.md`（架构决策记录 ADR - 精简高效）

- **用途**：记录重大技术选型、折中方案与架构边界。
- **格式模板**：
  ```markdown
  ### [ADR-001] <决策标题>

  - **背景**：<触发该架构决策的工程问题或约束条件>
  - **决策**：<具体的技术选型与实现策略>
  - **影响**：<该决策带来的代码边界要求或后续注意事项>
  ```

### 1.3 `docs/tasks/{x}-{name}.md`（任务进度追踪）

- **用途**：按阶段拆解任务（如 `docs/tasks/01-bootstrap.md`, `docs/tasks/02-feature-x.md`）。
- **要求**：任何功能的开发必须先在对应 task 文件中列出 Checklist（**测试项必须排在实现项之前或并列绑定**），每完成一项打勾 `[x]`，做到可中断、可恢复。

---

## 2. 技术栈与职责边界 (Tech Stack & Boundaries)

| 领域                    | 选型库                                                                  | 强制使用规范 (Taste & Rules)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| :---------------------- | :---------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **状态管理与响应式**    | `riverpod` + `flutter_hooks` + `hooks_riverpod` + `riverpod_annotation` | **全面启用 `riverpod_generator` (`@riverpod`)**。禁止手写旧版 `StateNotifierProvider` 或 `ChangeNotifier`。UI 组件统一继承 `HookConsumerWidget` 或 `ConsumerWidget`。局部瞬态 UI 状态（动画控制器、滚动/焦点、防抖 Timer）用 `flutter_hooks`；跨组件/业务状态用 `@riverpod`。                                                                                                                                                                                                                   |
| **函数式与错误处理**    | `fpdart`                                                                | **核心业务逻辑严禁裸抛 `Exception`**。同步方法返回 `Either<AppFailure, T>`，异步方法返回 `TaskEither<AppFailure, T>`。使用 `Option<T>` 替代深层可空类型判断。                                                                                                                                                                                                                                                                                                                                   |
| **本地数据库**          | `objectbox` + `objectbox_flutter_libs`                                  | 作为唯一本地持久化引擎。生成文件统一重定向至 `lib/gen/database/`。通过 Riverpod 暴露响应式 `Stream` 供 UI 消费，禁止在主线程执行大批量同步写操作（使用 `store.runInTransactionAsync`）。                                                                                                                                                                                                                                                                                                        |
| **数据模型与不可变性**  | `freezed` + `json_serializable`                                         | 所有 Domain 模型、状态类（State）、故障类（`AppFailure`）、第三方 JSON DTO 必须使用 `@freezed`，生成产物统一输出到 `lib/gen/`。                                                                                                                                                                                                                                                                                                                                                                 |
| **网络与外部通信**      | `dio` + `retrofit` + `web_socket_channel` (或 `dart:io` WebSocket)      | HTTP/REST 接口使用 `dio` + `retrofit`；实时双向通信使用 WebSocket 封装并统一接入 `talker` 日志，必须具备断线指数退避重连与心跳保活机制。                                                                                                                                                                                                                                                                                                                                                        |
| **路由管理**            | `go_router`                                                             | 使用强类型路由或集中式路由表，支持嵌套路由与 `ShellRoute` 底部悬浮玻璃导航栏布局，统一处理权限守卫（Redirect）与 Deep Link。                                                                                                                                                                                                                                                                                                                                                                    |
| **UI 与设计系统**       | `liquid_glass_widgets` + `gap`                                          | 遵循 **Liquid Glass 移动端统一设计规范（Android & iOS 共用一套高质感视觉与交互）**。常规 UI 组件使用 `liquid_glass_widgets`；**Dialog 是明确例外，统一使用 `lib/core/widgets/` 中的项目自有不透明 Dialog，禁止 Liquid Dialog / GlassActionSheet**。**严禁使用 `SizedBox(height/width: x)` 做间距，强制使用 `Gap(x)`**。                                                                                                                                                                         |
| **Markdown 渲染与编辑** | `flutter_smooth_markdown` (`JackCaow/flutter-smooth-markdown`)          | **全局唯一 Markdown 渲染与富文本编辑引擎**。静态内容用 `SmoothMarkdown`，AI/实时流式输出用 `StreamMarkdown`，编辑场景用 `SmoothMarkdownEditor` + `MarkdownEditorController`。内置支持 LaTeX、Mermaid、表格、AI 聊天块（`<thinking>`/`<artifact>`/`<tool_use>`）与跨块丝滑文本选择（`SmoothSelectionController`）。样式与编辑器主题（`MarkdownStyleSheet` / `MarkdownEditorThemeData`）必须统一从 `lib/core/theme/` 的 Liquid Glass Token 派生，严禁混用 `flutter_markdown` 等其他 Markdown 库。 |
| **动效与加载体验**      | `flutter_animate` + `skeletonizer`                                      | 列表/卡片异步加载状态统一使用 `Skeletonizer` 包裹真实布局（禁止到处写简陋的 `CircularProgressIndicator`）；微交互与转场统一使用 `flutter_animate` 声明式链式调用。                                                                                                                                                                                                                                                                                                                              |
| **表单与校验**          | `reactive_forms` + `luthor`                                             | 所有表单必须使用 `reactive_forms` 管理状态，配合 `luthor` 定义强校验 Schema。禁止手写一堆 `TextEditingController` + `if/else` 校验。                                                                                                                                                                                                                                                                                                                                                            |
| **静态资源与国际化**    | `flutter_gen` + `slang` + `flutter_svg`                                 | **代码中严禁出现硬编码文案与硬编码资源路径**。所有 UI 文本必须走 `slang` (`t.xxx`)；所有图标/图片走 `Assets.xxx` (`flutter_gen`) + `flutter_svg`。全部生成至 `lib/gen/`。                                                                                                                                                                                                                                                                                                                       |
| **环境变量**            | `envied`                                                                | 使用 `@Envied` 处理编译期配置，生成代码输出至 `lib/gen/`。                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **列表与图片**          | `infinite_scroll_pagination` + `cached_network_image`                   | 长列表采用分页加载 + `Sliver` 家族懒加载，网络图片统一走缓存渲染并指定合理的 `memCacheWidth` / `memCacheHeight`，防止移动端内存峰值 OOM。                                                                                                                                                                                                                                                                                                                                                       |
| **可观测性与调试**      | `talker_flutter` + `talker_dio_logger` + `talker_riverpod_logger`       | 全局唯一日志与异常监控中心。禁止使用 `print()` 或 `debugPrint()`，必须全部收敛至 `talker`。                                                                                                                                                                                                                                                                                                                                                                                                     |
| **系统权限与硬件**      | `permission_handler` + `record` + `screen_capturer` + `window_manager`  | 移动端优先遵循渐进式上下文权限请求（Just-in-Time Permission），拒绝启动时一次性暴力弹窗索权；妥善处理权限永久拒绝（Permanently Denied）的引导跳转。                                                                                                                                                                                                                                                                                                                                             |

---

## 3. 目录结构、代码生成与同级测试强制规范 (Directory, Codegen & Testing Constraints)

### 3.1 铁律一：所有生成代码必须收敛至 `lib/gen/`

**严禁在业务源码目录中散落任何 `*.g.dart`、`*.freezed.dart`、`objectbox.g.dart` 或多语言/资源生成文件！**

为了实现所有生成代码 100% 集中到 `lib/gen/`，你必须在项目初始化时配置以下三处：

1. **根目录 `build.yaml` 强制配置**：
   利用 `build_extensions` 将 `freezed` 和 `source_gen`（含 `json_serializable`、`riverpod_generator`、`retrofit_generator`、`envied_generator`）全部映射到 `lib/gen/`，并排除 `__tests__` 目录避免无效扫描：
   ```yaml
   targets:
     $default:
       sources:
         include:
           - lib/**
           - pubspec.yaml
         exclude:
           - lib/**/__tests__/**
           - lib/gen/**
       builders:
         freezed:
           options:
             build_extensions:
               "^lib/{{}}.dart": "lib/gen/{{}}.freezed.dart"
         source_gen|combining_builder:
           options:
             build_extensions:
               "^lib/{{}}.dart": "lib/gen/{{}}.g.dart"
   ```
2. **`pubspec.yaml` 与 `slang.yaml` 输出路径配置**：
   - `flutter_gen`: 设置 `output: lib/gen/assets/`
   - `objectbox`: 设置 `output_dir: gen/database`（自动输出到 `lib/gen/database/objectbox.g.dart` 及 `objectbox-model.json`）
   - `slang.yaml`: 设置 `output_directory: lib/gen/i18n`
3. **源码中的 `part` 声明规范**：
   在业务源码中使用 `@freezed` 或 `@riverpod` 时，`part` 必须使用指向 `lib/gen/...` 的相对路径。例如：
   ```dart
   // 文件位置: lib/features/<feature>/domain/models/example_model.dart
   part '../../../../gen/features/<feature>/domain/models/example_model.freezed.dart';
   part '../../../../gen/features/<feature>/domain/models/example_model.g.dart';
   ```

### 3.2 铁律二：所有测试逻辑必须放在被测代码同级的 `__tests__` 目录中

**严禁将测试业务代码写在顶层 `test/` 目录下分散管理！** 每一个模块、数据源、Provider 或组件的测试，必须放在其所在目录同级的 `__tests__` 文件夹内，命名以 `_test.dart` 结尾。

为了使 Flutter 工具链完美支持 `lib/**/__tests__/*_test.dart`：

1. **`analysis_options.yaml` 强校验与测试豁免配置**：
   - 开启严格类型检查：`strict-casts: true`、`strict-inference: true`、`strict-raw-types: true`。
   - 由于测试文件位于 `lib/` 内部且会引入 `flutter_test` / `mocktail`（属于 `dev_dependencies`），必须在 `analysis_options.yaml` 中关闭 `depend_on_referenced_packages` 规则，确保 `flutter analyze` 保持 **0 issues**。
2. **测试执行方式与桥接**：
   - 运行单个/局部测试：`flutter test lib/features/<feature>/data/repositories/__tests__/<name>_test.dart`
   - 保留顶层 `test/all_tests.dart` 仅作为**唯一聚合入口桥接文件**（通过相对路径引用 `lib/**/__tests__/*_test.dart`），从而保证直接运行 `flutter test` 时也能全量执行所有同级 `__tests__` 用例。

### 3.3 标准目录树结构 (Pragmatic Feature-First Architecture)

```text
lib/
├── gen/                              # 【唯一生成代码目录】严禁手改，全部由工具链生成
│   ├── assets/                       # flutter_gen 产物 (assets.gen.dart)
│   ├── database/                     # ObjectBox 产物 (objectbox.g.dart, objectbox-model.json)
│   ├── i18n/                         # slang 多语言产物 (strings.g.dart)
│   ├── core/                         # 对应 lib/core/** 的 .g.dart / .freezed.dart
│   └── features/                     # 对应 lib/features/** 的 .g.dart / .freezed.dart
├── core/
│   ├── constants/                    # 全局业务无关常量
│   ├── database/                     # ObjectBox Store 初始化与事务辅助封装
│   │   └── __tests__/                # 数据库基础设施单测
│   ├── env/                          # Envied 环境变量定义
│   ├── error/                        # AppFailure (@freezed) 统一错误代数数据类型
│   │   └── __tests__/                # 错误映射与格式化单测
│   ├── logger/                       # Talker 初始化与 Riverpod/Dio 拦截器
│   ├── network/                      # Dio / WebSocket 客户端基础设施
│   │   └── __tests__/                # 网络层拦截器与重连机制单测
│   ├── router/                       # go_router 强类型路由与导航守卫
│   │   └── __tests__/                # 路由跳转与重定向逻辑测试
│   ├── theme/                        # LiquidGlass 移动端统一设计系统 (Tokens/ThemeExtension)
│   │   └── __tests__/                # 主题对比度、明暗模式与 Token 一致性测试
│   └── widgets/                      # 跨 Feature 复用的原子级 Liquid Glass 组件
│       └── __tests__/                # 全局组件 Widget 测试
├── features/
│   └── <feature_name>/               # 业务特性模块（高内聚、按领域垂直切分）
│       ├── data/
│       │   ├── datasources/          # ObjectBox Entity、Retrofit Client、本地/远程数据源
│       │   │   └── __tests__/        # 数据源单测与 DTO/Entity 转换测试
│       │   └── repositories/         # Repository 具体实现 (返回 Either / TaskEither / Stream)
│       │       └── __tests__/        # Repository 缓存策略、离线优先与错误转化测试
│       ├── domain/
│       │   ├── models/               # @freezed 领域模型 + Luthor 校验 Schema
│       │   │   └── __tests__/        # 领域模型不变量、序列化与 Schema 边界测试
│       │   ├── repositories/         # Repository 抽象契约接口 (仅定义跨层边界)
│       │   └── services/             # 【按需创建】仅用于跨多 Repository 的复杂领域逻辑（严禁单行透传 UseCase）
│       │       └── __tests__/        # 复杂领域算法单元测试
│       └── presentation/
│           ├── providers/            # @riverpod 状态控制器与派生状态 Selector
│           │   └── __tests__/        # Provider 状态机流转测试
│           ├── pages/                # 页面级 HookConsumerWidget
│           │   └── __tests__/        # 页面级全状态（骨架屏/空/错/正常）Widget 测试
│           └── widgets/              # 局部精细化组件（保持小巧，const 优先）
│               └── __tests__/        # 局部组件交互与手势测试
└── main.dart
test/
└── all_tests.dart                    # 仅作为聚合入口，import 所有 lib/**/__tests__/*_test.dart
```

---

## 4. Liquid Glass 移动端统一 UI/UX 设计系统规范 (Mobile-First Unified Design System)

本项目采用 **Android 与 iOS 100% 共享的 Liquid Glass（液态光学玻璃）移动端设计语言**。**严禁在代码中写 `if (Platform.isIOS) Cupertino... else Material...` 分裂出两套外观！** 双端共用同一套高帧率、半透明折射质感、弹性物理动效与移动端拇指友好交互范式。

### 4.1 视觉层级与光学玻璃材质 (Optical Glass Hierarchy)

所有视觉参数必须收敛在 `lib/core/theme/` 的 `ThemeExtension`（如 `AppGlassTheme`、`AppSpacing`、`AppRadius`、`AppColors`）中，严禁在业务组件内硬编码 `Blur`、`Opacity` 或 `Color`：

1. **三层空间景深（Spatial Depth Layers）**：
   - **Canvas Layer（底层画布）**：深邃富有层次的动态渐变或柔和环境光底色（Dark Mode 默认优先，同时完美适配 Light Mode），为上层毛玻璃提供丰富的透射色彩基底。
   - **Surface Glass Layer（内容承载层）**：使用 `liquid_glass_widgets` 卡片/容器承载列表项与信息模块。具备微妙的高光折射描边（1px 半透明渐变亮边，模拟光源从左上方 45° 入射）与柔和背景模糊。
   - **Floating Chrome Layer（悬浮控制层）**：顶部导航栏（Glass AppBar）、底部悬浮胶囊导航栏（Floating Glass Pill Navigation Bar）、悬浮操作按钮（FAB）与底部抽屉（Glass Bottom Sheet）。拥有更高的模糊度与折射率，内容滚动至其下方时必须呈现真实的实时透射模糊效果（要求页面主体采用 `extendBody: true` 与 `extendBodyBehindAppBar: true`）。
2. **克制使用模糊，保障 120Hz 帧率（GPU Budget Discipline）**：
   - 同一视口内同时叠加的实时高斯模糊（`BackdropFilter`）层级**不得超过 3 层**。
   - 严禁在高频滚动的长列表（`ListView` / `SliverList`）每一个细小子项中滥用高开销实时全屏级 Shader/Blur；列表项优先使用 `liquid_glass_widgets` 针对滚动优化的轻量半透明玻璃样式或 `RepaintBoundary` 隔离重绘区域。
3. **8pt 空间网格与流体圆角（Grid & Concentric Curvature）**：
   - **严格 8pt/4pt 网格系统**：所有间距与内边距仅允许取自 Token：`4, 8, 12, 16, 20, 24, 32, 40, 48`，并使用 `Gap(x)` 表达。
   - **同心圆角法则（Concentric Corners）**：外层玻璃容器圆角为 $R_{\text{outer}}$，内边距为 $P$ 时，内部嵌套元素的圆角必须遵循 $R_{\text{inner}} = \max(R_{\text{outer}} - P, 8)$，营造浑然一体的光学倒角质感。

### 4.2 移动端优先交互工程实践 (Mobile-First Ergonomics & Interaction)

1. **单手拇指热区优先（Thumb-Zone Ergonomics）**：
   - 高频核心操作全部下沉至屏幕下半部（底部悬浮玻璃栏、底部操作条、下拉手势）。
   - 破坏性操作使用项目自有确认 Dialog；连续选值的低频设置使用 Bottom Sheet + Picker。两类弹层均须保持明暗主题、圆角和操作热区一致。
2. **物理触感与微交互（Tactile Physics & Haptics）**：
   - **触控热区铁律**：任何可点击/可拖拽的移动端交互元素，其最小物理响应区域必须 **$\ge 48 \times 48\text{ dp}$**。图标本身较小时，必须通过透明 Padding 扩充点击热区。
   - **按压弹性反馈**：所有可点击玻璃卡片与按钮必须具备按压微缩放（如 `scale: 0.97`，持续 `120ms`，缓动曲线 `Curves.easeOutCubic`）与光泽高亮反馈。
   - **触觉反馈（Haptic Feedback）**：关键交互节点必须绑定分级触觉反馈封装（轻触切换 Tab 用 `HapticFeedback.selectionClick()`，主操作确认用 `lightImpact()`，警告/删除/错误用 `heavyImpact()` 或 `vibrate()`）。
   - **统一双端物理滚动**：全局 `ScrollBehavior` 统一配置为具备回弹阻尼质感的 `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`，确保 Android 与 iOS 拥有完全一致的丝滑惯性与边缘回弹体验。
3. **安全区域与软键盘丝滑避让（SafeArea & Keyboard Inset）**：
   - 所有页面必须精确处理刘海屏/灵动岛（Top SafeArea）、底部手势横条（Bottom Home Indicator）以及折叠屏/小屏手机的尺寸自适应。
   - 表单与底部输入栏必须监听 `MediaQuery.viewInsetsOf(context).bottom`（注意使用 `viewInsetsOf` 而非整个 `MediaQuery.of`，避免无关重建），配合平滑动画随软键盘丝滑顶起，点击空白区域自动收起键盘（`FocusScope.of(context).unfocus()`）。
4. **杜绝布局抖动与加载割裂（Zero Layout Shift）**：
   - 异步加载态严禁使用孤立的转圈动画导致加载完成后页面剧烈跳动。必须使用 `Skeletonizer` 包裹与真实数据态 **1:1 等高同构** 的占位玻璃卡片。
   - 空状态（Empty State）统一在内容区域居中显示一行小字号、弱化色的纯文本；禁止使用 Liquid Glass 卡片、方块、插画或图标。错误状态（Error State）也使用简短纯文本说明，必要时可在文本下方单独提供重试按钮，不得将说明放入玻璃卡片。
5. **Markdown 与流式富文本 Liquid Glass 融合规范 (`flutter_smooth_markdown`)**：
   - **统一视觉主题映射**：在 `lib/core/theme/` 中基于当前 Liquid Glass 明暗模式统一构建 `MarkdownStyleSheet`、`MermaidStyle` 与 `MarkdownEditorThemeData`（通过 `ThemeData.extensions` 全局挂载）。代码块、引用块、表格与 AI 思考块（`ThinkingPlugin` / `ArtifactPlugin` / `ToolCallPlugin`）必须采用半透明毛玻璃容器与同心圆角（Concentric Corners）设计。
   - **流式渲染与移动端手势适配**：AI 流式响应或增量文本展示必须使用 `StreamMarkdown` 避免高频全量重解析卡顿；开启 `selectable: true` 时配合 `SmoothSelectionController` 提供移动端原生级段落/全文丝滑选中菜单，点击链接（`onTapLink`）或图片（`onTapImage`）统一接入应用内路由或玻璃模态预览器（严禁直接裸调 `print`）。
   - **安全边界**：默认保持 `MarkdownConfig(enableHtml: false)`；仅在明确受信任的内容源下按需开启白名单 HTML，杜绝 XSS 或非法 Scheme 注入。
6. 禁止使用大段的描述性文本去描述某个功能块，仅允许使用简短的 UI 文本或者 icon 去指示功能。

7. 页面顶部契约：所有标准页面的 page button 与 page title 必须使用统一的 toolbar 高度和垂直中心基线，按钮保留最小 48dp 触控热区，标题 capsule 的最小高度与按钮一致。特殊头部（例如 Chat 的头像叠加头部）必须显式声明独立高度，并为其提供布局测试；服务商、模型等子页面不得自行改变 button/title 的高度。

### 4.3 Dialog 专用规范

- 所有确认弹窗使用 `AppConfirmDialog`，消息等多操作弹窗使用 `AppActionDialog`；业务页面只负责调用 `showDialog` 和传入已确定的文案、回调。Dialog 自身使用不透明主题表面和项目 Token，不启用 Liquid Glass shader 或实时模糊。
- **禁止使用 `liquid_glass_widgets` 的 Liquid Dialog、`showGlassActionSheet`、`GlassActionSheet`，也禁止业务页面直接构造 `AlertDialog` / `CupertinoAlertDialog` / 裸 `Dialog`。**新增 Dialog 样式先扩展 `lib/core/widgets/` 的自有组件并覆盖明暗主题与交互测试。
- 所有自定义 Dialog 和 Bottom Sheet 内的保存、取消、确认、删除等操作统一使用 `AppActionButton`；纯图标操作使用 `AppActionIconButton`。按钮采用胶囊圆角、至少 48dp 高触控区和主题派生的实色低对比度描边，按 primary、secondary、destructive 区分语义；禁止渐变描边、高对比度描边以及业务层直接使用 Material 按钮拼出另一套样式。
- Bottom Sheet + Picker 是选择器，不属于 Dialog；保留其独立交互。弹窗 builder 不得在页面可能卸载后通过外层页面 `BuildContext` 读取主题或翻译，打开弹窗前先取得所需值。

### 4.4 自建组件库规范

- 可复用的应用 UI 原子组件集中在 `lib/core/widgets/`，并在“我的 > 开发工具 > 组件库 UI”提供可运行的组件预览；新增共享组件时同步增加预览和同级 `__tests__` 测试。
- 组件预览必须使用真实组件和当前主题 Token，至少覆盖明暗主题相关样式、禁用态或危险态等存在的变体；弹窗预览调用自建 Dialog，不在展示页另造一套样式。
- `AppActionButton` 与 `AppActionIconButton` 是弹层和表单 action 的唯一共享按钮入口；新增 action 语义优先扩展其主题变体，不在业务页面复制按钮装饰参数。

---

## 5. 核心工程实现规范与代码品味范式 (Implementation Paradigms)

### 5.1 声明式 UI 组件与状态消费范式

- **精细化 `select` 订阅**：在 Widget 中监听复杂状态时，若仅依赖某个字段，必须使用 `ref.watch(myProvider.select((s) => s.field))` 最小化 Widget 重建范围。
- **禁止通过函数返回 Widget（No Helper Methods Returning Widgets）**：严禁写 `Widget _buildHeader(BuildContext context)`！任何拆分的子视图必须定义为独立的 `class _HeaderSection extends StatelessWidget`（或 `HookConsumerWidget`）并加上 `const` 构造函数，赋予 Flutter Element Tree 稳定的边界与局部更新能力。

```dart
// 文件: lib/features/<feature>/presentation/providers/example_controller.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../../gen/features/<feature>/presentation/providers/example_controller.g.dart';

@riverpod
class ExampleController extends _$ExampleController {
  @override
  ExampleState build() => const ExampleState.initial();

  Future<void> refreshItems() async {
    state = const ExampleState.loading();
    final result = await ref.read(exampleRepositoryProvider).fetchItems().run();
    state = result.match(
      ExampleState.failure,
      ExampleState.loaded,
    );
  }
}
```

### 5.2 `fpdart` 声明式错误处理范式

```dart
// ✅ 正确示范：使用 TaskEither 声明式串联异步管道，零 try-catch 面条代码
TaskEither<AppFailure, Unit> syncSnapshot() {
  return _localDataSource
      .loadSnapshot()
      .flatMap(_remoteDataSource.upload)
      .tapLeft((failure) => _talker.error('Sync Snapshot Failed', failure));
}
```

### 5.3 ObjectBox 持久化与领域模型隔离规范

- **严禁将 ObjectBox 的 `@Entity()` 注解直接贴在 `@freezed` 类上**。
- 数据层（Data Layer）定义独立可变的 `*Entity`（供 ObjectBox 使用），领域层（Domain Layer）定义 `@freezed` 的不可变模型，通过类型安全的 Mapper 扩展方法进行 `toDomain()` / `toEntity()` 转换，并在 `datasources/__tests__/` 中 100% 覆盖双向映射测试。

### 5.4 跨平台与原生配置规范

- 修改平台原生配置文件（如 `android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist`、`macos/Runner/*.entitlements` 等）时，必须同步确保 Android 与 iOS 权限声明对等，并将原因记录到 `docs/decisions.md`。

---

## 6. 严禁事项与反模式清单 (Forbidden Anti-Patterns)

1. **禁止在 `lib/gen/` 以外生成任何代码**：每次执行 `dart run build_runner build -d` 后检查工作区，若 `lib/gen/` 之外出现 `.g.dart` 或 `.freezed.dart`，立即修复 `build.yaml` 并记录到 `docs/mistakes.md`。
2. **禁止在被测目录同级 `__tests__` 以外编写模块测试**：新增任何模型、数据源、Repository、Provider 或 UI 组件，必须同步在其同级 `__tests__/` 下创建对应的 `*_test.dart`，并注册至 `test/all_tests.dart`。
3. **禁止过度设计（No Speculative Abstraction）**：禁止单行透传 `UseCase`、禁止只有一个实现类的内部 `Interface`、禁止用不到的泛型参数。
4. **禁止平台分裂 UI**：禁止业务页面使用 Liquid Dialog / GlassActionSheet 或直接构造 Material / Cupertino 弹窗；仅 `lib/core/widgets/` 的自有 Dialog 可以封装 Flutter `Dialog` 基础组件。禁止使用 `SizedBox` 充当间距（强制用 `Gap`）。
5. **禁止忽略 Linter 警告与类型逃逸**：代码必须通过 `flutter analyze` 且 **0 issues**；严禁使用 `dynamic`、严禁无理由使用 `!`（非空断言操作符，必须通过模式匹配或 `Option` 安全解包）。
6. **禁止魔法数字与硬编码文本/资源**：间距、圆角、模糊度、动画时长全部走 `lib/core/theme/` 设计 Token；所有文案走 `slang` (`t.xxx`)；所有图标/图片走 `Assets.xxx`。
7. **禁止阻塞移动端 UI 线程**：JSON 大载荷解析、加密哈希、音频/图像二进制处理、大批量数据库写入必须放入 `Isolate.run` 或 ObjectBox 异步事务中执行，确保 UI 帧耗时稳定低于 `8ms`（120Hz 标准）。

---

## 7. 测试优先规范 (Test-First Specifications in `__tests__`)

**没有同级 `__tests__` 测试的代码等同于未完成，严禁勾选 Task 完成状态。** 每开发一个模块，必须遵循以下测试标准：

1. **领域模型与校验测试 (`domain/models/__tests__/`)**：
   - 验证 `@freezed` 模型的相等性、`copyWith`、JSON 序列化往返一致性（Round-trip）以及 `luthor` 表单 Schema 在合法值、空值、极值、非法格式下的精确校验结果。
2. **数据源与持久化测试 (`datasources/__tests__/` & `repositories/__tests__/`)**：
   - 使用系统临时目录初始化真实的内存/临时 ObjectBox `Store`（测试完毕后 `store.close()` 并清理目录），验证实体 CRUD、响应式 `Stream` 推送、事务回滚以及异常分支转化为 `AppFailure` 的确定性行为。
3. **状态机流转测试 (`providers/__tests__/`)**：
   - 使用 `ProviderContainer` 配合 `overrides` 注入 Fake/Mock Repository，使用Listener捕获状态序列，严格断言状态机从 `initial -> loading -> loaded / failure` 的完整轨迹。
4. **移动端 UI 与交互测试 (`pages/__tests__/` & `widgets/__tests__/`)**：
   - 使用统一的测试包装器（注入 `TranslationProvider`、LiquidGlass `ThemeData`、固定移动端视口尺寸如 `390x844` 与安全区参数）渲染组件。
   - 覆盖 4 大必测状态：**加载骨架态（`Skeletonizer`）、空数据态、错误重试态、正常数据渲染态**。
   - 验证关键手势（点击、滑动、表单输入错误提示展示）与最小触控目标尺寸合规性。

---

## 8. Agent 启动与闭环执行清单 (Bootstrap & TDD Loop)

当你读取本文件开始工作时，请严格按以下闭环执行：

1. **Step 1 - 侦察与建档**：
   - 检查项目当前状态，读取或初始化 `docs/mistakes.md`、`docs/decisions.md` 及 `docs/tasks/01-architecture-and-setup.md`。
2. **Step 2 - 记录核心架构决策**：
   - 在 `docs/decisions.md` 中维护 ADR（包括：`build.yaml` 统一重定向至 `lib/gen` 方案、同级 `__tests__` 测试桥接方案、Pragmatic Clean Architecture 反过度设计边界、Android/iOS 统一 Liquid Glass 移动端设计 Token 方案等）。
3. **Step 3 - 任务拆解（测试先行）**：
   - 将开发目标拆解为清晰的阶段性任务文档（存于 `docs/tasks/`）。首先完成 `01-architecture-and-setup.md`（依赖安装、`build.yaml` 验证、`__tests__` 桥接验证、Talker/GoRouter/ObjectBox/Slang/LiquidGlass 移动端主题基建），再按业务模块逐一推进。
4. **Step 4 - TDD 闭环开发与门禁校验**：
   - 每开发一个子模块，按 **「编写 `__tests__` 测试用例 -> 编写声明式实现 -> 运行代码生成与静态检查 -> 全绿通过」** 循环推进，并立即运行以下门禁命令：
     1. `dart run slang` & `dart run build_runner build -d`（确认产物 100% 位于 `lib/gen/`）
     2. `flutter analyze`（确认 **0 issues**）
     3. `flutter test`（确认 `test/all_tests.dart` 桥接的所有同级 `__tests__` 用例 **100% 通过**）
   - 遇到任何报错、陷阱或返工，修正后**立即追加一行高信息熵总结到 `docs/mistakes.md`**。
5. **Step 5 - 提交前全量格式化（强制）**：
   - 每次执行 `git commit` 前，必须先在仓库根目录运行 `.\tools\flutter\bin\dart.bat format .`，使用 formatter 格式化项目全部 Dart 代码（包括测试与生成代码），禁止仅格式化本次修改的文件或跳过此步骤。
   - 格式化必须成功完成；检查格式化产生的 diff，并将应提交的格式化结果纳入暂存区后，才可执行 commit。若之后再次修改或生成代码，必须重新执行全量格式化。
6. 每次完成一个完整的模块或者功能，都要 commit 一次，必须使用 `verb: desc` 的 msg 格式。

## 9. 工具链

- 优先使用当前目录下的 `.tools/flutter` 工具链，不要使用全局工具链。
