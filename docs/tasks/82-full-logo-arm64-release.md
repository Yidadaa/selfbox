# 82 - 完整 Logo 与 arm64 APK

- [x] 验证：先更新品牌资源契约，确认完整 PNG 在常规图标中铺满、原图未被去噪修改，自适应前景保持完整。
- [x] 实现：品牌生成器使用 `docs/design/asset-kit/logo/logo-full.png`，重生成运行时 Logo、Android/iOS/macOS/Windows 图标及启动 Logo。
- [x] 验证：品牌测试、全量测试、静态分析与图标视觉检查。
- [x] 构建：沿用 0.6.0+6，构建 release arm64 split APK，核验版本、ABI、图标与签名并输出校验文件。
- [x] 交付：更新文档，全量格式化，提交本任务改动并提供 APK。

验证：新增完整 Logo 像素契约先失败，生成后品牌测试 15/15、全量测试 739/739 通过，静态分析 0 issues。Slang / build_runner 已运行，生成代码仅在 lib/gen。全量格式化覆盖 386 个 Dart 文件。已查看实际 192px Android 图标。ZIP 解码像素确认包内常规图标、自适应前景、运行时和原生启动 Logo 与生成文件一致。

构建命令：`.tools/flutter/bin/flutter.bat build apk --release --target-platform android-arm64 --split-per-abi --no-pub`。aapt 与 ZIP 均确认仅含 arm64-v8a，应用名“小懒”、versionName 0.6.0、versionCode 2006。APK v2 签名有效，证书 SHA-256 与旧版一致：`4532dcac9b336d0c6c1edbaef887ff4a0859f74ed2ec87f8187389226cca65ea`。

产物：`build/app/outputs/flutter-apk/xiaolan-0.6.0-full-logo-arm64-v8a-release.apk`，38,094,948 bytes；同目录 `.apk.sha256` 为 `140AACB4D690ED45B483168242D3CEB794B739B330AA74FE734060A036C8065D`。沿用已有签名和版本，可覆盖安装。仅本地提交，不 push；任务开始前已有的 `docs/design/asset-kit/logo/logo.svg` 删除保持未暂存。
