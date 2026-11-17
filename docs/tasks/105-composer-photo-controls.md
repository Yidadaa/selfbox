# 105 - 输入照片预览玻璃关闭按钮

- [x] 测试：多图关闭按钮保留 24dp 视觉尺寸和 48dp 热区，上/右视觉边距从 12dp 减为 6dp；覆盖明暗主题、三档渲染及删除接线。
- [x] 实现：独立圆形玻璃关闭表面，主题 Token 着色，standard 预算并遵从 minimal；照片裁切使用 LiquidRoundedSuperellipse。
- [x] 验证：组件与输入框回归 11 项通过，flutter analyze 0 issues；全仓 dart format 完成（495 文件，仅本次 2 文件变更），git diff --check 通过。

## 视觉修订

- [x] 测试与实现：去外圈叉号改为 12dp，24dp 玻璃面独立定尺寸；复用回底按钮默认玻璃材质和 foregroundMuted。
- [x] 明暗主题真实组件截图已生成并目视检查玻璃背景、无外圈叉号及与回底按钮的颜色一致性；11 项相关回归通过，flutter analyze 0 issues。截图在 tool/screenshots/out/composer_photos_{light,dark,review}.png，本轮按要求未提交。

- [x] 尺寸微调：叉号由 16dp 缩至 12dp，24dp 玻璃面与 48dp 热区不变；明暗 × 三档 6 项回归通过，更新截图，继续不提交。

- [x] 用户随后明确要求提交；与 Agent 重试改动一起纳入本次提交。
