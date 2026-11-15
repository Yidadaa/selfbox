# 架构决策记录 (ADR)

### [ADR-080] 聊天列表局部订阅、逐条虚拟化与有界复用

- **背景**：思考流和键盘动画重建消息列表，连续 AI 讨论以 Column 全组挂载，历史窗口重复读取正文、解析布局和构造消息对象。
- **决策**：列表只订阅 AI 显隐布尔值，活动正文独立消费；AI 开启时将讨论映射为独立列表项，关闭时保留计数摘要。底部避让由反向列表首项消费 ShellScope，顶部只读取 MediaQuery 顶部安全区。时间会话只订阅 items 与路由激活状态。分页使用 `when(skipLoadingOnReload:true)` 保留旧数据与 ScrollController，首次加载才显示骨架；加载中拒绝重复请求。菜单浮层及选区控制器延迟创建，预览保留固定树形，缩略图异步失败后回退原图。Markdown 紧凑布局分类使用 Provider 生命周期内 100 项 LRU，注册表和列表 marker 测量按依赖复用。
- **数据边界**：现有消息只有新增、删除和清空，无原地编辑。ObjectBox 每次仍查询当前窗口的有序 ID，只对缓存缺失 ID 异步读取正文；缓存裁剪到最后窗口，清空时重置。分组复用内容未变的项，删除后重新验证边界。以后新增编辑 API 必须同步失效对应缓存。
- **影响**：保留实时历史删除语义，不改成会遗漏历史删除的静态分页快照。ID 扫描、边界检查和扁平化仍为 O(N)，本轮消除重复正文读取/映射与全组 Widget 挂载，不宣称整条更新链已变为 O(1)。讨论展开不再同时保留两棵整组 AnimatedSwitcher 子树；消息发送动效仍保留。首次 Markdown 分类与渲染分别解析，公开依赖未提供共享 AST 入口；后续分类命中缓存。真机帧率与 GPU 成本仍需 profile 采样确认。

### [ADR-079] 按故障边界收敛测试归属

- **背景**：静态光效、共享浮层与资料合并后，历史测试重复采样或跨层检查公共样式。
- **决策**：共享视觉契约归 core；模型/Schema 回归归 models；页面保留实际接线与重建，Provider 保留并发、失败与日志。删除前对照独有断言，迁移表见任务 89。
- **影响**：保留不同失败源与真实 I/O/SDK/权限边界，不以文件数量为优化目标。当前网页阅读已恢复，以生产 build() 和多轮 SDK 请求作为工具暴露契约；不引用过时暂停记录推导当前行为。

### [ADR-077] 消息链接与持久化网页元数据

- **背景**：用户消息中的链接需要可点击，纯链接显示收藏卡片；成功解析后不得每次进入页面重复请求。
- **决策**：纯函数识别 HTTP(S)/www 链接并保留原文字与标点；普通消息使用 TextSpan 下划线，选区模式关闭点击识别器。纯链接且无附件的用户消息用 standard 玻璃卡片，长按仍进入原消息菜单，选中文本恢复原始 URL。通过 url_launcher externalApplication 调用系统默认处理器，HTTP(S) 链接打开外部浏览器，不做 canLaunch 探测，不新增 Android/iOS 权限。
- **持久化**：ObjectBox 新增独立 LinkPreviewEntity，按源 URL 唯一索引保存最终 URL、标题、摘要、icon URL。先读库，未命中才调用既有网页仓库；成功后写入，失败不缓存为成功。多消费者共享同一请求，清空数据先排空在途写入再清库；原消息正文不变，旧实体 UID 保持稳定。图标文件由 CachedNetworkImage 负责磁盘缓存和限尺寸解码，图标失败回退 Hugeicons。
- **解析与工具**：复用 20 秒超时、2MB 下载上限、重定向/DNS 公网校验及 isolate HTML 提取。标题按 OG/Twitter/title/域名，摘要按 OG/description/Twitter/正文，icon 支持相对地址并回退 favicon。允许仅元数据页面用于卡片，但 web_read 对无正文返回错误。恢复默认 web_read 与提示词说明，web_search 保持关闭，替代 ADR-069 的阅读暂停约定。
- **界面修复**：引用入口、AI 标识、发送时间收敛同一 Row，用 Gap 分隔；引用保留 48dp 点击区。搜索结果复用 MediaStore.resolve 和 ImageViewerRoute，恢复真实图片解码及查看。
- **引用间距修正**：按用户要求与只有时间时保持相同排版，行内 MessageQuoteLink 显式 minSize: 0，不再用 48dp 按钮撑高整行；这是引用文字的紧凑交互例外，仍保留点击、语义、触觉和按压反馈。
- **卡片外观调整**：按用户要求，链接卡片复用普通用户消息的 MessageMineSurface 蓝色背景、尾角轮廓和白字；移除玻璃表面及双行预留高度。域名图标为 16dp，标题和简介各一行省略，行间 Gap 为 4dp，上下内边距为 8dp。缓存、打开浏览器和长按选区行为保持一致。

### [ADR-078] 全局自定义 AI 提示词

- **背景**：AI 配置需要可编辑的全局提示词，每次模型调用均携带。
- **决策**：AiSettings 追加默认空串 customPrompt，沿用已有设置持久化与清空路径；旧配置自动兼容。AI 配置提供强类型全屏编辑路由，ReactiveForm + Luthor 校验最多 12000 字符，可清空，保存按钮固定底部并随键盘避让。@riverpod 控制器负责重复提交、失败状态和草稿保留；复用共享文本字段的可选多行参数。
- **影响**：每个新回合读取当前设置，在系统指令末尾追加一次自定义提示词，同回合多步请求使用同一快照，并计入上下文预算。空白不追加，修改后下一回合生效；不改变内建工具能力。日志过滤 AI 设置与网页预览 Provider，避免输出提示词或网页元数据。首次引导中的 AI 配置也允许进入此页面。

- **2026-11-15 调整**：按用户要求移除独立页面、路由及 AI 配置入口；提示词放入编辑资料页称呼字段之后，固定四行，以当前编辑的 Agent 名称展示“对{agent}的要求”。保留 AiSettings 存储以兼容既有值；ProfileController 的可选 customPrompt 参数负责组合保存，首次引导不传此参数则不修改提示词。资料页同时等待资料和 AI 设置加载，保存失败保留草稿，全部成功后返回。保存按钮固定底部避让键盘。

### [ADR-076] 多消息引用与长回复阅读

- **背景**：消息需要引用多条旧记录并让模型理解关系；长 AI 回复占满聊天视口，多行输入控件居中不便操作。
- **决策**：消息/草稿保存不可变、有序引用 ID 列表，Composer 去重累加；ObjectBox 仅新增序列化 ID 列，不复制正文。卡片下方使用蓝色“引用了 n 条消息”；单条直接进入按 ID 加载的原消息页，多条先在根导航 Sheet 选择。原消息页仅展示选中消息，覆盖未加载和折叠 AI 消息；返回恢复原时间线。列表视口铺满页面，安全区与 toolbar 留白放在列表内容内，滚动时延伸至浮动顶部控件下方，与主聊天一致。Composer 同行左侧显示 Quotes 图标和“引用 n 条”，Sheet 直接响应草稿，使用 trash 图标逐条移除；引用由非空变为空时自动关闭当前 Sheet。
- **影响**：删除原消息不破坏引用关系，界面显示已删除；查询失败可重试。AI 消息和用户消息均带 ID/时间，关系标记进入历史和消息工具；当前问题的原引用按 ID 读取并按 token 预算追加，过长/嵌套引用由 read_messages 读取，图片由已有 view_image 读取，不持久化正文快照。
- **阅读与布局**：按实际 Markdown 布局把 AI 内容限制到半屏，引用脚注计入上限；卡片内不滚动，底部渐隐后以蓝色“展开更多”和右箭头提示完整阅读入口。用户反馈展开转场卡顿后，删除矩形展开与位置参数，全文路由统一 NoTransitionPage，打开与返回均无转场。全文四边内容留白为 32dp，安全区与 toolbar 不加倍，加载态使用相同留白；沿用共享 Markdown/选择菜单，长文“选中文本”进入全文页。输入字段、加号和发送按钮在多行时底对齐，单行基线不变。

### [ADR-074] 完整方形 Logo 作为品牌源图

- **背景**：用户指定 `docs/design/asset-kit/logo/logo-full.png` 作为 App Logo，替换原透明 WebP。
- **决策**：品牌生成器直接缩放完整 PNG，不再执行透明素材去噪。常规 Android、Apple 和 Windows 图标铺满方形画布；Android 自适应前景将整图放入 432px 画布中央的 288px 区域，沿用背景和系统形状遮罩。运行时与双端启动 Logo 同源。
- **影响**：重跑 `dart run tool/prepare_brand_assets.dart` 即可复现全部品牌资源；系统圆形等遮罩仍会裁切方形四角。未调整权限、版本或发布签名。

### [ADR-073] Composer 重建与合成预算

- **背景**：静态 AI 光晕仍有额外 ImageFiltered；键盘进度和 Shell 高度回传重建玻璃；输入全文订阅导致整行逐字测量；非聊天 Dock 升为 premium。
- **决策**：光晕直接绘制既有径向渐变，由输入玻璃保留背景模糊；键盘进度仅由玻璃内部内容消费，Shell memoize Dock，独立 RepaintBoundary 隔离绘制。附件以 blur/tint 和图标透明度过渡，不再对整个玻璃层套 Opacity，最高 standard；非聊天 Dock 同样最高 standard，minimal 保持降级。输入行仅订阅 canSend，编辑字段局部 hook 只响应多行布尔变化；缓存并释放 maxLines:1 TextPainter，空文本/显式换行/仅选区和 composing 变化跳过测量，宽度/字体/缩放/方向变化重新计算。
- **影响**：更新 ADR-065 的全文驱动整行布局和 ADR-071 的光晕实现。软换行仍使用精确字体排版，不做字符数估算，也不宣称完全消除逐字测量；光晕和附件中间帧不承诺像素完全相同。保留独立玻璃层以保障前后景关系，AI 开关保留浮动 chrome 预算。结构测试与截图不替代真机 GPU 帧时间测量。

### [ADR-045] AI 错误气泡使用正文内联操作

