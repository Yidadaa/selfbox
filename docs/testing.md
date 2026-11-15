# 测试维护指南

## 2026-11-16 精简后的归属

以 [任务 89](tasks/89-test-suite-refinement.md) 的迁移表为准，下面历史任务中的旧文件名只用于追溯。当前 `profile_prompt_save` 已并入 `account_providers`；`agent_identity` 并入 `local_account_repository`；`custom_prompt`、`short_term_memory_budget` 与原 services 中模型/Schema 用例合并为 `domain/models/__tests__/ai_settings_test.dart`。`app_ai_tokens` 并入 `app_theme`，`app_canvas` 并入 `app_page_scaffold`，空态统一为 `empty_state`；记忆编辑布局独立为 `memory_editor_layout`。

- Sheet 背景/轮廓归 `app_modal_surface`，按钮内部材质归 `app_action_button`，图标常量归 `app_icons`；页面保留业务接线与页面特有布局。
- 静态 AI 光效只做明暗/高度采样与开关、后台、裁切检查，无相位循环。Skeletonizer 承担 AppEffects 动画停止/恢复契约。
- Composer 对齐与光学边距归 `chat_composer_keyboard`，排版内边距归 `chat_composer_editor`，占位符矩阵验证中英/明暗/键盘实际文案布局。键盘 inset 收起和先失焦收起属于独立事件，分别保留。
- 资料页失败重试统一在 `agent_profile_page`，按资料/提示词持久化失败源参数化，覆盖名字、提示词、头像全部草稿。
- `web_read` 当前已恢复、`web_search` 仍隔离。默认工具名单在 `agent_tools` 精确匹配；`assistant_agent` 的多步调用覆盖每轮实际请求；`agent_web_tools` 保留隔离集合与执行实现。
- 不为减少数量删掉真实 SDK、持久化、权限、并发、安全、页面重建等不同风险边界。

提示词入口调整（任务 87）：原 custom_prompt_page_test 迁至 profile_prompt_test，保留读取、清空、加载失败重试、草稿保留和窄屏键盘校验；原 custom_prompt_controller_test 迁至 profile_prompt_save_test，保留日志隐私与重复提交/失败恢复，并验证资料组合保存。profile_prompt_field_test 覆盖中英文动态 Agent 名称及固定四行；截图改为 profile_prompt 明暗资料页。

链接与自定义提示词见任务 86/87。message_links_test 覆盖原文边界；web_content_parser_test 覆盖 OG/Twitter/title/摘要/相对 icon 与畸形地址；objectbox_link_preview_repository_test 验证真实 Store 重开、断网命中、失败重试、并发去重及清空在途写入。external_browser_test 验证系统 externalApplication 模式和拒绝/异常。message_links_widget_test 覆盖实际文字坐标点击、长按菜单/选区、加载与失败等高、引用/AI/时间同行；message_search_page_test 验证真实图片解码和查看路由。assistant_web_prompt_test 验证阅读工具实际多步结果、每轮提示词与下一回合更新；custom_prompt_page/controller/model 与 settings repository/service 测试覆盖中英编辑、清空、加载/错误/失败重试、窄屏键盘、重复提交、旧配置、持久化和日志隔离。截图 message_links/custom_prompt 明暗四张使用真实组件。

引用体验补充（任务 85）：`message_quotes_test.dart` 验证 trash 图标、部分删除保持弹层、删空自动关闭和再次打开；单条直达/多条选择只展示目标原文，滚动视口从页面顶边开始，正文初始位置避开 toolbar，长文可滚到浮动头部下方。`message_expanded_page_test.dart` 的两类原文页面共用按 ID 查询的加载/失败重试契约。

多消息引用与长文阅读见 [任务 85](tasks/85-message-quotes-and-expansion.md)：composer_quotes_test 验证去重/移除/失败保留及发送清空；message_entity_test 与 ObjectBox 仓库测试验证仅 ID 往返和原消息删除后的关系保留；agent_references_test 覆盖跨窗口原文、嵌套关系、预算及实际模型请求，消息工具测试保留引用 ID。message_quotes_test 覆盖长按累加、根 Sheet 即时移除、单条直达/多条选择、旧消息定位、删除与窄屏键盘；message_preview_test 覆盖真实布局半屏上限、明暗蓝色“展开更多 + 右箭头”、短文/段落/表格及大字缩放。message_expanded_page_test 覆盖打开/返回零转场、全局动画偏好无影响、32dp 阅读留白与实际正文边界、深链、加载/错误重试及全文选择。输入布局回归把多行居中契约更新为底对齐，保留单行与键盘性能测试。

