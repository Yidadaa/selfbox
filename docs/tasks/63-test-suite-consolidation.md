# 63 - 测试审计与整合

- [x] 审计：盘点全部同级测试、聚合入口、截图和联网工具测试，记录现有覆盖和基线结果。
- [x] 契约：按被测行为定位重复，明确保留位置；区分跨层验证与真正重复断言。
- [x] 整合：删除被完整覆盖的冗余用例，参数化相似场景，合并重复夹具。
- [x] 文档：更新测试归属、运行命令、维护规则和逐项审计结论。
- [x] 验证：重新生成测试入口、全量格式化、静态分析和完整回归，通过后提交。

## 审计基线（2026-11-14）

- 基于 `06fdff6`，默认回归 660 项全部通过。
- 审计覆盖 96 个同级测试文件、生成入口，以及 `tool` 下的截图和联网 smoke 两个独立测试入口；同时核对共享夹具、注册方式和源码相似片段。
- 只修改测试与工程文档，不修改产品逻辑。独立截图与联网工具本次只审查职责，不执行截图更新或外部搜索。

## 全部套件的审计结论

下表文件名均省略 `_test.dart`，目录均指对应模块的 `__tests__/`。数量为整合前快照。

| 范围 | 文件数 | 已核对文件与结论 |
| --- | ---: | --- |
| core/database、error、forms、logger | 4 | `app_store`、`app_failure`、`luthor_validator`、`talker_provider`：保留真实数据库重开、错误分类、表单桥接和日志注入契约。 |
| core/router | 2 | `app_router`、`app_dock_tabs_icon`：合并启动图标检查与重复路由匹配；保留 tab 路由、二级页覆盖、404、Dock 避让与首帧稳定性。 |
| core/storage | 1 | `data_reset_controller`：保留等待选图、重复重置屏障、失败恢复、记忆和偏好重置。 |
| core/theme | 3 | `app_effects`、`app_markdown_theme`、`app_theme`：保留主题 Token、对比度、全局效果及系统减少动态效果。 |
| core/widgets | 12 | `ai_composer_glow`、`app_action_button`、`app_canvas`、`app_confirm_dialog`、`app_icon`、`app_markdown_builders`、`app_page_scaffold`、`brand_assets`、`icon_source`、`illustrated_empty_state`、`pressable`、`toast_typography`：公共视觉契约归组件；Dialog 接收窄屏正常/大字矩阵，其余保留。像素裁切、字体继承与源码图标守卫验证不同边界。 |
| chat/data/datasources | 4 | `media_store`、`message_entity`、`public_web_http`、`web_content_parser`：保留图像解码与路径、实体映射、公开地址校验、HTML/RSS 解析。 |
| chat/data/repositories | 3 | `bing_web_research_repository`、`objectbox_message_repository`、`sdk_language_model_factory`：保留超时、重定向、大小限制、真实查询/分页/流和 SDK Headers。 |
| chat/domain/models | 1 | `agent_activity`：保留不可变快照和回答预览隔离。 |
| chat/domain/services | 7 | `agent_history`、`agent_prompt`、`agent_tools`、`agent_web_tools`、`assistant_agent`、`assistant_context_budget`、`vercel_gateway_options`：保留预算算法、实际请求、工具循环、Unicode 分段、缓存续读和协议选项。 |
| chat/presentation/pages | 3 | `assistant_ui`、`chat_page`、`image_viewer_page`：去重输入控件断言、合并发送成功断言；聊天测试按页面/行为拆分，图片导航归图片页；真实 Agent 回复接线与组件动效分别保留。 |
| chat/presentation/providers | 3 | `assistant_controller`、`chat_timeline`、`composer_controller`：保留状态序列、日志脱敏、取消与抢占、分组算法、选图权限及并发。 |
| chat/presentation/widgets | 15 | `assistant_failure_bubble`、`assistant_live_bubbles`、`assistant_motion_preferences`、`assistant_reply_transition`、`assistant_status_transition`、`chat_ai_toggle`、`chat_composer_glow`、`chat_composer_keyboard_dismiss`、`chat_composer_placeholder`、`chat_composer`、`composer_keyboard_motion`、`date_labels`、`message_bubble`、`outgoing_message_entrance`、`welcome_composer`：合并页脚、图标和 pending 动效；拆分输入键盘测试；保留明暗/语言/宽度及快速反向、中途禁用等风险矩阵。 |
| memory/data/repositories | 1 | `file_memory_repository`：保留真实文件 CRUD、路径、写队列、并发 patch 与 watch。 |
| memory/domain/models、services | 3 | `memory`、`unified_diff`、`user_memory_service`：保留路径 Schema、diff 上下文/CRLF/CJK 和旧资料迁移。 |
| memory/presentation/pages、providers | 2 | `memory_page`、`memory_providers`：保留实际编辑冲突、键盘可用性、Agent 外部更新及分组顺序。 |
| settings/data/datasources | 1 | `profile_entity`：保留旧字段与 Agent 字段的映射。 |
| settings/data/repositories | 6 | `agent_identity`、`file_ai_settings_repository`、`file_app_preferences_repository`、`http_model_catalog`、`local_account_repository`、`sdk_model_probe`：保留迁移、文件/凭证隔离、持久化、鉴权优先级及模型生命周期。 |
| settings/domain/models | 3 | `app_preferences`、`short_term_memory_budget`、`user_profile`：短时记忆编辑边界集中于预算测试；保留默认值、旧数据兼容、序列化、Schema 和 Token 换算。 |
| settings/domain/services | 4 | `ai_settings_edits`、`ai_settings_service`、`clear_app_data`、`model_test_service`：删除重复百分比 clamp，保留配置合并/选择、异步保存、重置编排及模型探测前置校验。 |
| settings/presentation/pages | 11 | `about_page`、`account_pages`、`agent_profile_page`、`ai_providers_page`、`component_library_page`、`general_effects`、`general_page`、`model_page`、`provider_page`、`settings_pages`、`talker_page`：去重版本、资料保存、服务商保存及公共表面，保留失败/取消/导航/即时偏好生效。 |
| settings/presentation/providers | 2 | `account_providers`、`app_preferences_controller`：保留权限拒绝/相册取消、失败不更新有效偏好、语言副作用与重置。 |
| settings/presentation/widgets | 5 | `agent_avatar_sheet`、`model_test_control`、`profile_introduction`、`provider_model_flow`、`short_term_memory_sheet`：去重新建服务商与格式切换；复用设置夹具，保留头像草稿、探测结果、实时介绍、模型选择和记忆估算。 |