- **背景**：配置缺失与请求失败的恢复动作排在气泡外，独立触控高度与小号按钮字体使错误状态排版割裂。
- **决策**：错误说明、去设置/重试及关闭统一放进气泡内的同一 Text.rich 段落；操作使用 baseline 对齐的 WidgetSpan + 无内边距 TextButton，沿用正常 AI 消息正文样式和固定正文 strut，自然换行。行内按钮按本次交互要求使用文字高度，WidgetSpan 负责字体缩放，内部 Text 避免重复缩放。
- **影响**：恢复设置、重试当前问题和关闭错误的行为不变；不再显示气泡外按钮或关闭图标。测试与真实字体截图覆盖明暗主题、中英文、280dp 大字换行和基线。

### [ADR-044] 短时记忆按模型上下文百分比分配

- **背景**：固定历史消息数量无法反映模型上下文大小或长短消息的实际成本，需要按当前模型的容量调整短时记忆。
- **决策**：以 `shortTermMemoryPercent` 保存 10–60 的整数百分比，默认 20；预算为模型完整 `maxInputTokens × percent ~/ 100`，不先扣除输出再计算比例。旧 `historyTurns` 不具备等价换算，读取时忽略并使用 20%，其余设置保留；持久化仅写新字段，越界新值在解码及编辑时归一化。Sheet 第一行是 1% 步进的 standard GlassSlider 和当前百分比，第二行仅用居中的大号数字显示实时 token 预算，未选择模型时显示未设置；取消、保存位于底部两个等宽列。滑块草稿经 reactive_forms + Luthor 校验，仅保存时落盘。
- **影响**：Agent 每批读取 64 条、按时间与 ID 倒序连续累加，下一条放不下即停止，不再限制总消息数；当前问题去重后始终保留，禁止混入问题之后的新消息。简单估算按每 3 个 ASCII 字符约 1 token、每个非 ASCII BMP 字符约 1 token、每个增补字符约 2 tokens 累加取整，每条另计 8 tokens 的消息封装；用户文本含时间/ID/附件标记，AI 文本不加用户前缀。历史目标包含当前问题，并受扣除系统文本和输出预算后的剩余空间约束；发送前恢复时间顺序、合并同角色消息，保留原协议兼容处理。截图和测试覆盖模型容量变化、精确边界、跨批次、失败、明暗主题与窄屏。

### [ADR-043] Agent 步骤与回复固定左锚点

- **背景**：思考与工具卡宽度不同，默认居中的 AnimatedSwitcher 在旧卡移除时使新卡横跳；最终回复还沿用了用户发送的右侧入场轨迹。
- **决策**：状态切换的叠放和尺寸动画统一左下对齐，保持 560ms 淡化与主题定义的纯纵向位移。已持久化的 AI 回复采用同一左下锚点和纵向位移，用户消息保留原发送轨迹。消息行的入场配置与长按操作独立到 ChatTimelineMessageRow。
- **影响**：新旧状态同时存在及快速打断时均不得改变左边缘；测试按 16ms 采样真实表面坐标，覆盖明暗主题、中英文、280/390dp 和最终回复，截图夹具保留切换中间帧供复查。替代 ADR-038 中未明确锚点的切换约定。

### [ADR-042] Header、Dialog 与 AI Composer 光晕契约

- **背景**：标准标题横向撑满且与按钮大小不一致，弹层取消/删除描边突兀；AI 彩边包住开关和附件，在键盘开合时偏离输入玻璃。
- **决策**：标准标题按文本取宽、固定 48dp，页面图标按钮统一 48dp。共享动作改用无描边的轻柔填充，删除使用淡红语义。AI 标识改为输入 + Tab 玻璃背后的四团淡彩光晕，按同一 `LiquidShape` 裁切，开关/附件预览在外；12 秒循环中珊瑚暖色始终保留在左侧。光晕以 700ms 渐显/旋转放大入场、500ms 退场，玻璃 tint 同步插值。浅色模式以同一形状绘制 1dp 白细边，暗色只保留库自带高光。AI/AI 待命使用 400ms 位移淡化与宽度过渡。
- **影响**：替代 ADR-038 的彩色描边与 ADR-041 的动作按钮描边；动画只重绘独立背景层，关闭 AI 时停止循环，减少动态效果时使用静态光晕。测试覆盖动画反转、区域裁切、16 个相位的暖色保留、键盘/失焦/多行输入与明暗主题。

### [ADR-034] Markdown 子级标记与父级正文对齐

- **背景**：默认列表在已缩进的正文内再次按层级增加 24dp，四级列表在手机消息气泡内可溢出，且两位编号导致同级正文错位。
- **决策**：通过 `flutter_smooth_markdown` 公开的 `BuilderRegistry` 统一覆盖 list 布局；子级标记左边缘对齐父级正文起始位置，标记与正文间距使用主题 Token。同级编号按实测最宽标记统一右对齐，内联正文继续调用库的渲染器，保留加粗、链接与任务勾选状态。
- **影响**：AI 消息、思考串流、记忆阅读及编辑预览使用同一 builder；不修改 pub cache、不替换 Markdown 引擎，运行中字体缩放和主题变化会重新计算标记宽度。

### [ADR-035] 历史图片浏览与媒体压缩

- **背景**：图片查看器只在当前消息的图片间切换，缺少历史缩略图导航；原图直接入库会增大本地存储和视觉模型请求负担。
- **决策**：消息仓库按时间升序提供去重后的全部历史图片路径；查看器以懒构建 PageView 浏览，并提供可横向滚动的懒构建缩略图栏。MediaStore 在 isolate 中按方向修正并将长边限制到 2048px，以 JPEG quality 85 保存模型使用的主图，同时生成长边 320px、quality 70 的 `.thumb.jpg` 旁车文件；删除图片时一并删除旁车文件。
- **影响**：数据库仍只保存主图相对路径，不需要 ObjectBox schema 迁移；旧图片没有缩略图时，预览栏回退为解码主图。无法解码的格式或损坏图片返回校验失败，不会写入半成品。缩放后的主图供 AI 图片读取路径复用。

### [ADR-036] Chat Shell 玻璃层预算

- **背景**：Chat 页面和 Shell 重复创建 `GlassScaffold`，且固定头像、导航按钮、AI 开关与键盘附件按钮使用 premium，Debug/Profile 下会触发多层高成本玻璃渲染与性能监控。
- **决策**：Shell 只负责画布、分支栈和浮动停靠区，不再额外创建 `GlassScaffold`；页面保留自己的 scaffold 和顶部渐隐。Chat 固定控件使用 standard，premium 留给独立悬浮操作。
- **影响**：Chat 首屏应只有一个 `GlassScaffold`；其顶部滚动边界由页面自身控制。独立图片查看器关闭按钮仍可使用 premium。

### [ADR-033] 底部 Dock 使用主题化 Chrome 玻璃层

- **背景**：聊天输入框和 Tab 停靠区过于透明，消息滚动到其下方时前后景对比不足。
- **决策**：输入表面与 Tab Dock 使用独立 `GlassContainer` layer，继续采用 standard 质量，并从当前 `AppGlassTheme` 读取更强的 `chromeBlur` 和亮度专属 `chromeTint`。
- **影响**：浅色使用高不透明度白色遮罩，深色使用高不透明度深色遮罩；两种遮罩都维持前景文字 AA 对比度。仅固定底部控件增加模糊层，滚动消息卡片不增加 shader。

### [ADR-032] 已添加模型的真实可用性探测

- **背景**：模型目录可拉取不代表某个模型可调用；用户需要在配置面板中直接确认服务商密钥与模型请求是否可用。
- **决策**：配置面板提供“测试模型”，从当前设置重新读取已启用模型和系统密钥，经现有 SDK 模型工厂发起一次不带工具的短文本请求；20 秒超时、不重试，成功或失败都释放客户端。探测结果仅作为面板临时状态展示，不保存回复、聊天消息或设置。领域层通过 `ModelProbe` 隔离网络，顶层 Riverpod Provider 组合设置仓库与聊天模型工厂，避免设置页面引用其他 Feature 的内部实现。
- **影响**：测试成功表示该模型完成一次实际请求，不代表所有能力（图片、思考）均可用；接口错误和缺失密钥按现有本地化故障文案显示。探测会产生一次服务商 API 请求。

### [ADR-031] 服务商目录与已添加模型分离

- **背景**：自动拉取的全部模型直接堆在服务商页面，目录较长时难以查找，也无法区分可用模型与用户已配置模型。
- **决策**：保存新服务商后拉取目录，但页面初始只展示已添加模型（0 个）。未添加模型留在目录中，通过带搜索、多选和懒构建列表的半屏面板批量启用；首个启用模型自动成为当前模型。已添加行可快速设置图片、思考与等级，名称打开半屏配置上下文预算和删除。删除只关闭模型，目录项保留以便重新添加。
- **影响**：目录刷新保留已启用模型配置与上游临时缺失的已启用项；选择器和配置面板使用随明暗主题变化的不透明表面，确认删除仍走项目自有 Dialog。目录合并用集合成员查找，避免长目录平方级扫描。

### [ADR-029] 项目自有 Dialog 作为唯一模态操作表面

- **背景**：消息、记忆和服务商操作仍通过 GlassActionSheet 呈现，而清除数据已使用不透明自有 Dialog；不同弹层的渲染成本与布局不一致。
- **决策**：确认操作统一使用 `AppConfirmDialog`，多操作菜单使用 `AppActionDialog`，两者共用不透明主题表面、34dp 圆角和 48dp 胶囊按钮。移除业务代码中的 GlassActionSheet；选择器继续使用 Bottom Sheet + Picker。弹窗文案在打开前读取，避免页面卸载后 builder 再访问旧 context。
- **影响**：业务页面不得调用 Liquid Dialog / GlassActionSheet 或直接构造其他 Dialog。新增模态操作样式先扩展项目自有组件并测试明暗模式、取消与确认行为；保留现有 Bottom Sheet 选择器。

### [ADR-030] 顶部渐隐由共享页面组件绘制

- **背景**：`GlassScaffold` 的顶部渐隐优先使用异步捕获的背景纹理，主题色参数只用于回退；运行中切换明暗主题时可能短暂显示旧浅色纹理。
- **决策**：`AppPageScaffold` 关闭依赖库的顶部边缘效果，并在全屏滚动内容上方、玻璃标题栏下方绘制取自当前 `AppGlassTheme.canvasGradient.first` 的渐隐；高度沿用安全区、标题栏和 20dp 延伸，且不拦截触控。
- **影响**：主题切换直接触发渐隐重绘，不依赖纹理捕获时机；页面内容继续在标题栏下滚动，玻璃背景采样和其他控件保持原有路径。

### [ADR-022] 设置确认使用原生白色弹层

