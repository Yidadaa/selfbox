# 97 - iOS 模拟器构建与运行

- [x] 验证：检查 Flutter/Xcode 工具链及 iOS 17.5 模拟器运行时。
- [x] 准备：在仓库 `.tools/flutter` 安装 Flutter 3.47.9；恢复依赖并生成 slang、build_runner 代码。
- [x] 构建：生成 iOS Simulator Debug 应用。
- [x] 运行：安装至 iPhone 15 / iOS 17.5 模拟器并启动，确认显示“小懒”欢迎页。

产物：`build/ios/iphonesimulator/Runner.app`（Debug，272 MiB）。

说明：Flutter 3.47.9 不支持 Simulator Release 模式；本次采用 Debug 模拟器构建。iPhone 15 模拟器保持启动。
