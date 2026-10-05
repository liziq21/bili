# ypi API 包规范

本文件只记录 `packages/youtube/ypi` 的平台特有规则。通用 API 包规则见 [`packages/AGENTS.md`](../../AGENTS.md)，根目录规则见 [`AGENTS.md`](../../../AGENTS.md)。

## 范围与依赖

- `ypi` 的目标边界是纯 Dart YouTube InnerTube 网络包，不依赖任何 workspace 包，也不依赖 Flutter SDK。
- `ypi` 不得返回或接收外层领域模型、分页状态或 continuation 状态；这些由 `packages/youtube` 适配层负责。
- `lib/ypi.dart` 只导出正式 service、网络 DTO、typed exception 和客户端配置；parser、fixture、tool 和测试代码保持内部。
- InnerTube 是 YouTube 客户端使用的内部协议，不是官方公开 SDK；来源以实际请求、响应 fixture 和可复核开源实现为准。

## 已确认的来源与端点

| Endpoint | Method / Path | 请求/鉴权 | 来源 | Fixture | 实测日期 |
|---|---|---|---|---|---|
| 视频搜索 | `POST https://www.youtube.com/youtubei/v1/search` | InnerTube client context；当前实现不要求登录 | [InnerTube 开源实现](https://github.com/LuanRT/YouTube.js) | `testing/search_video.json` | 已有原始 fixture；抓取日期未记录 |
| 频道搜索 | `POST https://www.youtube.com/youtubei/v1/search` | InnerTube client context；当前实现不要求登录 | [InnerTube 开源实现](https://github.com/LuanRT/YouTube.js) | `testing/search_channel.json` | 已有原始 fixture；抓取日期未记录 |
| 播放列表搜索 | `POST https://www.youtube.com/youtubei/v1/search` | InnerTube client context；当前实现不要求登录；结果以 `lockupViewModel` 返回，`contentId` 为 `PL` 前缀 | [PipePipe / InnerTube 开源实现](https://github.com/PipePipe-App/PipePipe) | `testing/search_playlist.json` | 2026-09-30 |
| 频道浏览 | `POST https://www.youtube.com/youtubei/v1/browse` | InnerTube client context；当前实现不要求登录；视频 tab 的条目以 `richItemRenderer.content.lockupViewModel` 返回，channel ID 取自 `metadata.channelMetadataRenderer.externalId` | [PipePipe / InnerTube 开源实现](https://github.com/PipePipe-App/PipePipe) | `testing/browse.json` + `testing/browse_continuation.json` | 2026-10-01 |
| 视频 Watch Next | `POST https://www.youtube.com/youtubei/v1/next` | InnerTube client context；当前实现不要求登录；主信息在 `twoColumnWatchNextResults` 的 `videoPrimaryInfoRenderer` / `videoSecondaryInfoRenderer`，续页条目走 `onResponseReceivedActions[].appendContinuationItemsAction.continuationItems` | [PipePipe / InnerTube 开源实现](https://github.com/PipePipe-App/PipePipe) | `testing/watch_next.json`（`videoId=dQw4w9WgXcQ`） | 2026-10-03 |
| 视频评论 | `POST https://www.youtube.com/youtubei/v1/next` | InnerTube client context；当前实现不要求登录；使用 Watch Next 返回的 comment continuation token 请求，评论条目以 `commentThreadRenderer` / `commentViewModel` 返回 | [PipePipe / InnerTube 开源实现](https://github.com/PipePipe-App/PipePipe) | `testing/comments.json` | 2026-10-03 |
| 视频 Player 播放器 | `POST https://www.youtube.com/youtubei/v1/player` | InnerTube client context；当前实现不要求登录；包含视频基本信息 `videoDetails`、播放状态 `playabilityStatus` 及媒体流格式 `streamingData` | [PipePipe / InnerTube 开源实现](https://github.com/PipePipe-App/PipePipe) | `testing/player.json`（`videoId=dQw4w9WgXcQ`） | 尚无成功响应 fixture；现存 fixture 为 `UNPLAYABLE` 业务失败响应、无 `streamingData`，待重抓 |
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

- 真实抓取脚本放在 `tool/capture/`，从 `packages/youtube/ypi/` 目录手动运行；输出到 `testing/<endpoint>.json`。脚本不进入 CI。
- fixture 只保存经过包级规则处理后的 HTTP response body，不保存 headers、Cookie、Token、带凭据 URL 或追踪凭据；HTTP status 和请求元数据记录在 `testing/README.md`。
- 写盘前脚本递归剔除 `trackingParams`、`clickTrackingParams`、`visitorData` 等追踪字段。
- 目标 fixture 已存在时脚本默认跳过并打印清单，`--force` 才覆盖，因此新增 endpoint 时其余 fixture 被跳过而抓取可正常进行。校验只保证结构可识别；结构合法但业务无效的响应（如失效频道返回的 200 且 `alerts[].alertRenderer.type` 为 `ERROR`）仍属业务失败，不得写入，人工确认也不能例外。
- 抓取遇到非 2xx、InnerTube 错误或无法识别结构时不得写入或覆盖 fixture，并返回非零状态。
- fixture 文件名：单端点用 `<endpoint>.json`；同端点多变体用 `<endpoint>_<variant>.json`；分页续页单独存 `<endpoint>_continuation.json`。
- 每个新增 endpoint 必须包含真实 fixture、MockClient 请求形状测试、fixture 解析测试和失败路径测试。
- 本包测试必须完全离线：禁止在测试中访问真实 YouTube 服务。CI 的 `Run Flutter Test` check 覆盖本包。本包无 Flutter 依赖，本地自查用 `dart test` 与 `dart analyze`，覆盖与 CI 相同的用例集。

## 新增 endpoint 流程

1. 确认来源：InnerTube 客户端实际请求为最高事实来源，可复核开源实现只作请求格式参考。无来源不实现。
2. 在 `tool/capture/fetch_fixtures.dart` 增加抓取分支与 `_validate*` 结构校验函数；业务语义无效的 200 响应（如失效频道）必须在校验层拦下。
3. 在本文件「已确认的来源与端点」表格加一行：Endpoint、Method/Path、请求/鉴权、来源、Fixture、实测日期。未实测的端点可登记但标注「尚无 / 未实测」，不实现。
4. 在 `testing/README.md` 的 Fixture 记录表加一行，补齐 HTTP status、非敏感请求参数、client context、来源与抓取日期；响应形态的特殊之处写进该文件的说明段。
5. 实现 service 方法与 DTO，一个 endpoint 对应 `YoutubeService` 上的一个方法；DTO 用 `NetworkYouTube` 前缀加端点或角色语义命名。
6. 写四项测试：fixture 解析、MockClient 请求形状、失败路径，加 fixture 本身。
7. 从包目录跑 `dart test` 与 `dart analyze --fatal-infos`，两者全绿。