Composer 性能覆盖见 [任务 81](tasks/81-composer-performance.md)：`composer_performance_test.dart` 验证光晕无额外 ImageFiltered、键盘连续帧输入玻璃 identity、附件玻璃无 Opacity 祖先、连续输入不重建发送控件和单行字段，以及三档画质下跨 Tab 的背景预算与 Dock 重绘边界。`chat_composer_editor_test.dart` 比较精确排版结果，覆盖中英文/Emoji、显式及软换行、删除/清空、宽度/文字缩放、选区与输入法 composing 更新。既有键盘测试继续负责反向动画、减少动态效果、焦点和几何。

## 运行入口

使用项目本地 SDK，在仓库根目录运行：

```powershell
.\.tools\flutter\bin\flutter.bat analyze --no-pub
.\.tools\flutter\bin\flutter.bat test --no-pub
```

业务测试放在被测目录同级的 `__tests__/*_test.dart`。默认回归只有一个入口：`test/all_tests_test.dart`。新增、删除或重命名测试文件后重新生成，禁止手工维护 imports 和注册列表：

```powershell
.\.tools\flutter\bin\dart.bat run tool/gen_all_tests.dart
```

入口自带磁盘注册检查，遗漏新文件或残留已删除文件都会失败。局部回归直接指定文件或目录；多个 Flutter 测试命令串行执行，避免共享编译缓存冲突：

```powershell
.\.tools\flutter\bin\flutter.bat test --no-pub lib/features/chat/presentation/pages/__tests__
.\.tools\flutter\bin\flutter.bat test --no-pub lib/features/settings/presentation/widgets/__tests__/provider_model_flow_test.dart
```

## 测试归属

| 层次 | 负责验证 | 不应重复承担 |
| --- | --- | --- |
| `core/theme` | Token、对比度、主题派生、系统减少动态效果 | 业务保存流程 |
| `core/widgets` | 共享控件的材质、几何、触控区、禁用态、明暗与窄屏布局 | 每个页面再次断言同一 Dialog 的内部圆角和 Padding |
| `domain/models` / `domain/services` | 不变量、校验、纯算法、上下文预算与编排规则 | Widget 内部结构 |
| `data` | 真实序列化、数据库、文件、HTTP、凭证和平台边界 | 仅靠 UI 替身推断持久化正确 |
| `presentation/providers` | 状态流转、失败恢复、并发、取消和日志脱敏 | 公共控件的样式细节 |
| `presentation/widgets` | 组件交互、布局、动效生命周期与可访问性 | 无关页面导航 |
| `presentation/pages` / `core/router` | 真实页面接线、路由、加载/空/错/正常态、业务操作结果 | 已有组件矩阵完整覆盖的纯样式检查 |

组件测试和页面接线测试可以验证同一功能，但必须指出不同故障边界。例如历史预算算法与实际 SDK 请求、URL 校验与 HTTP 重定向、清除服务与 UI 等待屏障均应分别保留。

## 去重与合并规则

1. 比较前置状态、触发操作、断言和失败边界，不能只凭标题、行数或相似代码删除。
2. 删除用例前，将它的独有断言迁入保留用例；在任务文档写明旧位置、保留位置和保留的边界。
3. 相同操作但不同输入使用具名参数矩阵。明暗主题、语言、窄屏、大字、动画起始禁用与中途禁用存在不同风险，不因“看起来相似”裁剪。
4. 将同一流程的互补断言合并到一次执行中；不要把无关业务串成一个长用例，也不要只为降低用例数合并独立错误分支。
5. 公共夹具优先使用 `core/testing/`；局部重复数据与 finder 放同目录的 `*_test_support.dart`。专用于一项测试的替身保留在所属文件，避免把整个测试应用封装进新的泛型框架。
6. 超过 300 行的测试按被测对象或行为拆分，并保留文件级夹具、初始化、清理和注册。文件数不作为优化目标。
7. 每次整合后运行相关回归、静态分析和默认完整回归，核对用例增减及删除断言的归属；通过数不能替代覆盖依据。