## 去重与断言迁移

所有目标文件均保留于对应模块同级 `__tests__/`。

| 旧覆盖 | 保留位置 / 迁移内容 | 默认用例净变化 |
| --- | --- | ---: |
| 独立 Dock 图标测试 | `app_router_test` 启动页：三枚指定 Hugeicons 和真实渲染一起验证 | -1 |
| 单独 `/memory`、`/me` 路由匹配 | `app_router_test` 对应明暗 Dock 场景，加入 `matchedLocation` 断言；原测试同样通过 `go` 进入，并非冷启动测试 | -2 |
| account 页仅检查版本号 | `about_page_test` 明暗 × 语言 × 280dp 信息列表已包含已安装版本 | -1 |
| Me 编辑资料再保存两种名字 | `agent_profile_page_test`：保留 Me 编辑入口、必填校验、返回 `/me`、两种名字保存及旧头像隔离；另一个语言场景仍从聊天头像进入 | -1 |
| 存储页内部 Dialog 样式及窄屏检查 | `storage_page_test` 只留确认/取消/清除次数与错误重试；`app_confirm_dialog_test` 在 280dp 参数化 1×/2×文字，保留长标签、等宽和无裁切 | 0 |
| 两套新建服务商保存流程 | `provider_page_test` 加入未启用模型、添加入口断言；仍验证凭证、单次拉取和停留原页 | -1 |
| 默认/自定义 URL 格式切换 | `provider_page_test` 参数化 URL，保留两种行为；`provider_model_flow_test` 复用设置夹具 | 0 |
| 设置列表、表单、暗色表面分散启动 | `settings_pages_test` 明暗参数化，一次遍历同一路由时同时检查分组和表单 | -1 |
| 两处短时记忆百分比 clamp | `short_term_memory_budget_test` 合并输入集合，保留 -3、10、12、37、500 | -1 |
| 聊天页键盘位置和 AI placeholder | 既有 `chat_composer_keyboard_test` 精确避让/草稿/选区，以及 `chat_composer_placeholder_test` 语言 × 明暗 × 键盘矩阵 | -2 |
| 普通发送入库/清草稿与首次入场 | `chat_message_send_test` 首次发送：同时检查中文内容落库、气泡、清空和欢迎退场 | -1 |
| 两个单独时间戳页脚测试 | `message_bubble_test` 明暗 × 作者 × 内容矩阵保留所有有 badge 布局；纯文本在同一用例继续切换到无 badge 并检查外部页脚，普通 AI 提问的页面接线保留在 `chat_ai_mode_test` | -2 |
| 单独 AI 图标切换 | `chat_ai_toggle_test` 多语言文字动画内保留指定图形、初始与切换后渲染断言 | -1 |
| pending 点与消息入口混在同一测试 | 点的停止/恢复归 `assistant_live_bubbles_test`；入口中途禁用完成一次仍归 `outgoing_message_entrance_test` | 0 |
| 合计 | 迁移独有断言后删除重复执行 | **-14** |

