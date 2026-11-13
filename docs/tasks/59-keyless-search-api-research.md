# 59 - 免注册与免 Key 搜索 API 调研

日期：2026-11-14。范围：不依赖注册、API Key 或按月免费额度的网页搜索接口；仅调研，不接入业务代码。

- [x] 核验服务方公开文档与使用限制。
- [x] 对候选执行匿名中英文 GET 请求，检查 HTTP 状态、结果及耗时。
- [x] 区分当前可调用、搜索相关性与长期稳定性，记录结论。

## 候选与实测

| 服务 | 官方声明 | 本次实测 |
| --- | --- | --- |
| FreeSerp | 无 Key、无注册、无固定额度；要求合理使用，建议每秒少量请求并缓存，重流量可能被拦截 | 英文 Flutter state management 返回 200、3 条结果，6.30 秒；中文杭州旅游返回 200、3 条结果，3.14 秒，但首条是湖州旅游，相关性有偏差 |
| Purili | 无 Key、无注册、无固定额度、JSON 接口 | 同一英文查询返回 200、10 条结果，2.50 秒；同一中文查询返回 200、空结果，2.47 秒 |

调用示例：

```text
https://freeserp.ai/api.php?index=web&q=Flutter&size=5
https://puri.li/api/search?q=Flutter
```

FreeSerp 网页搜索须指定 index=web，默认索引主要搜索网站主页。两家均使用自有索引，不应将结果视为 Google/Bing 原样结果。

结论：FreeSerp 可作为优先试用候选，Purili 可用于英文备选。每家仅测试两个查询，不构成可用率、延迟分位数、国内直连或长期稳定性证明；尚不能承诺满足“稳定长期使用”。SearXNG 公共实例并非统一托管 API，官方明确许多实例禁用 JSON，未开放的格式会返回 403。

## 来源

- FreeSerp：https://freeserp.ai/
- Purili：https://puri.li/developer
- SearXNG：https://docs.searxng.org/dev/search_api.html

本次未形成需要采纳的架构决策，未修改业务实现；本次观测不构成性能基准。