当前局部夹具：设置页与设置组件共享 `settings_test_support.dart`；聊天页面共享 `chat_page_test_support.dart` 的消息构造和 Composer finder。

## 动效与异步测试

- 使用 `app_widget_tester.dart` 的手机视口、主题、语言和依赖注入；测试显式恢复平台亮度、文字缩放和视口设置。
- 无限光效、pending 点和流式状态使用 `settle: false` 与固定推进帧，避免等待永不结束的循环。
- 键盘过渡检查中间帧、反向、中途关闭动画及最终布局；真实文件 I/O 用 `tester.runAsync` 推进。
- Toast 用例推进自动退场时间，数据库和临时文件沿用 `temp_storage.dart` 的清理约定。

## 独立工具测试

下面两个入口已纳入测试审计，但不属于默认回归：

| 入口 | 用途与限制 | 命令 |
| --- | --- | --- |
| `tool/screenshots/app_screenshots_test.dart` | 真实字体和页面截图，供人工视觉审查；依赖本机字体，输出在忽略的 `tool/screenshots/out/` | `.\.tools\flutter\bin\flutter.bat test tool/screenshots --update-goldens` |
| `tool/web_research_smoke_test.dart` | 实际请求 Bing RSS 与公开网页，依赖外网可用性；确定性 HTTP/解析/安全测试在 `lib` 中运行 | `.\.tools\flutter\bin\flutter.bat test tool/web_research_smoke_test.dart` |

默认回归不访问真实搜索服务，不将截图生成或外部网络状态当作单元测试门禁。

截图入口使用专用 binding 开启真实模糊阴影；图片夹具预热原图及匹配解码尺寸的缓存，避免把未解码占位或测试默认的硬阴影误判为产品效果。

2026-11-14 的全量审计结果、用例迁移和验证记录见 [任务 63](tasks/63-test-suite-consolidation.md)。


UI 打磨覆盖补充见 [任务 66](tasks/66-ui-polish-and-settings-discoverability.md)：图标断言 HugeIcon 的实际绘制尺寸；玻璃档位以 minimal/standard/premium 矩阵验证预算；关于页五次点击解锁与偏好持久化分属页面和 Controller 边界。Toast 覆盖顶部安全距离、键盘态、滑动关闭、手动幂等关闭及自动退场。截图 `ui-polish-*` 使用真实页面，生成后销毁 Widget 树以清理提示定时器。

首次引导覆盖见 [任务 68](tasks/68-first-run-onboarding.md)。`pumpApp(firstRun: true)` 使用首次启动状态，普通页面夹具默认标记引导已完成；纯 Provider 测试的 `testAppOverrides` 保持模型原始默认值。资料/记忆/完成标记失败及并发归属 Controller 测试；页面验证草稿保留、跳过、配置往返、系统返回和失败重试。280dp 大字键盘用例同时验证输入项与底部按钮可见，转场覆盖开启和关闭动画；`onboarding-*` 截图预热实际图片，并覆盖四步明暗主题和窄屏键盘。

消息时间覆盖见 [任务 70](tasks/70-message-timestamps.md)：`message_timestamps_test.dart` 负责本地分钟邻接、日期边界和 AI 折叠规则；`date_labels_test.dart` 负责中英文秒级格式与 UTC 转本地；`chat_timestamps_test.dart` 验证真实聊天页双击、等待、新消息、删除、AI 标记以及保留分支的 Tab / push 往返重置。精确时间是页面会话状态，不写入偏好。

Composer 输入几何覆盖见 [任务 71](tasks/71-composer-hit-area.md)：键盘单行输入框/加号等高及输入边缘聚焦由 `chat_composer_keyboard_test.dart` 验证；显式多行、窄屏软换行和内边距归属也在同文件覆盖；`chat_composer_placeholder_test.dart` 覆盖中英文、明暗及键盘态占位符和发送控件布局。

