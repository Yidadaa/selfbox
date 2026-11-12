# 11 - 发送按钮右侧与上下留白一致

- [x] 测试：键盘态空输入 / 可发送输入，发送圆形的右、上、下可见留白相等；覆盖中英文与明暗主题，原实现复现右侧多出 8dp。
- [x] 实现：键盘态去除额外右 padding，三侧可见留白均为 6dp；保持输入与附件圆钮 48dp、发送热区不小于 48dp。26 项相关测试通过。
- [x] 验证：多行与收键盘回归通过；slang / build_runner 成功，ObjectBox 模型无差异，analyze 0 issues，357 项全量测试通过；真实字体键盘态截图确认三侧协调，更新记忆并提交 `fix: balance send button inset in keyboard input`。
