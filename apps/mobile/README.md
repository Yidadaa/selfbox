# Mobile

selfbox 移动端应用，使用 Expo SDK 57 + Expo Router。

- 默认应用名称、Expo slug 和 URL scheme：`selfbox`。
- 桌面名称跟随系统语言：简体中文为「留话」，英文及未匹配语言默认为 `selfbox`；原生名称翻译集中在 `i18n/native/`，通过 `app.json` 的 `locales` 配置生成。
- iOS Bundle ID / Android 包名：`com.selfbox.app`。
- 本地设置和会话使用 `selfbox` 前缀；旧模板的数据不会自动迁移。
- 修改原生标识或桌面名称翻译后需重新构建安装包，Expo Go 和 OTA 更新无法验证或更新桌面名称。App Store / Google Play 商品页名称分别在 App Store Connect / Play Console 中配置。

## 首次设置

1. 登录 [Expo](https://expo.dev/) 账号，没有账号时可自行注册。
2. 在仓库根目录安装依赖并启动开发环境：

	```sh
	pnpm install
	pnpm dev
	```

3. 安装 Expo Go 应用。iOS 安装后，点击右上角头像并登录与 Expo 网页端相同的账号。
4. `pnpm dev` 启动后，扫描控制台输出的二维码即可进入本地开发。

## 开发

在仓库根目录执行：

```sh
pnpm install
```

启动 Web 和 Mobile：

```sh
pnpm dev
```

连接线上或测试环境时，只启动 Mobile：

```sh
pnpm dev:mobile
```

启动后在应用设置中切换到对应的线上或测试 host。

默认使用 Expo Go。首次运行原生开发构建时，执行以下命令之一：

```sh
pnpm --filter mobile ios
pnpm --filter mobile android
```
