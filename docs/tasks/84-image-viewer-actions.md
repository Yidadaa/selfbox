# 84 图片手势与聊天提示

- [x] 测试：双指缩放与翻页竞争、双击放大/复位、放大平移、后加第二指。
- [x] 实现：统一主图手势及翻页吸附。
- [x] 测试与实现：搜索输入图标使用主题灰色。
- [x] 测试与实现：折叠提示使用 Agent 名字，用户 + AI 的消息条数，无末尾标点；保留改名和消息增删响应。
- [x] 按最终要求移除图片长按面板、相关操作、测试及新增依赖/权限。
- [x] 最终验证：生成代码、格式化、analyze、全量测试、真实组件截图。
- [x] 交付：同步到聊天关联 worktree，截图审查；不提交。

基线：be248a1，新 worktree；不含主目录未提交的菜单修改。
审查 worktree：C:/Users/flynn/.codex/worktrees/image-viewer-gestures/selfbox
验证工作副本：C:/Users/flynn/Desktop/selfbox/.worktrees/image-viewer-review（宿主工具仅能在已授权项目下写入；与审查源码逐文件校验一致）
运行环境：项目 .tools/flutter；PUB_CACHE 使用验证副本 .pub-cache；TEMP/TMP 使用 .dart_tool/tmp。

最终结果：analyze 0 issues；745 项完整测试通过；12 张真实组件截图通过。未提交、未暂存。审查图为 image-chat-review.png 与 search-review.png；全部 PNG 位于 tool/screenshots/out/。
