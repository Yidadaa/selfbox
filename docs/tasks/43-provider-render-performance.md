# 服务商配置页渲染性能

## Checklist

- [x] 测试：服务商配置页的分段控件显式使用 standard 质量，避免在高性能主题下回退到 premium。
- [x] 测试：已添加模型的思考等级控件同样使用 standard 质量。
- [x] 实现：为服务商配置页内的交互式玻璃控件固定轻量渲染质量，保留页面卡片的 liquid surface。
- [x] 实现：检查状态更新范围；模型开关仅由对应行的局部状态控制，ProviderModelsSection 通过 select 只监听该服务商模型集合。
- [x] 验证：使用项目自带 Flutter 运行 analyze、定向测试、设置页全量测试和 diff check；全量测试入口曾因遗留路由测试进程停滞，未重复启动以避免并行占用 Flutter 资源。
