# 12 - AI 消息使用 standard Liquid Glass

- [x] 测试：明暗主题的 AI 文字 / 图文消息使用 standard GlassContainer，正文内无旧实色底层；时间与状态仍在表面外，长按正常。先复现 4 项材质契约失败，修复后 20 项消息测试通过。
- [x] 实现：AI 文字表面使用主题派生的 standard 玻璃与消息圆角，滚动重绘隔离。
- [x] 验证：slang / build_runner 成功，生成文件仅在 lib/gen 且 ObjectBox 模型无差异；analyze 0 issues，357 项全量测试通过；真实字体明暗聊天截图确认玻璃表面、正文与外置 footer 正常。更新文档并提交 `feat: use standard liquid glass for AI message surfaces`。