- **背景**：清除数据确认的全屏 glass action sheet 使用自有渲染层，弹出时有明显卡顿及文字装饰异常；历史轮次更适合连续数值选择。
- **决策**：清除确认使用白色 `AppConfirmDialog`，保持 34dp 圆角和确认/取消语义。布局沿用 Liquid Dialog 的 320dp 宽度、左对齐标题、16dp 操作区边距及两个等宽 48dp 胶囊按钮；文案放不下时纵向排列，内容过高时可滚动。历史轮次使用白色 `ModalBottomSheet` 与 `CupertinoPicker`，可选 0–100 并仅在保存时写入。
- **影响**：这两个设置流程不依赖 Liquid Glass shader；清除确认显式关闭文字装饰，选择器支持保存与取消。

### [ADR-021] 聊天顶部资料入口与消息搜索

- **背景**：聊天顶部需要呈现个人资料身份，并提供设置和消息历史的快捷入口。
- **决策**：聊天页顶部使用左右 premium 玻璃图标按钮及中心纵向头像 / 昵称控件；56dp 圆头像绘制在较小字号的昵称玻璃胶囊前方，两者重叠且整体居中可点击。聊天滚动视口从屏幕顶部开始，初始内容用顶部内边距避让头像栏，滚动时可透过玻璃按钮。资料进入根 Navigator 的资料编辑页，设置切换到 Me 分支，搜索进入根 Navigator 的独立页面并调用既有 `MessageRepository.find`。
- **影响**：消息搜索沿用 `MessageQuery` 的分词匹配并限制最多 100 条；空查询不读取全量历史。顶部视觉仍由共享 `AppPageScaffold` 承载，通过可选 `titleContent` 定制中心区域。

### [ADR-016] 首页输入与导航共用完整 Liquid 表面

- **背景**：首页原有输入框与 Tab 是两条独立悬浮栏；参考 ref-chat / ref-input 要求收起时合并、键盘打开时拆分。
- **决策**：Shell 统一持有 ChatComposer 与 AppDockTabs、实测停靠区高度，并通过 ShellScope 向页面传递底部避让。导航通过 Widget 插槽放入 GlassTextField.bottom，共用一层玻璃；键盘态隐藏导航并分离附件按钮。当前 liquid_glass_widgets 1.17.2 的 full shader 管线名为 GlassQuality.premium，底座、输入框、AI 胶囊、附件按钮显式使用该档位。
- **影响**：聊天页不再计算第二份键盘/导航偏移；bottom 插槽常驻、输入组件 Key 稳定以保留焦点与选区。输入最大高度扣除安全区、标题、键盘与附件，时间线跟随实测高度。Tab 保持 go_router 分支切换，不引入业务状态或新依赖。

### [ADR-017] ObjectBox 模型 JSON 必须参与构建输入

- **背景**：UI 任务的代码生成门禁发现 `lib/gen/**` 的排除规则令 ObjectBox 无法读取已提交模型，重新生成了实体与属性 UID。
- **决策**：恢复原模型，排除范围改为 `lib/gen/**/*.dart`；模型 JSON 保持为 source input。
- **影响**：生成代码仍全部输出至 lib/gen；无数据库结构改动时，objectbox-model.json 的 UID 必须保持不变。

### [ADR-001] Flutter 工具链本地化至 `.tools/`

- **背景**：机器上已有全局 Flutter（`C:\dev\flutter`），版本可能与项目要求漂移；需要可复现、项目私有的工具链。
- **决策**：Flutter stable（当前 3.47.9 / Dart 3.13.7）解压至 `.tools/flutter`，`.tools/` 加入 `.gitignore`。所有命令通过 `.tools/flutter/bin/flutter` / `dart` 执行，或先 `export PATH="$PWD/.tools/flutter/bin:$PATH"`。
- **影响**：升级 Flutter = 替换 `.tools/flutter` 目录并更新本 ADR；CI 需按同一版本安装。

### [ADR-002] 所有生成代码收敛至 `lib/gen/`

- **背景**：`*.g.dart` / `*.freezed.dart` 散落在业务目录会污染代码审查与搜索。
- **决策**：
  - `build.yaml` 用 `build_extensions` 把 `freezed` 与 `source_gen|combining_builder`（json_serializable、riverpod_generator、retrofit_generator 等）映射到 `lib/gen/{{}}`；`sources` 排除 `lib/**/__tests__/**` 与 `lib/gen/**/*.dart`，保留 ObjectBox 模型 JSON（ADR-017）。
  - `flutter_gen` → `lib/gen/assets/`；`objectbox` → `output_dir: gen/database`；`slang` → `lib/gen/i18n/`。
  - 业务源码的 `part` 用相对路径指向 `lib/gen/...`。
- **影响**：每次 `build_runner` 后必须确认 `lib/gen/` 之外无生成文件；`lib/gen/` 提交进版本库还是忽略见 ADR-005。

### [ADR-003] 测试与被测代码同级放在 `__tests__/`，`test/all_tests_test.dart` 作为唯一聚合入口

- **背景**：Flutter 工具链默认只扫描 `test/`，而规范要求测试与代码同级。
- **决策**：测试写在 `lib/**/__tests__/*_test.dart`；聚合入口命名为 **`test/all_tests_test.dart`**（偏离 AGENTS.md 的 `all_tests.dart`：`flutter test` 只收集 `*_test.dart`，否则裸跑 `flutter test` 找不到任何用例）。它以 `import ... as tN;` 引入每个测试文件并在 `main()` 中 `group(path, tN.main)`，末尾自带「注册表 == 磁盘扫描」守卫测试。`tool/gen_all_tests.dart` 扫描目录重写该文件并 `dart format`。`analysis_options.yaml` 关闭 `depend_on_referenced_packages`。共享测试夹具在 `lib/core/testing/app_widget_tester.dart`（390x844 视口、刘海/横条安全区、固定语言、完整 Provider + Glass 作用域）。
- **影响**：新增测试文件后运行 `dart run tool/gen_all_tests.dart`，遗漏时守卫测试会失败；单个测试可直接 `flutter test lib/.../__tests__/x_test.dart`。`@visibleForTesting` 成员（如 `ProviderContainer.test`）在 `lib/**/__tests__` 中会被 analyzer 报警，改用 `ProviderContainer(...)` + `addTearDown(container.dispose)`。测试代码未被 `main.dart` 引用，会被 tree-shaking 剔除。

### [ADR-004] Pragmatic Feature-First 分层，拒绝透传 UseCase

- **背景**：教条式 Clean Architecture 会产生大量一行透传类。
- **决策**：Presentation 的 `@riverpod` Controller 直接调用 Domain `Repository` 接口；仅跨多个 Repository 的编排或可复用领域算法才进入 `domain/services/`。仅在架构边界（Repository、平台网关）定义 `abstract interface class`。
- **影响**：Code review 时拒绝单方法透传类与单实现内部接口。

### [ADR-005] `lib/gen/` 不纳入版本库

- **背景**：生成文件体积大、易产生无意义的合并冲突，且可由工具链完全重建。
- **决策**：`lib/gen/` 写入 `.gitignore`，例外：`lib/gen/database/objectbox-model.json` 必须提交（ObjectBox 依赖它保持实体/属性 UID 稳定，丢失会导致 schema 迁移错误）。
- **影响**：clone 后必须先执行 `dart run slang && dart run build_runner build` 才能编译（build_runner 2.16 已移除 `-d`）。

### [ADR-006] Liquid Glass 统一设计 Token

- **背景**：Android 与 iOS 共用一套视觉，禁止 `Platform.isIOS` 分叉；业务组件禁止硬编码间距/圆角/模糊/时长。
- **决策**：`lib/core/theme/` 定义 `AppSpacing`（4/8/12/16/20/24/32/40/48）、`AppSizes`（48dp 触控热区、AppBar 高度、图标尺寸）、`AppRadius`（含同心圆角 `concentric(outer, padding)`）、`AppMotion`（按压 0.97 / 120ms / easeOutCubic）、`AppGlassTheme`（`ThemeExtension`，承载三层景深的模糊/透明度/描边）。`AppTheme.dark()` / `AppTheme.light()` 挂载全部扩展；全局 `AppScrollBehavior` 统一 `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`；全平台统一 `GlassPageTransitionsBuilder` 转场。页面统一用 `GlassScaffold` + `AppCanvas`（渐变画布），刷新式玻璃控件（`GlassButton`）不得嵌套在玻璃卡片内。
- **影响**：新增视觉参数一律先加 Token 与对应 `__tests__` 断言，再在组件中引用。

### [ADR-007] ObjectBox 使用 6.0.0-preview.6（精确锁定）

- **背景**：ObjectBox 稳定版 `objectbox_generator` 5.3.2 依赖 `analyzer <11`，而 freezed 4 / json_serializable 6.15 / build_runner 2.16 / riverpod_generator 4 要求 `analyzer ^14`，版本求解无解。
- **决策**：`objectbox` / `objectbox_flutter_libs` / `objectbox_generator` 精确锁定 `6.0.0-preview.6`（支持 `analyzer <14.5`，因此 analyzer 解析为 14.4.0）。不降级其余代码生成器。
- **影响**：ObjectBox 6 稳定版发布后立即升级并移除精确锁定；首个 `@Entity` 落地时需验证 preview 的生成产物、`objectbox-model.json` 与 Store 打开流程，并补齐临时目录 Store 测试。

### [ADR-008] 依赖版本受上游约束的已知滞后

- **背景**：要求使用最新版本，但部分包被上游约束卡住。
- **决策**：接受以下滞后，不引入 `dependency_overrides`：`cached_network_image` 3.4.1（`flutter_smooth_markdown` 要求 `^3`）；`talker_flutter` 5.1.16 与 `flutter_secure_storage` 10.x（`screen_capturer_windows` 要求 `win32 <6`）。其余直接依赖均为当前最新可解析版本。
- **影响**：上游放开约束后执行 `flutter pub outdated` 复查并升级。

### [ADR-009] i18n 关闭延迟加载 (`slang.yaml: lazy: false`)

- **背景**：slang 默认将非基准语言生成为 deferred library，`LocaleSettings.useDeviceLocaleSync()` / `setLocaleSync()` 对 zh-CN 直接抛 `_DeferredNotLoadedError`，中文设备启动即崩溃。
- **决策**：`lazy: false`，所有语言随主包加载（文案体积极小）。
- **影响**：若未来语言包体积显著增大，再改为异步 `useDeviceLocale()` 并在启动流程中 `await`。

