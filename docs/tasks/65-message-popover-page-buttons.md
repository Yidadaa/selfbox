# 65 - 消息 Popover、文本选择与页面主按钮

- [x] 测试：Popover 锚定触摸位置，纯白实心、同卡片圆角与扩散阴影；边缘/键盘/窄屏避让，图标文字项、点击外部与返回关闭。
- [x] 测试：消息文本长按选择并复制所选内容，消息删除及图片长按操作正常，取消不修改消息。
- [x] 测试：页面全宽按钮使用 standard Liquid Glass，忙碌/禁用不可重复触发；浮层保存、取消、删除按钮保持现有组件。
- [x] 实现：共享 Popover 与选择菜单，替换聊天长按 Dialog，统一 Hugeicons 与视觉 Token。
- [x] 实现：共享页面玻璃按钮并迁移页面入口，保持浮层独立；组件库增加真实预览，同步规范。
- [x] 验证：代码生成、定向测试、明暗截图、全量格式化、零问题分析及完整回归，更新文档并本地提交。

## 验证归属

- 共享样式与交互：`app_action_popover_test.dart` / `app_page_button_test.dart`；消息选区复制和全选：`message_selection_test.dart`。
- 真实页面接线：`chat_page_test.dart` 验证消息删除与图片锚点、圆角；`component_library_page_test.dart` 验证真实预览；保留服务商、模型设置、资料和存储页面原有业务测试。
- 明暗主题下消息卡片菜单、文本选择菜单、资料保存与存储清除共八张截图已检查，输出在忽略目录 `tool/screenshots/out/message_actions_*.png`。
- 已通过 Slang / build_runner，新增三份同级测试注册到默认入口。页面按钮默认 standard，可由全局渲染偏好统一调整；浮层操作仍为原实色按钮。
- 最终门禁：`flutter analyze --no-pub` 0 issues，完整回归 657/657，最终选区文案归入 Slang 后定向回归通过；353 个 Dart 文件全量格式化成功。仅本地提交，不推送。
