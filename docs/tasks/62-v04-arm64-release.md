# 62 - v0.4 arm64 发布包

- [x] 验证：版本展示夹具与关于页测试同步到 0.4.0+4；相关 11 项测试通过，静态分析 0 issues。
- [x] 实现：升级 pubspec 版本，关于页更新日期为 2026-11-14。
- [ ] 清理：旧 APK 与对应校验文件删除被自动审批拒绝（批量和明确路径均返回 blocked by policy），未完成。
- [x] 构建：沿用发布签名，生成 arm64-only release APK。
- [x] 核验：版本、应用名、ABI、签名与 SHA-256，记录产物路径并提交。

产物：`build/app/outputs/flutter-apk/xiaolan-0.4.0-arm64-v8a-release.apk`，38,129,384 bytes。

核验：应用名“小懒”，versionName 0.4.0，split versionCode 2004，ZIP 原生库与 aapt 均仅显示 arm64-v8a；APK v2 签名有效，证书 SHA-256 与旧版一致：`4532dcac9b336d0c6c1edbaef887ff4a0859f74ed2ec87f8187389226cca65ea`。

APK SHA-256：`DE8B5505A556BEE228A99D277A0DA5878833ED4F15C605ED7036E548C687477F`。
