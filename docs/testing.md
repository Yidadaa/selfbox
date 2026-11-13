# 测试维护指南

## 运行入口

使用项目本地 SDK，在仓库根目录运行：

```powershell
.\.tools\flutter\bin\flutter.bat analyze --no-pub
.\.tools\flutter\bin\flutter.bat test --no-pub
```

业务测试放在被测目录同级的 `__tests__/*_test.dart`。默认回归只有一个入口：`test/all_tests_test.dart`。新增、删除或重命名测试文件后重新生成，禁止手工维护 imports 和注册列表：

```powershell
.\.tools\flutter\bin\dart.bat run tool/gen_all_tests.dart
```

入口自带磁盘注册检查，遗漏新文件或残留已删除文件都会失败。局部回归直接指定文件或目录；多个 Flutter 测试命令串行执行，避免共享编译缓存冲突：

```powershell
.\.tools\flutter\bin\flutter.bat test --no-pub lib/features/chat/presentation/pages/__tests__
.\.tools\flutter\bin\flutter.bat test --no-pub lib/features/settings/presentation/widgets/__tests__/provider_model_flow_test.dart
```

## 测试归属

| 层次 | 负责验证 | 不应重复承担 |
| --- | --- | --- |
| `core/theme` | Token、对比度、主题派生、系统减少动态效果 | 业务保存流程 |
| `core/widgets` | 共享控件的材质、几何、触控区、禁用态、明暗与窄屏布局 | 每个页面再次断言同一 Dialog 的内部圆角和 Padding |
| `domain/models` / `domain/services` | 不变量、校验、纯算法、上下文预算与编排规则 | Widget 内部结构 |
| `data` | 真实序列化、数据库、文件、HTTP、凭证和平台边界 | 仅靠 UI 替身推断持久化正确 |
| `presentation/providers` | 状态流转、失败恢复、并发、取消和日志脱敏 | 公共控件的样式细节 |
| `presentation/widgets` | 组件交互、布局、动效生命周期与可访问性 | 无关页面导航 |
| `presentation/pages` / `core/router` | 真实页面接线、路由、加载/空/错/正常态、业务操作结果 | 已有组件矩阵完整覆盖的纯样式检查 |

组件测试和页面接线测试可以验证同一功能，但必须指出不同故障边界。例如历史预算算法与实际 SDK 请求、URL 校验与 HTTP 重定向、清除服务与 UI 等待屏障均应分别保留。

## 去重与合并规则

1. 比较前置状态、触发操作、断言和失败边界，不能只凭标题、行数或相似代码删除。
2. 删除用例前，将它的独有断言迁入保留用例；在任务文档写明旧位置、保留位置和保留的边界。
3. 相同操作但不同输入使用具名参数矩阵。明暗主题、语言、窄屏、大字、动画起始禁用与中途禁用存在不同风险，不因“看起来相似”裁剪。
4. 将同一流程的互补断言合并到一次执行中；不要把无关业务串成一个长用例，也不要只为降低用例数合并独立错误分支。
5. 公共夹具优先使用 `core/testing/`；局部重复数据与 finder 放同目录的 `*_test_support.dart`。专用于一项测试的替身保留在所属文件，避免把整个测试应用封装进新的泛型框架。
6. 超过 300 行的测试按被测对象或行为拆分，并保留文件级夹具、初始化、清理和注册。文件数不作为优化目标。
7. 每次整合后运行相关回归、静态分析和默认完整回归，核对用例增减及删除断言的归属；通过数不能替代覆盖依据。

当前局部夹具：设置页与设置组件共享 `settings_test_support.dart`；聊天页面共享 `chat_page_test_support.dart` 的消息构造和 Composer finder。

## 动效与异步测试

- 使用 `app_widget_tester.dart` 的手机视口、主题、语言和依赖注入；测试显式恢复平台亮度、文字缩放和视口设置。
- 无限光效、pending 点和流式状态使用 `settle: false` 与固定推进帧，避免等待永不结束的循环。
- 键盘过渡检查中间帧、反向、中途关闭动画及最终布局；真实文件 I/O 用 `tester.runAsync` 推进。
- Toast 用例推进自动退场时间，数据库和临时文件沿用 `temp_storage.dart` 的清理约定。

## 独立工具测试

下面两个入口已纳入测试审计，但不属于默认回归：

| 入口 | 用途与限制 | 命令 |
| --- | --- | --- |
| `tool/screenshots/app_screenshots_test.dart` | 真实字体和页面截图，供人工视觉审查；依赖本机字体，输出在忽略的 `tool/screenshots/out/` | `.\.tools\flutter\bin\flutter.bat test tool/screenshots --update-goldens` |
| `tool/web_research_smoke_test.dart` | 实际请求 Bing RSS 与公开网页，依赖外网可用性；确定性 HTTP/解析/安全测试在 `lib` 中运行 | `.\.tools\flutter\bin\flutter.bat test tool/web_research_smoke_test.dart` |

默认回归不访问真实搜索服务，不将截图生成或外部网络状态当作单元测试门禁。

截图入口使用专用 binding 开启真实模糊阴影；图片夹具预热原图及匹配解码尺寸的缓存，避免把未解码占位或测试默认的硬阴影误判为产品效果。

2026-11-14 的全量审计结果、用例迁移和验证记录见 [任务 63](tasks/63-test-suite-consolidation.md)。


UI 打磨覆盖补充见 [任务 66](tasks/66-ui-polish-and-settings-discoverability.md)：图标断言 HugeIcon 的实际绘制尺寸；玻璃档位以 minimal/standard/premium 矩阵验证预算；关于页五次点击解锁与偏好持久化分属页面和 Controller 边界。Toast 覆盖顶部安全距离、键盘态、滑动关闭、手动幂等关闭及自动退场。截图 `ui-polish-*` 使用真实页面，生成后销毁 Widget 树以清理提示定时器。
