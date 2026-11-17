# 105 - 输入照片预览玻璃关闭按钮

- [x] 测试：多图关闭按钮保留 24dp 视觉尺寸和 48dp 热区，上/右视觉边距从 12dp 减为 6dp；覆盖明暗主题、三档渲染及删除接线。
- [x] 实现：独立圆形玻璃关闭表面，主题 Token 着色，standard 预算并遵从 minimal；照片裁切使用 LiquidRoundedSuperellipse。
- [x] 验证：组件与输入框回归 11 项通过，flutter analyze 0 issues；全仓 dart format 完成（495 文件，仅本次 2 文件变更），git diff --check 通过。
