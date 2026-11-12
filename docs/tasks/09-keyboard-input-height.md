# 09 - 键盘态输入框与附件圆钮等高

- [x] 测试：先复现右侧 64dp / 左侧 48dp；中英文、明暗主题、空 / 单行输入时，键盘态输入玻璃与附件圆钮均为 48dp，顶底边一致。
- [x] 测试：多行仍可增长，清空恢复原尺寸；placeholder 居中、焦点、键盘避让与最小触控热区保持正常，20 项输入组件测试通过。
- [x] 实现：键盘态输入行移除上下额外 padding，同步编辑区高度预算。
- [x] 验证：slang / build_runner 成功，生成文件均在 lib/gen 且 ObjectBox 模型无差异；analyze 0 issues，351 项全量测试通过；键盘态真实字体截图检查通过。更新 ADR / 错误账本并提交 `fix: match keyboard input height to attach button`。
