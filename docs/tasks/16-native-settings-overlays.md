# 16 - 设置页原生白色弹层

- [x] 测试：清除数据确认使用白色对话框，维持 34dp 圆角；取消不清除、确认仍执行清理。
- [x] 测试：历史对话轮次通过白色底部 Picker 选择并保存，取消不保存。
- [x] 实现：清除数据确认替换 GlassActionSheet 为白色 Material Dialog，显式关闭文本装饰线。
- [x] 实现：历史轮次选择改为白色圆角 BottomSheet + CupertinoPicker。
- [x] 验证：设置页弹层测试通过；全量测试 363 项通过；`flutter analyze` 无问题。
