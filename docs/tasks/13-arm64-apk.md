# 13 - 真机 arm64 APK

- [x] 构建前检查：当前 UI 改动已通过 357 项测试和静态分析，使用现有 release 签名配置。
- [x] 构建：`flutter build apk --release --target-platform android-arm64` 成功（31.5 MB）。
- [x] 验证：APK v2 签名有效，签名主体 `CN=Selfbox`（正式签名）；包 `com.yidadaa.selfbox` / 版本 `0.1.0 (1)`；仅含 arm64 `libflutter.so` 和 `libapp.so`。SHA-256 `11C92391C7877705FEF44738D224330AB6CB1983CF7538077991AFB4C9E8FAC3`。release APK 位于 `build/app/outputs/flutter-apk/app-release.apk`。
