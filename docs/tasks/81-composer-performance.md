# 81 - Composer 四处性能优化

- [x] 先补回归：光晕无额外 ImageFiltered、键盘中间帧玻璃不重建、附件玻璃无 Opacity 祖先、连续输入不重建控制行、导航画质矩阵（旧实现 6 项失败）。
- [x] 移除光晕离屏模糊，保持静态配色、裁切与编辑器位置。
- [x] 将键盘进度依赖下沉至玻璃内容，稳定 Shell 高度回传期间的 Dock 引用；附件改为材质参数与图标淡入，并封顶 standard。
- [x] 输入行取消全文订阅；局部缓存单行测量，仅多行布尔变化刷新字段 padding，跳过空文本、显式换行及选区变化测量。
- [x] 非聊天 Dock 最高 standard，Dock 增加重绘边界。
- [x] 验证中英文/Emoji、软换行/删除、大字号/宽度变化、键盘反转/禁用动画和焦点选区。
- [x] Slang/build_runner 生成成功，产物均在 lib/gen；全量测试 739/739，flutter analyze 0 issues，全量格式化成功。
- [x] 16 张真实字体截图通过并目视检查；AI 光晕截图增加图片预热后重拍 4 张通过。ADR-073、测试指南与错误账本已更新。
- [x] 完成功能并按仓库规范提交。

报告的「一次模糊与两次模糊像素级一致」不作为验收前提；记录视觉差异与缺少真机 GPU profiling 的限制。

截图位于忽略目录 tool/screenshots/out/composer_glow_*.png 与 composer-keyboard-*.png；删除独立模糊及附件参数过渡可能产生细微视觉差异，未宣称像素相同。软换行仍需精确字体测量；不使用字符数猜测。尚未采集 Android/iOS 真机的 UI/raster 帧耗时，不能给出 FPS 或百分比提升。

## 真机实测 APK

- [x] 构建 release arm64 拆分包，沿用 0.6.0+6 与正式签名。
- [x] 核验 APK 架构、版本和签名，提供带性能提交标识的 APK 与 SHA-256 文件。

产物：`build/app/outputs/flutter-apk/xiaolan-0.6.0-perf-507eb14-arm64-v8a-release.apk`，同目录附 `.apk.sha256`。aapt 与 ZIP 均确认仅含 arm64-v8a，包含 libflutter.so；versionName 0.6.0 / versionCode 2006，签名校验成功且证书 SHA-256 与任务 78 一致。构建耗时 88.1 秒，保留旧命名版本包。