本次 UI 打磨覆盖见 [任务 72](tasks/72-ui-polish-round-two.md)：`chat_ai_toggle_test.dart` 验证待命态渐变复用与切换动画；`memory_page_test.dart` 覆盖创建占位文案、编辑态不显示占位和中英生成文案；`provider_model_flow_test.dart` 覆盖模型 Checkbox 语义/保存、半屏全宽标题及两个模型按钮图标尺寸。

Onboarding 导航与文案覆盖见 [任务 73](tasks/73-onboarding-navigation-polish.md)：`onboarding_page_test.dart` 检查无末尾标点、指定副标题、头像入口无文案、底部按钮同高对齐、尾置箭头 4dp 紧贴及无分页底板；截图套件覆盖明暗主题和键盘态。

Composer 与消息菜单修正见 [任务 74](tasks/74-composer-spacing-and-message-actions.md)：`chat_composer_keyboard_test.dart` / `chat_composer_placeholder_test.dart` 对比发送圆钮到上、右玻璃边界的真实几何距离；`message_selection_test.dart` 检查长按菜单先行、原触点选词与复制；`app_action_popover_test.dart` 覆盖选项之间滑动高亮、滑出清除和松手执行一次。`message_actions_*` 与 `composer-keyboard-*` 截图覆盖明暗主题及键盘终态。

AI 渐变与引用块见 [任务 75](tasks/75-ai-gradient-quote-placeholder.md)：`app_ai_tokens_test.dart` 锁定红紫蓝色相及饱和度/明度；`chat_ai_toggle_test.dart` 验证按钮激活态图标与文字同用渐变；`app_markdown_theme_test.dart` 和 `app_markdown_builders_test.dart` 分别检查主题与静态/流式实际引用无左线；`memory_page_test.dart` 对比标题与正文占位符的实际绘制颜色。

网页工具暂停见 [任务 76](tasks/76-disable-agent-web-tools.md)：`agent_tools_test.dart` 验证默认工具集合不暴露网页能力；`assistant_agent_test.dart` 检查首轮及多轮实际模型请求；`agent_prompt_test.dart` 锁定离线能力说明。`agent_web_tools_test.dart` 继续验证隔离的网页工具实现，但它不进入模型请求。

AI 图标与模型数量见 [任务 77](tasks/77-ai-icon-and-model-count-polish.md)：AppIcons 契约检查指定 Hugeicons，页面测试检查实际入口接线；服务商数量覆盖中英文 0/1/5，模型流程覆盖添加后可用数减少、刷新目录后更新和 16dp 能力项间距。

图片手势与聊天提示覆盖见 [任务 84](tasks/84-image-viewer-actions.md)：手势测试验证双指及先拖动后加第二指、双击复位、放大平移和长按无 Bottom Sheet。聊天测试覆盖两种作者总数、Agent 改名、默认名字、新增/删除后的计数、展开操作；搜索图标验证明暗主题中性灰。截图包括主图、缩放、搜索和六条讨论折叠摘要。

消息菜单反馈见 [任务 83](tasks/83-message-menu-feedback.md)：共享 Popover 测试覆盖 136dp/12sp/44dp、连续圆角、无滚动、三档渲染、明暗按压/滑动即时统一高亮和长按滑入。`message_selection_test.dart` 覆盖两端消息在明暗主题中的实际 RichText 灰色选区、选区复制 Toast 和选区删除取消；`chat_page_test.dart` 验证整条复制到 Clipboard 后 Toast，以及文字/图片消息删除确认与取消。`about_page_test.dart` 覆盖五次解锁提示、失败重试与已解锁不重复提示。`chat_ai_toggle_test.dart` 断言图标和文字祖先是同一个 ShaderMask，保留中英明暗切换动画。Windows 原生测试 TEMP/TMP 指向 `.tools/task-temp`。

菜单紧凑微调：`app_action_popover_test.dart` 检查图标左留白 20dp、行高 44dp；`message_actions_highlight_{dark,light}` 截图通过真实 pointer-down 保持“选中文本”高亮，并断言 highlightedIndex，正常及高亮共四张截图验收。

菜单实机透底修正：共享菜单测试覆盖明暗 × 三档画质的 chromeTint/chromeBlur 显式接线；`message_actions_{card,highlight,selection}_minimal_{dark,light}` 用真实设置切换轻量档并断言实际菜单质量，配合普通档截图检查气泡遮挡、按压高亮及主题材质。
