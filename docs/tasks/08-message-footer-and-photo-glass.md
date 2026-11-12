# 08 - 消息外置底栏与图片轻玻璃边框

- [x] 测试：文字 / 图片 / 图文消息的时间与 AI 标记位于内容外底部，按发送方左右对齐，覆盖明暗主题。
- [x] 测试：图片无实色气泡祖先、细边轻量玻璃与同心圆角、单图 / 多图尺寸、点击预览与长按保持可用；280dp 窄屏和 2 倍字体横向无溢出。
- [x] 实现：拆分文本气泡、图片堆叠与外置元信息；图片使用 standard 玻璃和 4dp 边框。
- [x] 验证：slang / build_runner 成功，ObjectBox 模型无差异，生成文件仅在 lib/gen；analyze 0 issues，350 项全量测试通过；6 张聊天截图生成通过并目视检查深色堆叠与浅色图文布局。
- [x] 更新 ADR-020 / 错误账本并提交：`feat: move message metadata outside bubbles and add glass photo frames`。
