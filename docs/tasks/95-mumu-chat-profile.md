# 95 - MuMu Android 15 聊天 Profile 排查

- [x] 阅读项目记录及 MuMu ADB 教程，连接 Android 15 实例。
- [x] 配置本机工具链，构建并运行 profile 基线，记录设备与渲染后端。
- [x] 采集可重复聊天场景的 UI/raster 帧耗时，定位热点。
- [x] 先补行为/重绘回归，再实现不改变视觉效果的优化。
- [x] 重跑同场景对照、相关测试及静态分析，检查视觉一致性。
- [x] 完成回装基线复测，交付报告；用户确认后才可提交。

## 环境

- 2026-11-16；MuMuManager instance 0，Android 15，x86_64，ADB `127.0.0.1:16384`。
- Flutter 项目本地 SDK 3.47.9 / Dart 3.13.7。
- 初始 Git 工作区干净；模拟器尚未安装 `com.yidadaa.selfbox`。
- 模拟器结果仅用于同环境相对对照，不推断手机 GPU/120Hz 表现。

## 已验证

- 真实 profile AOT APK，Impeller Vulkan，1080×1920 / DPR 3 / 60Hz；原始基线 `d8607a3`。
- 新增“未跨阈值不重建”用例先失败；优化后预览 12 项全部通过。
- 全量 864 项通过，`flutter analyze --no-pub` 零问题。
- 四项预览明暗截图对比通过，实际为两组相同画面的 fixture；截图采用当前基线生成后在优化代码上直接比较，无更新基准掩盖差异。
- 同样 80 次消息行构建时，MessagePreview 由 120 次降为 80 次；MeasureSize Widget 构建由 80 次降为 40 次。没有将 Widget 构建数等同 RenderObject 布局次数。
- 生产变更仅 `message_preview.dart` 的高度订阅，详细采样入口在 `tool/profile/`。
- ADR-085 与错误账本已更新；未提交。
- A/B/A′ 各两轮 2,898 帧均无 UI/raster 超预算；全链路帧时间没有稳定改善证据，不宣称 FPS 提升。完整报告：`docs/reports/95-mumu-chat-profile.md`。

## 提交确认

- [x] 2026-11-16 用户明确要求提交，与任务96合并提交；原始APK、trace及截图继续保留在忽略目录。
