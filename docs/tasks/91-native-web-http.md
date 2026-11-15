# 91 - 原生网页 HTTP 与链接预览恢复

- [x] 依赖 dry-run、源码核查：无 GMS、重定向、取消及桌面回退。
- [x] 测试先行：原生工厂注入、单链路请求、安全重定向/下载上限、旧缓存迁移及失败重试。
- [x] 实现 NativeAdapter 工厂与单 Dio Provider，移除代理/竞速及废弃测试和冒烟依赖。
- [x] 缓存 fetchVersion 升级为 2，仅成功结果持久化，保留并发合并和清空屏障。
- [x] 生成测试入口与代码、格式化、相关回归、静态分析及必要平台验证。
- [x] 更新 ADR/错误账本并提交。

## 契约与核查

- dry-run 成功解析 native_dio_adapter 1.8.0 / cronet_http 1.10.1 / cupertino_http 3.1.1，无 Dio 5.11.1 依赖冲突；pub get 完成。Windows 插件链接沿用项目目录联接方案。
- 源码核查位置：native_dio_adapter 的 native_adapter.dart / cronet_fallback_adapter.dart / conversion_layer_adapter.dart；cronet_http 的 android/build.gradle / cronet_client.dart；cupertino_http 的 cupertino_client.dart。具体平台限制见 ADR-081。
- 先运行更新后的缓存契约，旧实现出现 4 个预期失败；新实现的相关 29 项通过。本地 HTTPS 夹具真实握手、证书验证、gzip 解压、3xx/location 和禁止自动跟随测试通过；夹具私钥仅用于 loopback 测试。
- 删除 web_proxy_adapter_test 的插件发现/手写代理契约；其 gzip 和真实传输边界迁入 public_web_tls_test。删除竞速双路径专属契约，保留请求 headers 于 bing_web_research_repository_test，失败后独立请求、超时取消、逐跳安全和大小边界归 web_fetch_limits_test。Provider 测试覆盖同客户端 search/read 和销毁强制关闭。
- 缓存只保存成功，旧 fetchVersion=1 的失败重抓并原位写回 version=2，失败跨重开可恢复；不再提供数据库预占行的跨仓库实例锁。clearAll 排空与同仓库并发合并继续覆盖。
- 真实联网：example.com、dart.dev/overview、baidu.com 阅读及生产 Provider → ObjectBox 持久化全部通过。Bing RSS 冒烟失败（unsupported response），不属于 TLS 400，不改搜索解析或恢复搜索工具。
- Slang/build_runner 成功，产物均位于 lib/gen，ObjectBox 模型 UID 无变化。
- 当前 adb 无连接设备，Apple 运行环境不可用；Android/iOS 真机的系统代理、无 GMS 回退及原生重定向尚未实测。
- Android compileSdk 37 Debug APK 编译成功（GRADLE_USER_HOME=.tools/gradle）；KGP 迁移告警和宿主 Kotlin daemon 临时文件权限告警保留，未修改包源码或全局权限。flutter analyze 零问题。
- 首次全量 848 通过 / 1 失败：上层 message_link_preview_test 仍要求永久失败缓存，已同步为 invalidate 后恢复、成功结果跨重开离线命中的新契约。
- 最终验证：Provider 局部回归通过；默认全量 849/849 通过（141 个同级测试文件）；flutter analyze 零问题；全量 Dart 格式化、git diff --check 通过。外网 Bing RSS 及移动真机限制仍按上文保留，不混入确定性通过数。