### [ADR-010] v0 数据存储布局与测试替身

- **背景**：消息、图片、记忆文件三类数据需要可测试、可迁移，且 ObjectBox 原生异步查询在 widget 测试的 fake-async 区中无法完成。
- **决策**：所有持久化数据位于 `AppPaths.root`（应用支持目录下 `selfbox/`）：`objectbox/`、`media/`（消息图片，库内只存 `media/<uuid>.ext` 相对路径）、`memory/`（agent 记忆 Markdown 树）。`appPathsProvider` / `appStoreProvider` 在 `main()` 中覆写。Repository 层测试用临时目录真实 Store（需 `dart run tool/fetch_objectbox_native.dart` 下载宿主库）；Widget / Provider 测试用 `FakeMessageRepository`（`lib/core/testing/`）。
- **影响**：路径必须经 `MediaStore.resolve` 校验，拒绝越界（模型工具参数可控）；设计评审截图通过 `flutter test tool/screenshots --update-goldens` 生成到 `tool/screenshots/out/`（不入库）。

### [ADR-011] AI 服务商配置与密钥存储

- **背景**：需支持 chat completions / responses / messages 三种接口格式，可拉取并逐个配置模型；API Key 属敏感凭据。
- **决策**：`AiSettings`（服务商、模型能力与预算、当前模型、历史轮数）以 JSON 存于 `config/ai_settings.json`（先写临时文件再 rename 保证原子性）；API Key 仅存系统钥匙串（`SecretStore` → `flutter_secure_storage`），表单从不回显，留空即保留。模型列表经 Retrofit `GET {baseUrl}/models` 拉取（OpenAI 用 Bearer，Anthropic 用 `x-api-key` + `anthropic-version`），合并时保留已有配置，上游消失但已启用的模型不删除。Dio 日志不打印请求头与请求体。表单规则以 luthor Schema 定义于领域层（`AiSettingsSchema`），经 `luthorValidator` 接入 reactive_forms。
- **影响**：`AiSettingsService`（跨设置仓库与模型目录的编排）是唯一写入口；新增接口格式需同时扩展 `ApiFormat`、鉴权头映射与语言模型工厂。

### [ADR-012] AI 模式 Agent 设计

- **背景**：AI 模式需在全部聊天记录上检索作答、维护文件式记忆；UI 只显示最新工具调用与“正在输入”，最终文本整体渲染。
- **决策**：`AssistantAgent`（`chat/domain/services`）用 `ai_sdk_dart` `streamText` 多步工具循环（`maxSteps: 16`，总超时 3 分钟）。工具：`search_messages` / `read_messages` / `view_image`（仅视觉模型）/ `memory_list` / `memory_read` / `memory_search` / `memory_create` / `memory_patch`（强制 unified diff）/ `memory_delete`；工具失败以 `{"error"}` 返回给模型自行纠正。历史为最近 `historyTurns+1` 条消息（用户笔记带 `[#id 时间]` 前缀、AI 为 assistant，同角色合并、首条必为 user），按 `maxInputTokens - maxOutputTokens` 粗估裁剪。`view_image` 的图片经 `prepareStep` 在工具结果后注入一条 user 图片消息（工具结果只能携带文本）。流事件仅用于状态：`ToolInputStart` → 工具类别，首个 `TextDelta` → typing；最终取最后一步文本一次性入库为 AI 消息。`AssistantController` 状态机 `idle → working(activity) → idle | failed(failure, question)`，新问题取消旧问题且旧回复不入库。`LanguageModelFactory` 为网络边界（测试用 `ScriptedLanguageModel`）。
- **影响**：新增工具需同步 `AgentToolKind.ofTool` 与状态文案；widget 测试中 SDK 流需 `tester.runAsync` 交替推进。

### [ADR-013] 平台权限：相册

- **背景**：笔记可附图片（`image_picker`，仅从相册选择）。
- **决策**：iOS `Info.plist` 声明 `NSPhotoLibraryUsageDescription`（未声明会在首次选图时崩溃）。Android 使用系统 Photo Picker，无需运行时权限与 Manifest 声明，双端行为对等：均为用户点击图片按钮时才弹出系统选择器（Just-in-Time）。macOS 选图走系统打开面板，沙盒 entitlements 待桌面端需要时补充。
- **影响**：新增相机拍照时需同时补 `NSCameraUsageDescription` 与 Android `CAMERA` 权限并更新本 ADR。

### [ADR-014] Android 构建：compileSdk 37 / AGP 9.5.1 / Gradle 9.6.0

- **背景**：`permission_handler_android` 14.x 要求以 API 37 编译；SDK 仅提供 `platforms;android-37.0`，模板自带 AGP 9.1.0 无法解析 `compileSdk = 37`，且 app 端还需 compileSdk ≥ 37。
- **决策**：AGP 升至 9.5.1（随之 Gradle wrapper 升至 9.6.0），`android/app/build.gradle.kts` 固定 `compileSdk = 37`（targetSdk 仍跟随 Flutter 默认）。新增 `cupertino_icons`：liquid_glass_widgets 内部引用 Cupertino 图标字体，缺失会显示方块。
- **影响**：Flutter 默认 compileSdk 升到 ≥37 后可改回 `flutter.compileSdkVersion`。Release 包暂用 debug 签名，发布前需配置正式签名。

### [ADR-015] Android release：正式签名、网络权限、仅声明用到的权限

- **背景**：要装到真机长期使用；debug 签名的 APK 日后换正式签名只能卸载重装，会丢失本地笔记与记忆。模板 release manifest 缺少 `INTERNET`；`record` 插件合并进 `RECORD_AUDIO`，v0 并不录音。
- **决策**：release 用本地私钥签名：keystore 在 `%USERPROFILE%/.selfbox-signing/selfbox-release.jks`，`android/key.properties`（已 gitignore）提供路径与密码；缺少该文件时回退 debug 签名以保证新克隆可构建。主 manifest 声明 `INTERNET`，并以 `tools:node="remove"` 移除 `RECORD_AUDIO`，录音功能落地时再按 Just-in-Time 恢复并更新本 ADR。真机为 arm64，用 `--target-platform android-arm64` 构建（只打 x86_64 时插件仍会塞入不完整的 arm64 目录，arm64 设备启动即崩溃）。
- **影响**：keystore 与密码丢失后将无法覆盖安装更新——务必备份 `.selfbox-signing/` 与 `android/key.properties`。

### [ADR-018] 消息相册与个人资料 / 数据重置边界

- **背景**：聊天需要 iMessage 蓝色气泡、内置时间与多图堆叠；个人设置增加资料、存储与独立 AI 页面。
- **决策**：图片消息限制单图 224×180dp，最多绘制 3 张堆叠卡片，保留完整相册并通过 PageView 浏览。发送蓝色使用 #006FE6 保持白字 AA 对比度。个人资料存 ObjectBox 独立 ProfileEntity，头像存 media 相对路径。存储重置由 core 组合边界等待 composer、取消并排空 AI 回合、等待设置写入后，调用跨仓库领域服务清除密钥、配置、消息、记忆、资料和图片。
- **影响**：不删除正在打开的 ObjectBox 目录，统计明确包含预分配空间；清除失败可重试。子页面使用强类型路由，资料 / 存储 / 关于覆盖底部栏。版本从 package_info_plus 读取安装包元数据。玻璃控制与分组使用 premium（full）管线。

### [ADR-019] 固定控件玻璃预算、二级页与 Agent 调用日志

- **背景**：输入栏与 Tab 边距不统一，部分二级页仍显示 Tab；设置列表和表单的 full 玻璃层过重，Agent 调用缺少可查看的轨迹。
- **决策**：停靠区统一 16dp 左右与安全区外底距，输入行用标准玻璃表面和垂直居中的文本框；仅独立悬浮按钮使用 premium，固定表单按钮、分组和导航表面使用 standard。所有二级路由由根 Navigator 覆盖底部栏。Agent 回合与工具状态写入全局 Talker，设置提供 TalkerScreen 入口。
- **影响**：日志只含回合编号、消息 ID、工具名和状态，不记录正文、工具参数、结果或密钥；Talker 历史仅在当前进程保留。本文更新 ADR-018 中原先的 premium 范围。
- **输入基线补充**：聊天正文与 placeholder 从同一 bodyLarge 派生并显式统一 alphabetic，避免中文主题 ideographic 与 RenderParagraph 基线实现差异导致提示下移；不改变全局中文排版。
- **键盘态尺寸补充**：分离的附件圆钮与单行输入面统一 48dp；输入面移除上、下、右额外 padding，保留左侧文字内边距、发送热区与多行自然增长，并按实际 padding 计算编辑高度预算。发送圆形 36dp 位于 48dp 热区中央，单行时上、下、右可见留白均为 6dp；测试测量实际圆形边缘，不能只比较热区或中心线。
- **收键盘时机补充**：ChatComposer 通过 useListenable 响应 FocusNode；仅在键盘存在且输入持有焦点时使用编辑布局，失焦立即启动导航展开。高度预算与 Shell 底部定位仍消费实际 inset，避免收起期间提前忽略键盘；键盘归零不再二次展开导航，重新聚焦可直接恢复编辑布局。
- **表面与底部画布更新**：AI 消息与图片框使用无阴影的纯白 RoundedSuperellipse 卡片，不执行 Liquid Glass shader；我方消息保留蓝色气泡，发送按钮沿用同一 bubbleMine token。footer 使用单独更低不透明度 token。浅色全局画布渐变保持底部暖白色终点。

### [ADR-020] 消息元信息外置与图片轻玻璃框

- **背景**：时间 / AI 标记需要显示在气泡外底部；图片不再被发送方实色消息背景包裹。
- **决策**：MessageBubble 按消息方向排列独立图片堆叠、可选文字气泡和单一 footer；元信息统一使用 foregroundMuted。图片每层采用 standard GlassContainer、4dp 内边距与 16dp 外圆角 / 12dp 内圆角，通过测试锁定默认圆角契约；堆叠区域使用 RepaintBoundary。
- **影响**：图文消息的文字单独显示为气泡，footer 位于整条消息内容底部；纯图片无实色气泡。保留最多 3 层堆叠、完整张数、预览与长按。本决策替代 ADR-018 的气泡内时间布局。
- **AI 表面补充**：AI 文字 / 图片说明使用 GlassContainer、GlassQuality.standard 与 MessageTokens.radius 圆角，无旧 bubbleOther 实色衬底；外层 RepaintBoundary 隔离滚动重绘。玻璃材质继承主题，正文沿用主题前景色，footer 在容器外。用户发送气泡仍采用蓝色连续尾部轮廓。

