# 80 - 连续圆角与轻拟物浮层

- [x] 测试先行：Dialog / Sheet 使用连续超椭圆；按钮沿用同心圆角，渐变、细边及禁用态契约。
- [x] ThemeExtension 集中明暗渐变、边框和阴影，公共浮层材质组件复用。
- [x] 接入确认/操作 Dialog、全部七类 Bottom Sheet、文字和图标按钮。
- [x] 保留取消/确认/保存、禁用/忙碌、键盘避让、大字和窄屏行为。
- [x] 组件库展示与明暗截图验收；格式化、分析、完整回归。
- [x] 更新文档，完成截图验收后按用户后续要求提交。

## 验证与交付

- Slang、build_runner 完成，生成代码仍集中于 lib/gen；全量格式化与 flutter analyze 无问题。
- flutter test：730/730 通过。几何测试按像素采样比较 Sheet 顶部与 LiquidRoundedSuperellipse 的路径；材质测试覆盖明暗主题、正常/按压、4.5:1 对比度、不透明渐变与静止后无持续帧。
- 按钮覆盖禁用及按住时禁用、恢复交互和减少动画；现有页面回归覆盖保存、取消、失败恢复、窄屏大字与键盘避让。
- tool/screenshots/relief_fixtures.dart：确认弹窗、操作弹窗、主题选择 Sheet 各有明暗截图，6/6 通过并逐张视觉验收。
- 截图位于 tool/screenshots/out/relief-*.png；三个 *-comparison.png 为真实截图局部裁切拼接，便于对照。
- 用户已确认截图效果并要求提交；提交前再次全量格式化，383 个文件无新增变化。
