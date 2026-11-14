# 78 - 0.6 arm64 发布

- [x] 验证：更新关于页版本夹具，执行版本页面测试与静态分析；核验 APK 版本、架构和签名。
- [x] 实现：版本更新为 0.6.0+6，沿用 2026-11-14 更新日期。
- [x] 构建：使用本地 Flutter 构建 release APK，仅包含 arm64-v8a。
- [x] 交付：全量格式化，提交全部未提交改动，提供版本命名 APK。

验证：静态分析 0 issues，关于页 6/6 测试通过；此前功能提交全量 720/720 通过。全量格式化覆盖 378 个 Dart 文件。APK 的应用名为“小懒”，versionName 为 0.6.0，split versionCode 为 2006；aapt 和 ZIP 均确认仅含 arm64-v8a。APK v2 签名有效，证书 SHA-256 与旧版一致：4532dcac9b336d0c6c1edbaef887ff4a0859f74ed2ec87f8187389226cca65ea。

产物：`build/app/outputs/flutter-apk/xiaolan-0.6.0-arm64-v8a-release.apk`，同目录提供 `.apk.sha256` 校验文件。构建使用 `.tools/flutter/bin/flutter.bat build apk --release --target-platform android-arm64 --split-per-abi --no-pub`。本地提交，不 push。