## 文件组织

- `chat_page_test.dart` 保留时间线状态、日期分组、长按操作；新增 `chat_header_test.dart`、`chat_message_send_test.dart`、`chat_ai_mode_test.dart`、`message_search_page_test.dart`，图片查看用例并入已有图片页测试。
- `chat_composer_test.dart` 保留草稿/布局，键盘交互移入 `chat_composer_keyboard_test.dart`；消息构造与 Composer finder 集中到 `chat_page_test_support.dart`。
- 删除 `account_pages_test.dart`，资料加载归资料页，存储流程归 `storage_page_test.dart`；删除已合并的 `app_dock_tabs_icon_test.dart`、`assistant_motion_preferences_test.dart`。
- 所有 `*_test.dart` 均不超过 300 行。文件数 96 → 99，增加来自职责拆分；默认运行用例 660 → 646。
- `lib/**/__tests__/*_test.dart` 源码 12,813 → 12,566 行（不含生成入口和共享夹具）；行数只记录规模，不作为覆盖结论。

## 保留的相似场景

- 历史预算纯算法与实际模型请求验证不同边界；不合并为一个仅检查公式的测试。
- 公开 URL 校验、真实 HTTP 重定向/超时、HTML 解析与 Agent 分段阅读分别保留，防止解析测试替代网络安全验证。
- Repository、服务和 Provider 的清除/保存分别验证真实存储、跨仓库编排及 UI 并发屏障。
- General 的取消与保存失败、模型探测成功与失败、动画初始禁用与运行中禁用使用相似前置步骤，但预期与风险不同，保留独立用例。
- 品牌测试验证实际资源映射；插画组件、欢迎区、关于页分别验证布局与业务接线，保留各自职责。

## 验证

- 基线默认回归：660/660。
- 已重新生成聚合入口，注册 99 个同级测试文件。
- 已运行全量 `dart format .` 和 `flutter analyze --no-pub`，分析 0 issues。
- 最终默认完整回归：646/646，已包含夹具精简与有/无 AI 标记的连续页脚验证；无失败、跳过用例。
- 维护指南新增于 `docs/testing.md`，README、AGENTS 与 ADR-058 同步指向测试归属规则；历史任务的测试总数保留当时记录。
