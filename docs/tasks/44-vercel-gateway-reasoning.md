# Vercel AI Gateway 思考配置

## Checklist

- [x] 测试：规范化识别 Vercel AI Gateway 的 base URL，覆盖尾斜杠、大小写和 query。
- [x] 测试：普通服务商、Anthropic Messages 格式或未开启思考能力时不注入 Gateway options。
- [x] 测试：GPT Responses、Chat Completions、Gemini、Claude 与 DeepSeek 生成正确的 provider options。
- [x] 测试：AssistantAgent 将 Gateway options 传给 SDK 请求。
- [x] 实现：新增纯 Dart 的 Vercel Gateway URL 与模型供应商识别配置器。
- [x] 实现：在 AssistantAgent 的 streamText 请求中接入自动生成的 provider options。
- [x] 文档：记录 Gateway reasoning 参数的架构边界与 SDK 版本约束。
- [x] 验证：使用项目自带 Flutter 运行定向测试、静态分析与 diff check。