### [ADR-021] 非玻璃表面跟随系统明暗模式

- **背景**：消息卡片与弹层为性能改用不透明表面后，固定白色在深色模式下刺眼；GlassScaffold 的顶部滚动过渡未收到画布颜色，回退色可能与背景不符。
- **决策**：AppGlassTheme 定义 AI/图片实色表面及对比文字、Dialog 操作填充色和危险操作色，按亮度切换。AppPageScaffold 的顶部过渡最终由 ADR-030 接管。确认 Dialog 与模型/历史轮次 Picker Sheet 保持原布局与圆角，但底色、文字和选中背景取主题 Token；两类 Picker 共用布局。
- **影响**：浅色模式 AI/图片卡片仍为纯白，深色模式使用不透明深灰蓝；弹层不启用实时模糊。新增非玻璃表面必须从主题取颜色并覆盖双模式测试。

### [ADR-022] 设置流程的统一 Liquid Surface

- **背景**：设置列表的玻璃分组默认 12dp 圆角，服务商详情的 solid 分组默认为 26dp 且浅色模式呈纯白，跨页视觉不一致。
- **决策**：设置、服务商与模型配置中的卡片和分组统一使用默认 `GlassSurfaceStyle.glass`、`GlassQuality.standard` 与 `AppRadius.lg`（28dp）圆角；输入控件仍采用独立的内嵌表面。
- **影响**：这些页面的卡片继续继承全局明暗玻璃主题；后续新增设置分组须沿用相同材质与圆角。

### [ADR-023] 首次欢迎与用户记忆

- **背景**：空聊天与空记忆的占位卡片缺乏引导；用户需要直接维护记忆文件。
- **决策**：消息库为空时仅在 UI 渲染三条临时 AI 气泡，不写入数据库或 Agent 历史。启动时在记忆仓库创建根目录 `user.md`，资料保存后仅同步其开头的姓名状态句，保留其他内容；完整改写过的文件不再自动覆盖。Agent 每轮提示词读取当前资料和应用语言，并提供本地时间、时区与简短对话风格。手动编辑使用 `SmoothMarkdownEditor`，仓库 `replace` 比较打开时原文，以拒绝并发覆盖。
- **影响**：清除全部数据后立即重建无昵称的 `user.md`；编辑页固定打开时的原文作为并发校验基准，冲突时保留草稿并提示重新打开文件。记忆新增入口浮于 tab 栏上方，编辑页由根路由覆盖 tab。

### [ADR-024] Agent 单行实时预览与日志边界

- **背景**：固定“思考中”与跳动圆点无法表明 Agent 是否持续运行；流状态进入 Riverpod 日志会暴露推理与回复片段。
- **决策**：仅将推理和回复流的最新逻辑行作为有界临时状态展示，换行与工具/步骤切换丢弃旧片段；状态气泡用纯文本横向尾随视图与连续轻动效，同阶段 token 更新不重启动画。最终完整答复仍只在回合成功后入库。应用层 Riverpod 观察器排除 `assistantControllerProvider`，手写的回合和工具元数据日志继续保留。
- **影响**：实时片段只存在于当前 UI 状态，不写入消息库或 Talker；新增 Agent 状态字段时须保持日志过滤测试。

### [ADR-025] 已发送消息的时间线入场动效

- **背景**：发送成功后气泡立即出现在倒序列表中，缺少从输入区进入时间线的连续反馈。
- **决策**：Composer 仅在持久化成功后发布新消息 ID；聊天列表只给该 ID 的行加 360ms 高度展开、右下方上滑、淡入与轻微回弹，完成后移除动画包装。倒序列表以消息 ID 和日期为稳定 key，发送时滚至最新消息。动效参数集中在 `AppMotion`。
- **影响**：首次欢迎消息切换、快速连发及图片消息沿用同一入场路径；历史消息与 AI 回复不重播。新行局部隔离重绘，列表项不增加玻璃层。

### [ADR-026] 通用主题与语言偏好

- **背景**：应用只能跟随系统明暗模式和设备语言，用户无法在设置页固定主题或语言。
- **决策**：通用偏好独立保存于 `config/ui_preferences.json`，先写临时文件再原子替换；主题默认为系统，语言在首次选择前跟随设备。启动前读取并应用偏好，运行时由 Riverpod 控制器在保存成功后更新 `ThemeMode` 与 Slang locale。“通用”作为根导航二级页覆盖 tab；主题和语言复用模型/历史轮数的 bottom sheet picker。
- **影响**：清除所有数据时同时重置偏好与当前界面；AI 设置仓库只删除自己的配置文件和临时文件，避免部分重置时误删通用偏好。存储统计仍将两类配置归入 `config`。

### [ADR-027] 各 Tab 分支独立保留底部避让

- **背景**：聊天输入 Dock 比普通 Tab 容器高；共享测量值在切换 Tab 时被覆盖，返回聊天的首帧列表底部 padding 从 246dp 暂降为 130dp，随后再次布局，造成消息气泡弹跳。
- **决策**：Shell 分别缓存聊天 Dock 与普通 Tab Dock 的实测高度，并为 IndexedStack 的每个分支提供对应的 ShellScope；聊天输入增长时仍按实测高度更新。
- **影响**：隐藏的聊天列表不再消费其他分支的 Dock 高度；切回聊天的首帧与稳定帧保持同一消息位置。

### [ADR-028] 空状态使用纯文本占位

- **背景**：通用空状态和零散无内容页面使用玻璃卡片、图标与大字，干扰页面层级；搜索页未输入与无结果的提示不够贴切。
- **决策**：共享 EmptyState 只渲染内容区域居中的小字号弱化色文本，不绘制图标或玻璃背景；错误操作独立置于文本下方。服务商无模型与 404 也移除占位卡片。搜索未输入显示“搜索你的碎碎念”，无结果显示“没有搜索到消息”，英文保持对应语义。
- **影响**：新增空状态沿用同一文本组件；图片预览在深色画布上使用深色主题的浅色文字 Token 保持可读性。聊天首页的欢迎气泡属于正常对话内容，不受空状态规范影响。

### [ADR-029] 思考 Markdown 窗口与最终回复延迟展示

- **背景**：单行纯文本思考预览无法显示模型的 Markdown 结构；最终回复逐字预览使气泡频繁重排。
- **决策**：思考状态保留当前步骤的累积 Markdown，超过 8192 UTF-16 单元时保留安全的末尾 4096 单元并开启新串流段；`StreamMarkdown` 在最多三行的窗口内增量渲染，内容尺寸变化后平滑滚到底部，上下边缘使用透明度渐隐。回复串流仅切换为“正在输入”及三个错峰跳动的点，完整回复成功结束后才写入消息并一次渲染。常规 Markdown 六级标题统一为正文加 1dp、半粗；思考标题与正文同字号、半粗。
- **影响**：替代 ADR-024 的单行预览约定。实时思考只留在受日志过滤的临时状态；步骤切换必须重置 Markdown 流，失败或取消时不发布部分回复。

### [ADR-030] Chat 固定控件的玻璃等级

- **背景**：Chat 顶部操作按钮和底部 AI 开关需要更明显的玻璃层次；头像背景与输入附件按钮保持较低开销。
- **决策**：设置、搜索和 AI 开关使用 `GlassQuality.premium`；顶部头像背景与附件按钮继续使用 `GlassQuality.standard`。
- **影响**：固定区域最多保留这三个 premium 控件，避免把高开销玻璃扩散到列表项或整块输入区域；相关 Widget 测试锁定等级分配。

### [ADR-037] Agent 思考与工具状态的 pending 动效

- **背景**：思考内容与工具调用会持续一段时间，仅靠滚动文本或静态标签不易感知任务仍在运行。
- **决策**：思考和工具状态统一显示 hook 驱动的错峰跳动点；思考 Markdown 单独使用 14sp、1.4 行高及降低透明度的主题前景色，普通 AI 回复样式不变。
- **影响**：动画生命周期随 Widget 自动结束，不使用会在测试后遗留 Timer 的循环动画；新增进行中状态沿用共享 pending 指示器。

### [ADR-038] AI 状态卡片与输入区动效契约

- **背景**：AI 思考、工具调用和最终回复的状态切换缺少连续反馈；AI 模式与普通输入状态区分度不足，键盘态附件按钮的材质也与输入框不一致。
- **决策**：思考卡片固定为“图标 + 状态”与最多三行滚动 Markdown 两行结构；pending 表面使用一次性横向高光脉冲，有思考文本时隐藏右侧跳动点。工具、思考和最终输入状态统一使用 560ms 淡入并轻微上移的切换。AI 回复持久化成功后发布一次性消息 ID，时间线仅为该 ID 播放底部滑入动画。AI 模式通过低开销流彩边框标记输入区、Tab dock 和 AI 开关；键盘态附件按钮复用输入框 blur 与 tint，并由同一 `TextFieldTapRegion` 接管点击。
- **影响**：历史消息不会重复播放入场动画；固定控件只保留边框动画，不增加列表项玻璃层；标准页面顶部 button/title 统一使用 48dp toolbar 基线并写入 UI 规范。

### [ADR-039] 服务商配置控件的玻璃质量预算

- **背景**：服务商配置页同时包含格式选择、模型能力开关、思考等级和顶部操作按钮；这些交互控件在高版本玻璃主题下若继承 premium，会在表单滚动和状态切换时叠加高成本渲染。
- **决策**：服务商配置页内的 `GlassSegmentedControl`、`GlassSwitch` 和 `GlassIconButton` 全部显式使用 `GlassQuality.standard`；外层卡片与模型分组继续使用 standard liquid surface，单个模型状态仍由局部 Hook 状态驱动。
- **影响**：该页面不再依赖主题对交互控件的隐式质量回退；新增服务商页内玻璃控件必须显式选择 standard 或更低质量，并通过 Widget 测试锁定质量预算。

### [ADR-040] Vercel AI Gateway 推理摘要自动配置

