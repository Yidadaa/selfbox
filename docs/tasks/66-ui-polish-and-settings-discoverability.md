# 66 - UI polish and settings discoverability

- [x] 测试：五次点击插画解锁开发工具，四次保持隐藏、偏好持久化及失败回退。
- [x] 测试：图标尺寸与触控区、Headers 独立分组、全局分组间距及存储插画。
- [x] 测试：顶部 Toast 安全距离、自动消失与手动关闭；高级玻璃仅用于浮动元素。
- [x] 测试：无模型时短时记忆显示大号百分比；折叠 AI 提示渐变图文与右箭头。
- [x] 实现：统一 Token、页面布局和中英文文案，开发工具解锁逻辑。
- [x] 实现：Toast 顶部布局和玻璃性能边界。
- [x] 运行代码生成、定向测试、截图检查、全量格式化、analyze 与完整测试。
- [x] 更新 ADR、错误账本及设计规范，本地提交（不 push）。


## 验证记录

- 先行失败用例确认：20dp 图标实际被拉伸为 64dp；无模型预算显示 Not set。实现后均通过。
- 开发工具页面测试覆盖默认隐藏、四次不解锁、第五次显示；Controller / JSON 测试覆盖持久化、失败不改变状态、清除恢复默认。
- 实际图标尺寸与 48dp 热区分别在共享图标、Composer、记忆页、头像选择器测试负责；Headers 拆组由页面测试负责，读写与保留配置由 provider_model_flow_test 负责。
- 渲染等级以三档矩阵验证；原有 premium 单例断言并入矩阵，避免重复。设置页面明暗/语言测试同时验证内容 standard 与浮动控件 premium。
- slang 与 build_runner 生成成功；产物仍集中 lib/gen。默认测试注册表维持 103 个同级文件。
- 全量 dart format 成功，flutter analyze --no-pub 为 0 issues，flutter test --no-pub 为 667/667。
- 17 个相关截图用例通过，人工查看 Headers、开发工具、存储插画、短时记忆百分比、折叠 AI 消息、顶部 Toast 及 280dp 输入栏；Headers key 调整后又更新明暗两张截图。
- 无新增依赖、平台权限或版本号变更；本地提交，不 push。
