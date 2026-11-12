# 05 - AI 切换时保留键盘

- [x] 测试：键盘已打开，空草稿和有内容草稿切换 AI 模式均不失焦、不收键盘；再次切换行为一致。
- [x] 实现：用 `TextFieldTapRegion` 将 AI 按钮纳入输入框点击区域，聊天页原有空白点击仍可收键盘。
- [x] 门禁：`flutter analyze` 0 issues、`flutter test` 313 项通过、键盘态截图复查并提交。
