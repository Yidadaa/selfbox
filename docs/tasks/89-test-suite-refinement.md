# 89 - 按重构指南精简测试

- [x] 核对当前测试与指南差异，记录删除断言的保留位置。
- [x] 修复无效循环和不完整状态契约，保留独有风险边界。
- [x] 收回跨层样式断言，精简 Composer、图片与设置重复流程。
- [x] 合并同源测试，更新测试归属与聚合入口。
- [x] 执行格式化、静态分析和完整回归，审查后提交。

## 约束

- 当前代码已恢复 web_read，web_search 仍隔离；旧 ADR-069 不能作为当前行为依据。默认集合精确名单归 agent_tools，首轮/后续轮真实请求归 assistant_agent；网页工具测试只检查隔离集合及实现。
- 保留历史预算/实际请求、网络安全各层、清理编排各层、diff/文件并发的独立边界。
- 仅删除已确认有归属的重复契约；不以文件数或通过数代替覆盖依据。

## 审计与迁移（文件名省略 _test.dart）

工作区开始时干净，实际为 138 个同级测试文件（指南的 137 为早期快照，当前包含 chat_scroll_controller）。审计覆盖全部注册文件及两个独立 tool 入口；产品代码不变。

| 原位置 | 保留位置与边界 |
| --- | --- |
| ai_composer_glow 的 16 相位 × 两种高度 | 同文件每种高度/明暗各采样一次；保留裁切、瞬时开关、后台恢复、无持续帧。静态行为不再为 reduceMotion 重跑。 |
| app_effects 中静态 Glow | 同文件只验证真正调度动画的 Skeletonizer，保留禁用/恢复及系统减少动态效果。 |
| glass_reactive_text_field 明暗循环 | 同文件单次验证多行绑定、min/maxLines；该用例无主题断言。 |
| assistant_controller dismiss | 同文件同时验证 failed 清除、working 不清除且回复完成。 |
| general_page、ai_providers_page、provider_headers_flow、provider_model_flow、short_term_memory_sheet 的 Sheet 材质 | app_modal_surface 明暗矩阵新增背景色，原有 shape、静态材质、结果返回保持；app_relief_theme 负责色彩对比度。业务页保留保存、取消、失败、键盘与布局。 |
| app_confirm_dialog 按钮内饰和暗色亮度 | app_action_button 与 app_theme；Dialog 保留自身尺寸、排布、标题、取消/执行结果。 |
| general_effects 的底层 qualityFor / section / chrome / reduceMotion 重复断言 | app_effects / settings_pages；设置页保留实际用户选择、全局有效画质和动画开关。 |
| router、chat_ai_toggle、message_quotes、app_icon 的 Hugeicons 常量 | app_icons 新增 ai/chat/memory/profile/quote/search；调用方保留 AppIcons 到实际 UI 的接线。 |
| 页面 EmptyState 无玻璃、消息菜单无 Dialog、点击外部关闭 | empty_state 与 app_action_popover；页面保留空/错文案、菜单操作、Clipboard、Toast、删除确认。 |
| brand_assets 重复 logo/native 解码与十条路由插画矩阵 | 原资源逐像素检查补充 alpha，避免重复解码；welcome_composer/about_page 既有插画检查，memory_page/message_search_page/app_router 补入 files/search/resting 实际接线。 |
| Composer placeholder 八组矩阵中发送几何 | chat_composer_keyboard 单一键盘矩阵；placeholder 保留中英/明暗/键盘的文案基线、填入后无抖动、清空恢复。 |
| keyboard 单行独立用例、软换行 padding | 单行高度并入 keyboard 对齐流程；内边距与软换行由 chat_composer_editor 的真实 TextPainter 排版负责，多行控件底对齐继续保留。 |
| composer 与 placeholder 中 48dp / 单行居中重复 | pressable/app_page_button 与 keyboard；仍保留实际小屏避让、图标绘制尺寸。 |
| keyboard_dismiss 小屏多行限高 | chat_composer 的带附件小屏用例覆盖聚焦和 unfocus 后仍有 inset 的两阶段限高。 |
| composer_keyboard_motion 的 0.3 倍重叠 | welcome_composer；运动测试保留中间帧、反向、禁用中断、终态与焦点。 |
| image_viewer_page 普通滑动/重复关闭/居中 | carousel 的两端、双向、缩略图、resize 与 3x 缩放关闭；page 保留真实聊天点击入口、跨消息缩略图点击、长历史可见性、无效图。 |
| assistant_ui 的点位移和 pending 内部结构 | assistant_live_bubbles 补充实际 pending/typing 位移，保留停止/恢复；页面仍测状态接线、问题相对位置、流式内容与滚动。 |
| message_quotes 的重复 quote 调用/Provider 列表 | composer_quotes 保留算法去重；页面只引用两条不同消息，保留 Sheet 部分移除、清空关闭、发送引用与原文定位。 |
| provider_page 重复 checkbox/已知可用数 | provider_model_flow 保留语义、图标、添加后数量；provider_page 保留刷新目录后数量更新，属于不同触发路径。 |
| 两处资料保存失败流程 | agent_profile_page 参数化 profile/prompt 两个失败源，共同填写 agentName/nickname/customPrompt 并选头像，验证失败后草稿、持久化差异和重试。 |
| profile_prompt_save / account_providers | 合并至 account_providers，保留日志隐私、重复提交、失败恢复、资料公开状态与头像权限。 |
| agent_identity / local_account_repository | 合并至 local_account_repository，昵称越界仅验证一次；保留原图/预设切换、旧数据隔离、非法头像与真实落盘。 |
| custom_prompt / short_term_memory_budget / ai_settings_edits 中模型组 | 合并至 ai_settings；服务文件保留编辑算法。所有 JSON、Schema、旧数据、预算边界保留。 |
| app_ai_tokens / app_canvas / 两处 EmptyState | 分别并入 app_theme / app_page_scaffold / empty_state。所有源断言保留。 |
| memory_page 超过 300 行 | 编辑器明暗与键盘布局移至同级 memory_editor_layout；业务读写与冲突仍归 memory_page。 |

