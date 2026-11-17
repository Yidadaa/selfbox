# 106 - Agent 单次模型调用重试

- [x] 测试：首次成功不重试、暂时失败后恢复、重试三次耗尽、每步独立预算且已执行工具不重复、永久错误直接失败、等待中取消、流中错误不重跑工具。
- [x] 实现：显式设置 SDK maxRetries=3（首次 + 3 次重试），保留 SDK 退避、Retry-After、取消和整体超时预算。
- [x] 验证：Agent domain services、Controller 与 SDK factory 共89项回归通过（含8项新增重试用例）；flutter analyze 0 issues，git diff --check通过，ADR-107已更新。保留先前照片样式待确认改动，不提交。

边界：SDK 重试针对 doStream 建立请求阶段的可重试 API 错误；已经返回响应流后的中断不自动重放，避免重复输出或工具副作用。

- [x] 用户随后明确要求提交；包含照片预览样式的待确认改动，全仓格式化497个文件无额外变更。
