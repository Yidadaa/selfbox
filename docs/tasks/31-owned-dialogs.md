# 项目自有 Dialog 统一

- [x] 测试：自有操作 Dialog 在明暗模式下使用不透明主题表面、统一圆角和按钮布局；取消与动作回调语义正确。
- [x] 测试：消息、记忆和服务商操作入口均显示自有 Dialog；取消不删除，确认后执行原有动作。
- [x] 实现：移除业务代码中的 GlassActionSheet，统一由 core/widgets 自有 Dialog 承载确认与操作菜单。
- [x] 文档：AGENTS.md 明确 Dialog 禁用 Liquid Glass Dialog / ActionSheet，记录设计决策。
- [x] 验证：项目 Flutter 代码生成、静态分析 0 issues、全量 431 项测试通过。
