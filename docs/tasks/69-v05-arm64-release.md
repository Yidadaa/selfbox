# 69 - v0.5 arm64 发布包

- [x] 验证：版本展示夹具和关于页测试同步为 0.5.0 (5)，静态分析 0 issues，完整回归 707/707 通过。
- [x] 实现：升级为 0.5.0+5；关于页更新日期保持本次发布日期 2026-11-14。
- [x] 构建：沿用现有发布签名，生成 arm64-only release APK。
- [x] 核验：应用名、版本号、ABI、发布签名、文件大小及 SHA-256。
- [x] 全量格式化并提交所有未提交更改，不 push；提供 APK 路径。

## 产物

- 路径：`build/app/outputs/flutter-apk/xiaolan-0.5.0-arm64-v8a-release.apk`。
- 大小：38,260,456 bytes；SHA-256：`DC344D9E0B05F503449C41256B500AE0C9CBE59BFEF39C04D1529089C76E98D`；校验文件为同名 `.apk.sha256`。
- 应用名“小懒”，applicationId `com.yidadaa.selfbox`，versionName `0.5.0`，split versionCode `2005`。
- aapt 与 ZIP 检查均仅含 `arm64-v8a`；APK v2 签名有效，与上一版发布证书相同。
- 证书 SHA-256：`4532dcac9b336d0c6c1edbaef887ff4a0859f74ed2ec87f8187389226cca65ea`。
- 本次重打包使用同一 arm64-only APK 路径，签名证书保持一致；仅含 `arm64-v8a`。
- 构建：`flutter build apk --release --target-platform android-arm64 --split-per-abi --no-pub`，使用项目本地 SDK。
- 全量格式化覆盖 374 个 Dart 文件，无额外格式改动。
