# Android 聊天 Profile 采样

使用专用模拟器。入口复用生产 `main()`、ObjectBox、路由及 UI；首次 `prepare`
向空数据库插入 240 条固定测试消息，完成引导，设置深色/中文/标准档并开启 AI
显示，但不调用模型。发现最新消息不是采样夹具时拒绝准备。不要在个人数据设备运行。

## 构建和连接

Windows 本仓库需要沿用本地工具缓存：

```powershell
$env:PUB_CACHE = "$PWD/.tools/pub-cache"
$env:TEMP = "$PWD/.tools/task-temp"
$env:TMP = $env:TEMP
$env:GRADLE_USER_HOME = "$PWD/.tools/gradle"
$env:ANDROID_HOME = "$env:LOCALAPPDATA/Android/sdk"
$env:ANDROID_USER_HOME = "$PWD/.tools/android-user"
New-Item -ItemType Directory -Force $env:TEMP,$env:ANDROID_USER_HOME
& .tools/flutter/bin/flutter.bat build apk --profile --target-platform android-x64 --no-pub -t tool/profile/chat_profile.dart
adb install -r build/app/outputs/flutter-apk/app-profile.apk
adb shell am start -n com.yidadaa.selfbox/.MainActivity --ez enable-dart-profiling true
adb logcat -d -s flutter
```

从日志取当前 VM service URL，转发对应端口。重启后 URL/端口会变化。
目标 ABI 按实际设备调整；profile 入口拒绝在非 profile 模式运行。

```powershell
adb forward tcp:PORT tcp:PORT
node tool/profile/capture.mjs SERVICE_URL prepare
node tool/profile/capture.mjs SERVICE_URL scroll .tools/mumu-profile/warmup.json
node tool/profile/capture.mjs SERVICE_URL scroll .tools/mumu-profile/run-1.json
node tool/profile/capture.mjs SERVICE_URL scroll .tools/mumu-profile/run-2.json
node tool/profile/summarize.mjs .tools/mumu-profile/run-1.json .tools/mumu-profile/run-2.json
```

`scroll` 从偏移 0 开始，4 次往返到 2400dp，每程 3 秒、线性曲线。
正式比较先预热；不同时运行编译、测试、截图或详细 tracing。统计取真实
`FrameTiming`，保留每帧 UI、raster、totalSpan 和 vsync 时间戳；totalSpan
含排队，不能当成 UI+raster 或显示 FPS。没有帧的 idle 场景百分位为 null。

## 诊断场景

- `idle`：静置 5 秒，检测无交互时是否持续提交帧。
- `keyboard`：8 次输入焦点开关。必须另行核实 IME 可见与 viewInsets，不能仅凭此名称声称测到软键盘动画。
- `typing`：5 次逐字设置测试草稿，再清空；这是 Flutter 编辑状态更新，不包含 IME 候选词与网络延迟。
- `quality OUTPUT_PATH premium` / `theme OUTPUT_PATH light`：设置固定对照环境。
- `trace`：开启 Widget/build、layout、paint 事件；`trace OUTPUT_PATH false` 关闭。
- `traced-scroll`：运行相同滚动并每 2 秒取 timeline，保存 `.segments.json`，避免环形缓冲只保留末尾。

详细 tracing 有额外开销，只用于数调用和定位，不能与关闭 tracing 的耗时比较。
去重 timeline 分段时，按线程、时间戳、名称及 phase 处理；不要直接累加重叠片段。
每次场景先等待 1.5 秒，结束后等待 1.2 秒接收批量帧报告。

采样工具仅在显式 `-t tool/profile/chat_profile.dart` 构建时进入 APK。
正常 `lib/main.dart` 构建不包含此服务扩展。原始日志/APK/trace 放 `.tools/`，不提交。

## 高级档长消息与真实软键盘

`prepare-long` 仅允许替换带 `Profile fixture ` 标记的专用数据，创建恰好 100 条
消息（50 用户 + 50 AI），切到 premium、深色、中文、动画开启。每条 AI 含 16 个
Markdown 段落组。在 360×640dp 模拟器实测正文为 6875dp，生产半屏预览仍保留。
`inspect` 返回档位、消息总数、已挂载正文实测高度、Flutter viewInsets 与 Tab 高度。

`long-scroll` 连续向历史滚动十段，每段目标增加 2400dp、耗时 3 秒，再 4 秒回底；
目标限幅于当时的 maxScrollExtent，历史分页继续使用生产逻辑。
`fast-scroll` 每段耗时 1 秒，其余相同。`traced-long-scroll` 分段保存详细追踪。
`keyboard` 每轮开/关各等待 1 秒，运行 8 轮，保存每个端点的 inset 和 Tab 高度。
检查 `.scenes` 中 open=`280/0/true`、closed=`0/60/false`，不能仅凭名称判断场景有效。

MuMu 的 `com.sohu.inputmethod.sogou.chuizi` 可能实际是 `nemu-vinput-pack` 代理，
即使 mInputShown=true，也会向应用报告 0 高度。`ime/` 提供可复现的最小 Android
InputMethodService（280dp 四行按键、无网络权限、不记录输入），用于验证系统 IME
窗口与真实 inset 动画。它不是搜狗/Gboard 的性能基准，也没有在 Flutter 注入假 inset。

```powershell
& tool/profile/ime/build.ps1
adb install --no-incremental -r .tools/mumu-long/ime/profile-ime.apk
adb shell settings get secure default_input_method
adb shell settings get secure show_ime_with_hard_keyboard
adb shell ime enable com.selfbox.profileime/.ProfileKeyboard
adb shell ime set com.selfbox.profileime/.ProfileKeyboard
adb shell settings put secure show_ime_with_hard_keyboard 1
adb shell am stack list
adb shell am display move-stack ACTUAL_APP_ROOT_TASK_ID 0
```

MuMu 多显示器可能将 IME 放到 display 0；移动当前应用 task 到同一显示器才能收到
inset。task id 每次重启都变，必须重新查询。移动后不要点旧应用 Tab；必要时通过
主显示器截图确认应用与键盘。完成后恢复原输入法及 show_ime_with_hard_keyboard，
卸载 `com.selfbox.profileime`。下一次普通启动由 MuMu 恢复应用独立窗口。

`console OUTPUT_PATH false` 只用于归因实验：临时关闭 Talker 控制台输出，保留
history 与 UI。`console OUTPUT_PATH true` 恢复；正式验证使用默认开启状态。
详细 traced 场景同时导出 `.cpu.json`，仅用于定位，耗时不混入正式结果。
