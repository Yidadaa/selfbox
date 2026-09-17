# Mobile

Expo SDK 57 + Expo Router 移动端应用。

## 首次设置

1. 登录 [Expo](https://expo.dev/) 账号。没有账号时，请使用公司邮箱注册，并加入对应的 Expo 组织。
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
