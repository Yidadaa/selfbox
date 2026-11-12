# 07 - 输入提示垂直位置诊断与修复

- [x] 阅读输入区、主题、现有测试与本地 Flutter 基线布局源码。
- [x] 临时同级 Widget 诊断使用真实中文字体：提示 top=695.6，编辑区 top=690.0；两者高度均为 24dp，正文输入前后编辑区位置不变。
- [x] 验证原因：中文 bodyLarge 为 ideographic；RenderParagraph 固定返回 alphabetic，RenderEditable 使用请求的基线；两者差约 5.6dp。
- [x] 在独立诊断场景将正文与提示样式同时设为 alphabetic，提示与编辑区 top 一致，测试通过；诊断输出保留在忽略的 tool/screenshots/out/placeholder-diagnostic.json，临时测试已移除。
- [x] 更新错误账本，说明原因与修复位置；本次仅回答原因，未改动产品实现。

- [x] 回归测试先复现中文 placeholder 向下偏移 5.62890625dp。
- [x] 测试：8 组中英文、明暗主题、键盘展开/收起场景，覆盖普通/AI 提示；输入及清空后无跳动，已注册全量测试入口。
- [x] 实现：正文与 placeholder 从同一主题字体派生，统一 alphabetic 基线。
- [x] 验证：slang / build_runner 成功，生成文件全部位于 lib/gen，ObjectBox 模型无差异；analyze 0 issues，336 项全量测试通过，5 项聊天截图生成通过并目视检查深色提示与键盘输入。
- [x] 提交修复：`fix: align chat placeholder and input baselines`。
