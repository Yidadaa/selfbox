# 84 - 消息菜单最新版 arm64 APK

- [x] 确认源码提交 049e282；沿用 0.6.0+6，静态分析 0 issues、完整回归 746/746 已在提交前通过。
- [x] 构建 release split APK，仅含 arm64-v8a。
- [x] 检查版本、ABI、签名与 SHA-256，提供带源码标识的 APK。

产物：`build/app/outputs/flutter-apk/xiaolan-0.6.0-049e282-arm64-v8a-release.apk`，38,082,076 bytes（36.3 MiB）；同目录提供 `.apk.sha256`。

验证：aapt 确认应用“小懒”、包名 com.yidadaa.selfbox、versionName 0.6.0、split versionCode 2006；aapt/ZIP 均仅包含 arm64-v8a。APK v2 签名有效，证书 SHA-256 与旧版一致（4532dcac9b336d0c6c1edbaef887ff4a0859f74ed2ec87f8187389226cca65ea）。保留已有版本与签名，可覆盖安装。

构建：`.tools/flutter/bin/flutter.bat build apk --release --target-platform android-arm64 --split-per-abi --no-pub`，进程设置 GRADLE_USER_HOME=.tools/gradle 与 TEMP/TMP=.tools/task-temp。使用源码提交 049e282，未修改产品代码；此前完整回归 746/746、静态分析 0 issues 继续有效。

SHA-256：`60FD21680870870BE5FDD281D7C40E50F01BBEA29E889732BCAFAB119AED54A5`。
