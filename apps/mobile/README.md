# selfbox · 留话

Expo SDK 57 + Expo Router + HeroUI Native + Uniwind，本地优先的聊天式记录应用，无需登录或后端即可使用。

## 目录

- `app/`：聊天 / 设置 tab、聊天详情、新建聊天、账号及开发路由。
- `views/`：页面；`views/login/` 保留尚未接入导航的认证表单。
- `components/`：主题、数据库 provider、浮动底栏和通用原生组件。
- `db/`：Drizzle SQLite 表、CLI 生成的迁移、Zod payload 和读写逻辑。
- `i18n/`：中英文文案；`native/` 为系统应用名及权限说明。
- `lib/`：图片持久化、Zustand 设置，以及保留的 auth / tRPC 基建。
- `env/`：应用独立的公开配置校验。

## 常用命令

在仓库根目录执行：

```sh
pnpm install
pnpm dev:mobile
pnpm --filter mobile ios
pnpm --filter mobile android
pnpm --filter mobile test
pnpm db:generate:mobile
pnpm lint
pnpm check-types
pnpm build
```

默认使用 Expo Go；原生开发构建使用 `ios` / `android` 命令。新增原生依赖或修改权限、应用名后需要重新构建。

## 数据与交互

- 首次启动创建「我的独白」；系统界面使用 Lucide，用户自定义聊天图标另支持单个 emoji。
- SQLite 数据库为 `selfbox.db`；启动时通过 Drizzle 官方 Expo migrator 执行迁移，以 `__drizzle_migrations` 记录版本，失败回滚并显示重试入口。
- 数据库打开失败时显示可复制的错误详情；仅开发版提供「删除数据库并重启」，确认后删除数据库文件并重新加载应用，下次启动自动建表。
- 改表只修改 `db/schema.ts`，运行 `pnpm db:generate:mobile`（或 `pnpm --filter mobile db:generate --name=变更名称`），用 `pnpm lint:fix` 统一格式后，提交 `db/migrations/` 下自动生成的 SQL、snapshot、journal 和 `migrations.js`，不手写或修改已发布迁移。`driver: "expo"` 负责生成入口，Babel 内联 SQL 随安装包发布，用户设备启动后自动升级；不对手机数据库运行 CLI migrate / push。
- 消息预留 `role: 'user' | 'bot'`；JSON payload 经 Zod 验证，按 `type: 'text' | 'image'` 区分，当前 `version: 1`。文字和图片说明使用 `react-native-marked` 渲染 Markdown。
- 相册图片复制到应用文档目录 `attachments/`，SQLite 保存相对文件名和尺寸，避免缓存清理或 iOS 容器路径变化后失效。
- 长按可置顶、修改、删除；置顶面板不改变消息原始顺序。修改图片消息可修改说明或替换图片。
- 清除数据会删除聊天、消息及附件，并重建「我的独白」；主题、语言等设置保留。
- 主题、语言（跟随系统 / 中文 / 英文）、气泡颜色通过 Zustand + AsyncStorage 保存。默认聊天名随语言切换，自定义名称原样保留。
- 主题颜色唯一来源是 `global.css` 的 `@variant light/dark`，复用 HeroUI 语义变量。切换只调用 `Uniwind.setTheme`；普通界面使用语义 className，原生图标、导航和 Markdown 使用 `useCSSVariable`，不在 JS 另建深浅色调色板。新增主题才需要配置 `extraThemes`。
- 设置中的账号入口仅展示说明，不执行认证；原有 auth、SecureStore、tRPC 和验证测试保留，开发者选项及 `/dev` 仅开发版可用。
- 测试用 Node.js SQLite 执行真实迁移和 Drizzle 查询，覆盖重启持久化、增删改、置顶、role、回滚、图片清理及设置恢复。

应用标识：`selfbox`，URL scheme：`selfbox`，iOS / Android 包名：`com.selfbox.app`。桌面中文名为「留话」，其他语言为 `selfbox`。
