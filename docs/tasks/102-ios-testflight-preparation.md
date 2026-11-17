# 102 - iOS TestFlight 准备

- [x] 更新：快进至 `origin/main` 的 `eef5a47`，版本为 `0.7.0+7`，并恢复原工作区改动。
- [x] 生成：运行完整 `dart run build_runner build`，同步 Riverpod provider 类型。
- [x] 验证：`flutter analyze --no-pub` 通过；聊天滚动相关测试 16/16 通过。
- [x] 测试准备：运行 `dart run tool/fetch_objectbox_native.dart` 安装 macOS ObjectBox 宿主库。
- [x] 全量测试：`flutter test --no-pub --concurrency=4` 881 项通过、1 项按预期跳过。
- [x] 归档：生成 iOS Release `Runner.xcarchive`，版本 `0.7.0 (7)`，arm64，最低 iOS 15.0。
- [x] 检查：确认归档无签名、无 Team、无 provisioning profile。
- [ ] 准备上传：当前 macOS 14.8.9/Xcode 15.4 不满足 Apple 的 Xcode 26+ / iOS 26 SDK 上传要求；本机还需配置开发团队与分发签名。
- [ ] 导出并上传签名 IPA 至 App Store Connect TestFlight。

产物：`build/ios/archive/Runner.xcarchive`。当前为无签名本地归档，不能上传或安装到真机。