- **背景**：Vercel AI Gateway 使用 OpenAI 兼容接口转发多个上游模型；仅设置 SDK 通用 reasoning 等级不足以要求 GPT、Gemini、Claude 或 DeepSeek 返回可展示的 reasoning 摘要，而且不同上游的参数嵌套位置不同。
- **决策**：当服务商 `baseUrl` 的主机严格为 `ai-gateway.vercel.sh`、模型启用思考能力且接口不是 Anthropic Messages 时，由纯 Dart 配置器按模型 ID 生成 `ProviderOptions`。GPT Responses 使用 `openai.reasoning.{effort,summary:auto}`，Chat Completions 使用 `openai.reasoning_summary`；Gemini 将 `thinkingConfig` 放入 `openai.providerOptions.google` 与 `vertex`；Claude 固定预算或 adaptive thinking、DeepSeek 使用各自的 `openai` reasoning 结构。请求统一通过 `ai_sdk_dart 3.1.0` 的 `streamText(providerOptions:)` 传入，已有 reasoning delta 事件链路负责展示摘要。
- **影响**：普通 OpenAI URL、未启用思考、未知模型和 Messages 服务商不会注入 Gateway 参数；新增模型供应商映射必须补充配置器单测与 SDK 请求契约测试。Gateway 的真实可用性仍取决于上游模型和密钥，配置器只负责生成协议参数。

### [ADR-041] 弹层操作按钮与自建组件库

- **背景**：自定义 Dialog 和设置 Sheet 中的确认、取消、保存、删除操作使用了多种 Material 按钮，圆角、触控高度与边框对比度不一致；共享组件缺少集中预览入口。
- **决策**：`AppActionButton` 与 `AppActionIconButton` 统一承载弹层和表单 action，提供 primary、secondary、destructive 主题变体，采用胶囊圆角、48dp 最小触控区和主题派生的低对比度纯色描边。所有共享 UI 原子组件在“我的 > 开发工具 > 组件库 UI”提供真实组件预览。
- **影响**：Dialog / Sheet 中不再直接构造 Material action button；新增共享组件需要补充预览与同级 Widget 测试，并覆盖适用的明暗主题和语义变体。

### [ADR-046] 提交前统一格式化 Dart 代码

- **背景**：提交前若只格式化局部文件，未格式化的 Dart 代码可能进入版本库，导致代码风格和审查结果不一致。
- **决策**：每次 `git commit` 前必须在仓库根目录使用本地工具链执行 `.\\tools\\flutter\\bin\\dart.bat format .`，覆盖项目全部 Dart 代码，并在提交前检查格式化产生的 diff。
- **影响**：后续修改或代码生成完成后若再次产生 Dart 变更，必须重新执行全量格式化；格式化失败时不得提交。

### [ADR-047] Asset kit 品牌与状态插画

- **背景**：用户要求使用已有 asset-kit 统一应用 Logo、头像及状态页；本次明确需求替代 ADR-028 对这些页面仅用纯文本的约定。
- **决策**：原始素材保留在 docs/design，prepare_brand_assets.dart 生成按显示尺寸缩小的透明 PNG、各平台图标及 Android/iOS 启动素材。AppArtwork 通过 FlutterGen 类型化引用、固定布局与按 DPR 限制解码；EmptyState 按可用高度缩放插画并允许滚动。欢迎页保留三条临时气泡，错误消息的行内操作保持原交互。
- **影响**：Android/iOS 使用同一小狗品牌与明暗启动底色，未新增权限；空状态与真实内容共用主题文本，组件库展示全部素材。修改源素材后需重新运行生成脚本。

### [ADR-048] Overlay 默认正文样式

- **背景**：GlassToast.show 创建独立 OverlayEntry，只捕获玻璃及 Cupertino 主题；文本局部样式继承 MaterialApp 的黄色双下划线回退值。
- **决策**：在 MaterialApp.builder 中给 Navigator 及其 Overlay 提供主题 bodyMedium DefaultTextStyle，明确 decoration:none；保留 Liquid Glass Toast 的位置、交互、动画与自动关闭。
- **影响**：所有现有 Toast 调用直接获修复，无需修改依赖缓存；真实应用测试覆盖全部 Toast 类型和明暗主题的最终 RichText 样式及退场。

### [ADR-049] 欢迎小狗锚定输入框

- **背景**：聊天顶部已有用户头像，再叠欢迎插画会重复视觉焦点；默认头像缺少可读的实心背景。
- **决策**：默认头像以当前 bubbleOther 不透明主题色绘制圆形底板，图像保持 contain。欢迎插画移入 Composer 的 Stack，在输入玻璃之前绘制，底部 30% 与输入框重叠，双手位于上沿之外；居于输入区偏左，避开右侧 AI 开关。键盘聚焦态缩小，按输入实际左右边界定位；附件和已有消息时隐藏。
- **影响**：Shell 对整个 Composer 实测高度，消息底部自动避让；失焦时插画与 Tab 同步恢复，避免键盘 inset 归零后的第二次尺寸变化。测试覆盖明暗、280/390dp、键盘及首次发送，截图检查手部与玻璃遮挡关系。

### [ADR-050] Agent 资料与用户称呼分离

- **背景**：聊天与“我的”顶部应代表 Agent，资料页同时配置用户希望被如何称呼；旧版记录已有用户昵称和头像。
- **决策**：保留 UserProfile/ProfileEntity 的 nickname、avatar 及 ObjectBox UID，追加 agentName、agentAvatar。旧昵称继续用于 user.md 状态及提示词中的用户称呼，旧头像保留但不作为 Agent 展示。Agent 未自定义名字时存空值，以 Slang 显示中文“小懒”/英文“Dozy”，提示词通过注入的默认名字获取同一值。资料表单支持独立用户称呼，Agent 名字必填且两者最多 40 字符。
- **影响**：预设使用稳定 preset: 标识映射本地生成素材，工作/娱乐等七种头像统一保留实色圆形底板；底部选择器末尾才提供圆形相册入口。选择只更新草稿，保存后生效，关闭或相册取消保留原值。改用预设时只删除仓库自有且不再被资料引用的头像文件。默认引导迁移只替换受控首行，保留私人记忆正文。

### [ADR-051] 小懒应用名称与启动图标渐变

- **背景**：应用对外名称改为“小懒”，图标需要与蓝耳小狗协调的蓝到白纵向背景。
- **决策**：中英文应用标题和各平台可见名称统一为“小懒”；保留 applicationId、bundle identifier、Dart 包名和存储路径以延续现有安装数据。图标生成脚本以 #8CB9EE → #FFFFFF 的逐行线性插值生成背景；Android 自适应图标独立背景层与安全区前景组合，其他平台输出合成图标。
- **影响**：Android/iOS 同步品牌更新，不新增权限。发布保持 0.3.0+3 并使用同一签名，通过 --split-per-abi 构建 arm64 包；检查包内名称、ABI 和签名后交付。

- **v0.4 发布补充（2026-11-14）**：版本升级为 0.4.0+4，继续使用同一发布签名与 arm64 拆包策略，Android 实际 versionCode 为 2004；关于页更新日期保持为当天。

- **v0.5 发布补充（2026-11-14）**：版本升级为 0.5.0+5，继续同一发布签名与 arm64 拆包策略，Android 实际 versionCode 为 2005；保留应用标识、存储路径与本次更新日期，产物与校验记录见任务 69。

### [ADR-052] 输入区键盘态共享过渡进度

- **背景**：插画尺寸直接切换；Tab 的 AnimatedSize 在收拢开始时就移除内容，无法看到退出动画。
- **决策**：键盘可见且输入聚焦共同驱动 280ms easeInOutCubic 的可打断进度；同一进度同步控制欢迎插画的尺寸、横向位置和顶部占位，以及 Tab 的高度裁切/透明度、附件入口宽度和输入内边距。Tab 退场完成后再移除，过渡期间不接受点击和读屏焦点。插画按完整尺寸固定解码缓存，避免逐帧重新解码。
- **影响**：保留双手露在输入框上方的 30% 叠放关系，预留最大插画高度用于小屏多行上界；失焦即恢复 Tab，快速反向从当前进度继续。减少动态效果时直接使用最终布局，AI 文本也跳过零时长 AnimatedSize，避免布局阶段自触发。

### [ADR-053] 全局渲染档位与主要动画偏好

- **背景**：通用设置需要统一切换玻璃渲染等级和动画效果；用户补充不必强行消除每个第三方控件的细节动画。
- **决策**：AppPreferences 保存纯 Dart 的 AppRenderQuality（minimal / standard / premium）及 animationsEnabled，默认标准与开启，旧 JSON 自动补默认值。MaterialApp.builder 内的 AppEffects 向 Navigator、Sheet、Overlay 提供统一 GlassTheme、固定范围的 GlassAdaptiveScope、MediaQuery.disableAnimations 与 GlassAccessibilityScope。原显式档位通过 AppEffects.qualityOf 获取用户值，避免 Scope 仅作上限、无法把 standard 控件升级到 premium 的问题。
- **影响**：覆盖此前局部固定档位预算；默认所有控件使用标准，用户可统一升降档。关闭动画使应用自己的页面/弹层过渡、键盘插画与 Tab、消息入场、思考点、输入光效和骨架闪烁静止或直接完成；系统减少动态效果优先，不使用全局 TickerMode 冻结应用状态。第三方 Switch、Toast 等保留库自身减少动画后的细节反馈，不复制或修改依赖源码。键盘过渡采用 hook controller，中途关闭立即落到终值且不重建编辑器。

### [ADR-054] Hugeicons 统一图标与资料用语

- **背景**：页面、导航、弹层与状态提示混用 Material 图标；资料页的 Agent 术语不能清楚说明头像和名字代表谁。
- **决策**：使用 Hugeicons 免费 stroke-rounded 包；应用图标通过 `AppIcons` 语义表和 `AppIcon` 统一线宽、颜色及语义。共享按钮、列表项使用 `AppIconData`。Toast 显式注入图标，Markdown 图片错误态由自有 builder 呈现。第三方 TalkerScreen 不提供完整图标覆盖入口，日志页改为自有页面，保留搜索、过滤、排序、复制、导出、清除和日志开关。资料入口改为“编辑资料”，头像下方以小头像与气泡说明“我的名字”和“你的称呼”，气泡随表单草稿更新。
- **影响**：`AGENTS.md` 禁止新增 Material/Cupertino 图标，并由 `icon_source_test.dart` 守卫；品牌图像与头像不属于图标库。新增图标需在组件库预览并覆盖明暗主题。

- **补充**：消息 `strokeRoundedMessage02`、记忆 `strokeRoundedCards02`、我的 `strokeRoundedBlackHole01`；AI 模式更新为 `strokeRoundedPawPrint`，隐藏 AI 消息为 `strokeRoundedMagicWand02`，AI 配置为 `strokeRoundedAlien01`，模型选择为 `strokeRoundedAlien02`，服务商为 `strokeRoundedSpaceship`，关于我们为 `strokeRoundedLookLeft`，拉取模型为 `strokeRoundedDownload02`。AI 按钮两种状态保持同一图形，以颜色和文字切换表达状态；其他 AI 活动仍用原有语义图标，Toast 保留信息图标。

