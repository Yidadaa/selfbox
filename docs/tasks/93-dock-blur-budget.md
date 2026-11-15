# 93 - Dock 模糊预算

- [x] 先补主题预算与附件键盘进出场回归，旧实现主题两项、附件动画契约一项失败。
- [x] 明暗 chromeBlur 降为 12、surfaceBlur 降为 8，chromeTint alpha 增加 13/255。
- [x] 附件采用固定 blur/tint 与整体淡入淡出，保留命中与语义切换。
- [x] 相关回归通过；全量 `flutter test --no-pub` 852 项通过，`flutter analyze --no-pub` 零问题，格式化与 diff 检查通过；ADR-083 与错误账本已更新。

不以 Widget 测试推断真机 GPU 帧耗时；本轮不改变 AI 模式 tint 切换动效。