## 核对后保留的相似场景

- keyboard 的 inset 收起但仍聚焦，与 keyboard_dismiss 的先 unfocus 再逐帧收起不是同一事件，分别保留草稿/选区回归。
- chat_composer 的失败后实际编辑器文本与重试发送，区别于 Controller 仅验证状态；保留 UI 接线回归。
- chat_timestamps 删除后恢复时间验证 Riverpod 派生到 Widget 的重新接线，纯 message_timestamps 不覆盖订阅失效，保留。
- general_page 的 Picker 失败后保持打开，与 general_effects 的 Switch 回滚有不同 UI 契约，Provider 状态测试不能代替，保留。
- user_profile 的 Schema 与 local_account_repository 的拒绝非法落盘是不同边界，不跨层删掉后者；仅消除仓库内部重复。
- composer_performance 的初始质量/跨 Tab、chat_composer_glow 的实时切换质量/AI 模式、router 的不同页面 chrome 材质承担不同接线，保留必要矩阵；去掉普通 composer/keyboard 中同一默认档位断言。
- 指南第二节全部边界保留；其余数据库、HTTP/代理/竞速、文件并发、SDK、权限、清理、日志、算法、路由及其他组件测试未发现需要迁移的同边界重复，保持。
- 截图与真实联网 smoke 仍为独立入口；此次不重生成截图、不以网络状态作为确定性门禁。

## 验证

- 第一批静态光效、表单和 Controller：21 项通过。
- Composer、资料页和 Sheet：26 项通过；气泡迁移的两项相位问题修复后，assistant_live_bubbles 3 项通过。
- 已重建聚合入口：134 个同级测试文件，磁盘注册完整性检查通过；全部同级测试文件不超过 300 行。
- `dart format .`：441 个 Dart 文件，最后一次执行 0 changes。
- `flutter analyze --no-pub`：No issues found。
- `flutter test --no-pub`：823 项全部通过，测试阶段约 65 秒。
- `git diff --check` 通过；审查确认产品源码无变更。提交信息：`refactor: consolidate test coverage and remove redundant assertions`。