### [ADR-055] Bing RSS 网页搜索与分段阅读

- **背景**：原 Bing Search API 于 2025-08-11 退役；用户指定无需 Key 的 Bing RSS HTTP 搜索，并要求网页纯文本提取和硬切段，避免占满模型上下文。
- **决策**：`WebResearchRepository` 作为 Agent Domain 边界，Data 层通过 Dio 请求 `https://www.bing.com/search?format=rss`，以 XML 解析标题、链接、摘要；`web_read` 只访问公开 HTTP(S) 页面，固定 20 秒请求时限、2 MB 下载上限、最多 4 次安全重定向。HTML 由解析器剔除脚本、样式、导航及标签，最多保存 80,000 字符纯文本，每次默认返回 6,000 字符、最多 12,000 字符，并返回 `next_offset` 供按需续读；同一次 Agent 回合缓存至多 4 页。解析放后台 isolate，外部内容标记不可信，提示词禁止执行网页内指令或擅自发送私人记忆。
- **影响**：无需搜索 API Key，但 Bing RSS 的相关性与可用性不受应用保证；空结果和 HTTP 失败如实返回，不虚构来源。只支持 HTML 和纯文本，JavaScript 渲染页、登录页和 PDF 不承诺提取。网页搜索和阅读在 Agent 时间线显示独立状态，结果带来源 URL，私网地址在发起请求和重定向时均拒绝。

### [ADR-056] 普通模式折叠连续 AI 消息

- **背景**：聊天页普通模式仍显示发给 AI 的提问与 AI 回复，混杂在私人记录中；切换模式时需要保持时间顺序和左侧视觉锚点。
- **决策**：时间线按日期和普通消息边界把相邻 AI 消息组成稳定分组；普通模式以左侧气泡显示按提问数计算的隐藏组数，孤立回复按回复数计。AI 模式在同一列表项展开原消息，使用底部左对齐的尺寸与淡入淡出过渡；进行中状态只在 AI 模式显示。
- **影响**：摘要点击开启 AI 模式，普通消息及日期分隔保持原位置；分页继续按原始消息窗口计数，减少动态效果时直接切换。跨日期问答分为两个日期内摘要。

### [ADR-057] 关于页采用插画与信息列表

- **背景**：关于页需要移除标语等描述文案，并集中展示应用信息。
- **决策**：顶部使用已有阅读小狗插画，下方复用 GlassGroupedSection / AppListTile 展示版本、更新日期、用户协议和官网，Leading 统一使用 Hugeicons。版本继续读取已安装包；更新日期为随版本维护的发布元数据，本版为 2026-11-14。
- **影响**：版本加载使用等高骨架，读取失败在原行重试；协议与官网尚未提供内容或地址，保持空值、无点击和无箭头，不生成虚假链接或协议。

### [ADR-058] 测试按故障边界归属与去重

- **背景**：功能迭代后，页面与组件套件重复执行相同流程、重复检查公共样式，聊天测试文件超过 700 行。
- **决策**：以状态、触发操作、断言与故障边界确定重复；独有断言先迁入保留用例，再删除旧用例。公共控件的视觉契约放组件测试，页面验证实际接线与结果；同操作的变体参数化，超长测试按对象拆分。默认入口继续由生成器注册全部同级测试。
- **影响**：业务算法与真实 SDK 请求、URL 校验与重定向、存储服务与 UI 并发屏障属于不同边界，保留独立测试；明暗、语言、小屏、大字和动画中途切换不作盲目裁剪。去重映射及基线记入任务文档，日常维护遵循 `docs/testing.md`。

### [ADR-059] 图片查看前景操作与有限历史导航

- **背景**：全屏图片遮住共享玻璃层的关闭按钮；缩略图底栏破坏沉浸感，首尾当前项无法居中，消息叠图缺少景深。
- **决策**：关闭按钮使用独立玻璃层并最后绘制，查看器固定暗色画布及可读前景。主图与无底栏缩略图共享真实历史索引，双向有限分页，到首尾停止；当前缩略图用两端留白居中，选中描边绘制在照片前、对比阴影在照片后。图片原比例让横向手势交给分页，放大后允许平移。
- **影响**：图片、缩略图和导航各自拆分组件，历史加载后以新不可变路径表初始化。多图每层使用主题派生的柔和扩散阴影并允许溢出，单图保持原样。测试覆盖两端、同步、窄屏、减少动态效果及真实白图放大后关闭；截图专用 binding 开启真实模糊阴影。

### [ADR-060] 消息锚定菜单与页面玻璃按钮边界

- **背景**：消息操作使用居中 Dialog，与被操作的卡片脱节且无法选择消息文本；页面全宽主按钮与浮层操作共用了实色组件。
- **决策**：消息卡片长按坐标驱动 hook 瞬态状态，以 OverlayPortal 在根 Overlay 展示 Popover，纯白实心、扩散阴影、同卡片圆角及 Hugeicons + 文字项；布局避让安全区和键盘，点击外部或返回关闭。文本采用原生 SelectionArea / SmoothMarkdown 选区，同样的 Popover 提供所选内容复制、全选和删除，不阻断选择手柄。
- **影响**：AppPageButton 集中到 core/widgets，使用 standard GlassButton 普通玻璃效果并遵从全局渲染档位、动画偏好，忙碌时阻止重复操作。Dialog / Bottom Sheet 继续使用原 AppActionButton，不受页面样式迁移影响；原 PrimaryButton 删除，跨 Feature 不再引用设置模块的按钮。组件库分别展示页面按钮、浮层按钮和消息菜单。


### [ADR-061] 浮动玻璃预算与设置入口收敛

- **背景**：高级档全局提升普通卡片造成无谓开销，部分图标被按钮约束放大；开发工具入口和状态提示过于突出或被遮挡。
- **决策**：AppEffects 以请求档位作为组件预算，普通内容最高 standard、浮动 chrome 可 premium，minimal 全局降级；默认主题保持内容预算。AppIcon 居中松约束，20dp 小图标保留至少 48dp 热区；card group 间距统一 24dp。Headers 独立分组；开发工具默认隐藏，在“关于我们”插画累计五次点击后持久化解锁，退出页面重置未完成计数、清除数据重新隐藏。
- **影响**：替代 ADR-053 的所有控件统一升为 premium 策略。Toast 复用 GlassToast 实际材质，由应用 Overlay 统一布局于安全区下方 48dp，保持正文主题、三秒自动退出、向上滑动与幂等手动关闭。AI 折叠提示采用明暗主题对应的文字渐变，不增加实时模糊。设置入口改称“AI 配置”与“关于我们”；无模型的记忆面板显示当前百分比。


### [ADR-062] 聊天气泡内容宽度与控件垂直节奏

- **背景**：Markdown 的 stretch 列使短回复也占满最大气泡宽度；编辑态输入边距归零；Switch 热区与列表内边距叠加导致行高突出。
- **决策**：AI 文本使用同一 Markdown AST 判断可做固有宽度计算的文本/标题/行内样式，按内容收缩并受既有 82% 上限约束；表格、代码、公式及媒体保留有界布局。判断按消息正文 memoize，继续使用 SmoothMarkdown 和原生选区。输入上下固定 12dp，最大编辑高度扣除这两侧留白；键盘态发送按钮的右侧留白与上下光学留白相等。
- **影响**：AppListTile 的垂直 padding 归属于标题/副标题，整行仅设水平 padding，避免给 48dp Switch 热区重复加高；普通行、Switch 行随文字缩放保持同高，带副标题行保留原节奏。输入区单行键盘态高度由 48dp 调整为 72dp，附件仍垂直居中，旧占位符布局测试更新该契约。

### [ADR-063] 首次引导采用逐步资料草稿与可选 AI 连接

- **背景**：新用户直接进入聊天，不清楚 AI 身份、称呼设置和模型配置的关系。
- **决策**：引导归属 settings，采用欢迎、头像与 AI 名字、用户称呼、AI 连接四步；前序资料页最多两项。ReactiveForm 与 hook 状态保留本次引导的全部草稿，预制头像/相册和模型配置复用现有入口。最后先保存资料并同步用户记忆，再写入 AppPreferences.onboardingCompleted；任一步失败留在当前页面重试，提交期间禁止重复操作。默认 AI 名称保留空值以跟随语言显示小懒/Dozy。
- **影响**：路由监听完成标记刷新重定向，不重建 GoRouter；未完成时仅允许引导与 AI 配置子页，配置返回后继续原步骤。旧偏好文件缺字段视为已完成，新建偏好为未完成，清空全部数据重新引导。统一 standard 页面按钮、48dp 返回热区、固定底部操作区、可滚动内容、键盘避让，以及淡入/位移/缩放转场；避让动画结束后按最终视口再次显示聚焦输入项，减少动态效果直接切换。过程不请求相册权限、不发起模型请求，只有用户主动配置或选择相册时才进入对应流程。

### [ADR-064] 消息时间按可见邻接聚合与页面会话查看

- **背景**：相邻消息重复展示同一分钟造成噪声；需要通过双击列表临时查看每条消息的秒级时间，并在离开聊天后恢复。
- **决策**：纯函数按 newest-first 时间线计算每个连续本地年月日时分中的最新消息 ID；展开的 AI 消息参与同一邻接规则，折叠的 AI 摘要与日期分隔打断邻接。时间精度由聊天页 hook 状态单向开启，不持久化、无超时；监听 GoRouter delegate 的最顶层匹配路由，在切换 Tab 或 push 子页时重置。
- **影响**：不更改消息时间或存储格式；时间显隐独立于 AI 标记，欢迎消息仍不显示 footer，搜索结果保持原时间展示。Scope 仅覆盖聊天列表，新消息、删除与 AI 模式切换会重新计算可见时间。双击由无计时器的 Pointer 观察实现，不参加子控件手势裁决，保持图片、重试与行内按钮的即时单击；拖动、长按和取消不触发精确时间，离开页面也清空手势记录。错误路由匹配为空时视为离开聊天。

### [ADR-065] Composer 单行基线与多行内部留白

