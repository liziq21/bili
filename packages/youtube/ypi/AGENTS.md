# ypi API 包规范

本文件只记录 `packages/youtube/ypi` 的平台特有规则。通用 API 包规则见 [`packages/AGENTS.md`](../../AGENTS.md)，根目录规则见 [`AGENTS.md`](../../../AGENTS.md)。

## 范围与依赖

- `ypi` 的目标边界是纯 Dart YouTube InnerTube 网络包，不依赖任何 workspace 包。
- `ypi` 不得返回或接收外层领域模型、分页状态或 continuation 状态；这些由 `packages/youtube` 适配层负责。
- `lib/ypi.dart` 只导出正式 service、网络 DTO、typed exception 和客户端配置；parser、fixture、tool 和测试代码保持内部。
- InnerTube 是 YouTube 客户端使用的内部协议，不是官方公开 SDK；来源以实际请求、响应 fixture 和可复核开源实现为准。

## 已确认的来源与端点

| Endpoint | Method / Path | 请求/鉴权 | 来源 | Fixture | 实测日期 |
|---|---|---|---|---|---|
| 视频搜索 | `POST https://www.youtube.com/youtubei/v1/search` | InnerTube client context；当前实现不要求登录 | [InnerTube 开源实现](https://github.com/LuanRT/YouTube.js) | `testing/search_video.json` | 已有原始 fixture；抓取日期未记录 |
| 频道搜索 | `POST https://www.youtube.com/youtubei/v1/search` | InnerTube client context；当前实现不要求登录 | [InnerTube 开源实现](https://github.com/LuanRT/YouTube.js) | `testing/search_channel.json` | 已有原始 fixture；抓取日期未记录 |
| 搜索建议 | `GET https://suggestqueries.google.com/complete/search` | 公共请求 | [Google Suggest](https://suggestqueries.google.com/complete/search) | `testing/search_suggest.json` | 已有原始 fixture；抓取日期未记录 |
| 首页推荐 | `POST /youtubei/v1/browse`，`browseId=FEwhat_to_watch` | InnerTube client context；需真实探针确认 | [InnerTube 开源实现](https://github.com/tombulled/innertube) | 尚无 | 未实测 |
| 独立 Trending | 不作为实现依据 | 社区报告旧 `FEtrending` 不稳定/退役，尚未验证，不注册 | [InnerTube 使用说明](https://github.com/tombulled/innertube) | 不适用 | 未验证 |

不得使用第三方聚合 API 或抓取服务作为运行时数据源；社区实现只能作为请求格式参考，不能替代本包的实测 fixture。

## ypi DTO、解析与异常

- ypi 不得直接返回 `VideoModel`、`CreatorProfile`、`Page` 或 `Result`；这些属于外层 `packages/youtube` 和 `packages/data`。
- 搜索和 browse 响应应先通过 DTO 表达平台 JSON 的 envelope、renderer、`owner`、统计和 continuation 结构，再由外层转换。
- DTO 使用 `Network` 前缀并按 YouTube 端点区分；复杂 renderer 使用手写 `fromJson`，稳定且扁平的嵌套字段可以使用 `json_serializable`。
- DTO 只声明已确认的稳定业务字段；未知 renderer、tracking、广告和实验字段忽略。缺少视频 ID 的 item 丢弃并继续处理。
- API 错误按包内独立分类表达，至少区分网络错误、HTTP 错误、InnerTube 错误、JSON 解码错误和 client context/鉴权错误；不使用跨包异常基类。
- `YoutubeService` 返回 continuation token，但 token 的查询/feed 状态由外层管理；API 包不保存页面状态。
- InnerTube client context、API key（如需要）、Cookie、Token、`trackingParams`、`clickTrackingParams`、`visitorData` 和其他追踪字段不得写入 fixture、日志或测试输出。

## 抓取与测试

- 真实抓取脚本放在 `tool/capture/`，从 `packages/youtube/ypi/` 目录手动运行；输出到 `testing/<endpoint>.json`。
- fixture 只保存经过包级规则处理后的 HTTP response body，不保存 headers、Cookie、Token、带凭据 URL 或追踪凭据；HTTP status 和请求元数据记录在 `testing/README.md`。
- 抓取遇到非 2xx、InnerTube 错误或无法识别结构时不得写入或覆盖 fixture，并返回非零状态。
- 每个新增 endpoint 必须包含真实 fixture、MockClient 请求形状测试、fixture 解析测试和失败路径测试。
- CI 只运行离线 `dart test`；禁止在单元测试或 CI 中访问真实 YouTube 服务。