- **背景**：键盘态单行输入框因为 Row 外层固定纵向 padding 变矮且点击面被挤压，和 48dp 加号控件不齐；多行留白应属于文本编辑区。
- **决策**：移除输入 Row 的垂直外间距。CupertinoTextField 单行约束最小高度 48dp；按当前文本和输入宽度用 TextPainter 检测显式换行或软换行，仅多行时在字段自身添加 12dp 上下 padding。Composer 控制器文本变化驱动布局重新测量。输入 Row 透明 Listener 覆盖整个输入面，在 pointer down 请求聚焦，让输入框周边留白可唤起键盘。
- **影响**：单行键盘态输入框与附件按钮等高；多行字段随内容长高，外层 max height 只预留导航高度，避免把内部间距重复计入上限。占位符仍保持垂直居中，附件与发送按钮保持现有触控热区及单击行为。

### [ADR-066] AI 状态渐变、轻量模型选择与表单提示

- **背景**：AI 待命态需与隐藏 AI 消息提示保持视觉一致；模型能力开关动画负担较高；新增记忆表单缺少输入方向；模型选择半屏头部与按钮图标比例不足。
- **决策**：AI 渐变统一由 `AppAiTokens.contentGradient` 提供，待命只给文本应用遮罩，保留 AnimatedSwitcher 状态。新增记忆页文件名和 Markdown 正文使用 Slang 引导占位，编辑已有记忆不覆盖正文。已添加模型的图像/推理能力改为 AppIcons 方框及 checked Semantics，替代 GlassSwitch。模型选择 Sheet 显式拉伸全宽及标题栏；添加、拉取模型的 AppPageButton 图标统一 20dp。
- **影响**：列表行保留 48dp 点击区与即时保存逻辑，不再引入 Switch 渲染；新增中英文占位必须同步 Slang 资源和生成代码。共享 AppPageButton 保留默认尺寸，只有模型列表操作使用紧凑图标。

### [ADR-067] Composer 光学边距与消息菜单选区入口

- **背景**：单行 Composer 收起态上下留白不足，展开态发送按钮向左偏移；消息文本长按直接进入选区，与操作菜单竞争手势。
- **决策**：输入行收起态以 8dp 四边留白包裹 48dp 控件，展开时上下及右侧留白随同一键盘进度归零，发送圆钮到上、右边界均为 6dp。消息默认不注册文本选择手势，长按统一进入锚定菜单；“选中文本”在原按压位置启用 SmoothSelectionRegion / SmoothMarkdown 选词，复制后恢复普通消息菜单。Popover 以选项实际渲染边界追踪指尖，按住滑动跨项时更新高亮，松手仅执行当前项。
- **影响**：多行纵向留白继续归属输入字段内部，最大编辑高度扣除外层收起态留白；图片消息无选中文本操作。消息与选区菜单共用纯白表面和高亮 Token，明暗主题保持可读性。

### [ADR-068] AI 文案渐变与 Markdown 引用呈现

- **背景**：隐藏 AI 消息和模式按钮的旧渐变混入青绿、暗色偏灰，按钮图标未同步着色；依赖的增强引用 builder 自绘左竖线；记忆正文编辑器沿用 Material 默认 hint 色，与标题的玻璃输入框不一致。
- **决策**：两处 AI 文案共用 `AppAiTokens` 的红、紫、蓝高饱和三色渐变，激活按钮图标也用同一渐变遮罩，保留原文字切换动画与语义。引用块在应用 builder 注册表中覆盖依赖的增强 builder，只使用主题底色、圆角与内边距。记忆正文编辑器局部覆盖 `InputDecorationTheme.hintStyle`，颜色与标题玻璃输入框的 Cupertino placeholder 完全一致。
- **影响**：只调整文字与图标渐变，不更改 Composer 背后的弥散光效；Markdown 引用不再显示竖线及依赖默认的 Material 引号图标。明暗主题、实时与静态 Markdown、实际 hint 渲染均由测试覆盖。

### [ADR-069] 暂停向模型暴露网页搜索与阅读

- **背景**：当前无需 Key 的 Bing RSS 网页搜索能力尚不可用，向模型提供 `web_search` / `web_read` 会诱导它承诺实时检索。
- **决策**：Agent 默认 `build()` 工具集合不再包含两个网页工具，`AssistantAgent` 的每次模型请求只传默认集合；网页工具实现留在独立 `buildWebTools()` 集合供隔离验证，生产请求不引用。系统提示词删除搜索、阅读和引用网页的指引，明确当前无法在线核验，不得声称已搜索或引用未经核验的来源。
- **影响**：消息检索、图片查看及记忆工具继续可用；现有网页 HTTP/解析和工具实现测试保留，待服务可用时再单独决定是否恢复暴露。网页工具不再产生新的 Agent 活动事件。

### [ADR-070] 模型目录数量随配置状态派生

- **决策**：服务商副标题展示接口格式与已添加模型数量，例如 Responses (5 个模型)；添加模型按钮显示目录中尚未添加的数量，例如 添加模型 (15 可用)。两者直接消费现有设置流，无独立计数状态；英文区分 model / models。图片与思考能力项之间统一使用 16dp 间距。
- **影响**：刷新目录、添加及移除模型后自动重算，未加载目录显示 0 可用；数量表示目录可选项，不代表已通过网络可用性探测。

### [ADR-071] AI 输入静态渐变与普通模糊背景

- **背景**：AI 输入光效持续循环增加后台负担；高级渲染不应改变输入与 Tab 共用背景。
- **决策**：AiComposerGlow 移除循环和入退场动画，固定原静止相位及渐变配色，保留裁切与编辑器挂载位置；输入背景预算最高 standard，minimal 继续降级。替代 ADR-042 的动画和 ADR-061 对该背景的 premium 约定。
- **影响**：测试验证静态像素、无持续动画帧、后台恢复及键盘布局。引导末页仅保留底部配置入口，标题使用尚未保存的用户称呼，空称呼显示“我准备好了”；配置完成后仍可开始使用。

### [ADR-072] 自有浮层使用连续圆角与静态轻拟物材质

- **背景**：Dialog、Sheet 与内部按钮的普通圆弧和纯平填色，与项目 Liquid Glass 轮廓不统一。
- **决策**：Dialog 直接使用 LiquidRoundedSuperellipse；Sheet 使用该库委托的同一 RoundedSuperellipseBorder，仅保留顶部圆角；按钮按外层 34dp 减 16dp 内边距得到 18dp 同心连续圆角。AppReliefTheme 集中不透明渐变、0.75dp 低对比度边框及扩散/接触阴影；AppModalSurface 和 showAppBottomSheet 统一两个 Dialog 与七类 Sheet。文字/图标按钮复用材质，保留 Material 语义、键盘焦点与状态，按压减弱凸起并缩放。
- **影响**：替代 ADR-042 的无描边动作面和 ADR-060 的实色按钮外观。浮层无新增实时 blur / shader / 循环 ticker；背景保持不透明。主色高光单独限幅，明暗主题的正文与按钮所有渐变停止点均满足 4.5:1 对比度。组件库增加真实 Sheet 预览，页面主按钮与消息 Popover 继续各自既有视觉契约。用户确认截图效果后同意提交。

### [ADR-075] 图片手势仲裁与折叠讨论计数

- **背景**：PageView 与 InteractiveViewer 竞争双指缩放；折叠提示需显示 Agent 名字及用户和 AI 的消息总数。
- **决策**：主图 scale recognizer 统一持有触摸，原比例单指直接更新有界页偏移，释放后按位移/速度吸附；多指中止分页，放大后平移。双击以触点为中心放大三倍，再次双击恢复完整适屏尺寸，遵从减少动态效果。图片查看器不提供长按操作面板。
- **影响**：移除折叠模型的冗余 groupCount，直接使用当前分组 messages.length；日界线及普通消息继续分组，未回复提问和孤立 AI 回复各算一条。提示名响应 userProfileProvider，空名回退本地化默认名；中文为“{agentName}收起了 {count} 条讨论”，无末尾标点。搜索输入图标显式使用 foregroundMuted，明暗主题共享中性灰语义。未增加依赖、平台权限或存储结构变更。

### [ADR-073] 紧凑玻璃消息菜单与操作反馈

- **背景**：消息菜单固定白底且尺寸偏大，滑动时渐变高亮残留；复制和开发模式开启缺少反馈，删除缺少确认。
- **决策**：消息/选区菜单共用 136dp、12sp 文字、20dp 图标和按用户要求收窄的 44dp 菜单行热区；使用独立层 standard GlassContainer，显式使用与 Tab 背景相同的 chromeTint/chromeBlur（深色 alpha 0xAA、浅色 0xB3），遵从 minimal 全局降级。外层复用弹层按钮的 18dp 连续超椭圆，内部按 4dp padding 派生同心轮廓，行内横向 padding 为 16dp（图标距外边界 20dp）；无 Scrollable，极短视口整体缩放适配，命中使用实际变换后的 bounds。按压/滑动共用主题派生的低透明度灰色并即时更新，选区另用灰色透明 Token。
- **影响**：替代 ADR-060/067 的固定白底、卡片圆角契约。所有消息删除入口复用 AppConfirmDialog，仅确认后读取控制器执行删除。开发模式首次成功开启及整条/选区复制统一 Toast。AI 模式图标和标签行使用单一稳定 ShaderMask，停用以 dst 保留原色，切换标签仍交叉淡入，替代 ADR-068 的分别遮罩。

### [ADR-076] 聊天底部操作与低成本设置表面

- **背景**：用户阅读较旧消息时需要快速回到最新位置；引用入口与回到底部入口不能同时占用左下操作位；服务商配置页在轻量模式下仍有滚动掉帧风险。
- **边框补充**：轻量实心表面复用 `shadowBorder` 色与统一 0.75dp 宽度；服务商卡片与 Dock 沿原 shape 绘制，输入描边置于 AI 渐变上方，保持布局和连续圆角不变。
- **决策**：Riverpod 托管时间线共享 ScrollController，左下按钮用 hook selector 从偏移派生显隐，与引用按钮复用胶囊；超过 24dp 显示回底，点击归零后恢复引用。凭据、Headers、模型分组采用库原生 solid 表面和既有连续圆角。Toast 使用 neutral 描边，保留原类型图标但统一中性色，放在底部安全区或键盘上方。深色画布收敛为微弱蓝黑渐变。
- **影响**：轻量模式三页 Tab 栏与普通聊天输入背景改成不透明主题色，无实时背景采样；按用户明确要求，AI 模式保留静态彩色渐变及主题衬色。输入子树保留稳定 key，切换材质时保留焦点、草稿与选区。标准/高级模式继续原玻璃策略。没有真机采样前不将卡顿归因于单一渲染层。
