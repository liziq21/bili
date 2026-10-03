# ypi 测试 fixture

`testing/` 中的 JSON 是 YouTube InnerTube API 经过追踪字段脱敏后的 HTTP response body，用于离线解析测试和接口结构回归。fixture 不包含 headers、Cookie、Token、client context 凭据或追踪字段。

## Fixture 记录

| Fixture | Endpoint | Method | HTTP status | 请求参数 | 来源 | 请求上下文 | 抓取日期 |
|---|---|---|---|---|---|---|---|
| `search_video.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 视频搜索 | 原始抓取日期未保留 |
| `search_channel.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 频道搜索 | 原始抓取日期未保留 |
| `search_playlist.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 200 | query=Flutter, hl=zh-CN, contentType=3（`params=QgIQAw==`） | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00，播放列表搜索 | 2026-09-30 |
| `search_suggest.json` | `https://suggestqueries.google.com/complete/search` | GET | 未知（原始记录未保留） | 未保留（原始记录未保留） | [Google Suggest](https://suggestqueries.google.com/complete/search) | 公共 | 原始抓取日期未保留 |
| `browse.json` | `https://www.youtube.com/youtubei/v1/browse` | POST | 200 | browseId=`UCuAXFkgsw1L7xaCfnd5JJOw`, params=`EgZ2aWRlb3PyBgQKAjoA`（视频 tab） | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00, hl=zh-CN | 2026-10-01 |
| `browse_continuation.json` | `https://www.youtube.com/youtubei/v1/browse` | POST | 200 | continuation=取自 `browse.json` 的 richGrid 续页 token | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00, hl=zh-CN | 2026-10-01 |
| `browse_playlist.json` | `https://www.youtube.com/youtubei/v1/browse` | POST | 200 | browseId=`VLPL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ` | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00, hl=zh-CN | 2026-09-30 |
| `watch_next.json` | `https://www.youtube.com/youtubei/v1/next` | POST | 200 | videoId=`dQw4w9WgXcQ` | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00, hl=zh-CN | 2026-10-02 |


## 频道浏览的 renderer 形态

`browseChannel` 解析 `richGridRenderer` 下的 `richItemRenderer.content.lockupViewModel`，不解析 `videoRenderer`。依据是 2026-10-01 的实测：`UCuAXFkgsw1L7xaCfnd5JJOw` 视频 tab 的响应里 30 条条目**全部**是 `lockupViewModel`（`contentType: LOCKUP_CONTENT_TYPE_VIDEO`），`videoRenderer` 出现 0 次。`lockupViewModel` 的 `contentId` 是 `PXC_` 前缀而非 `dQw4w9WgXcQ` 形式的视频 ID，是 YouTube 的内部 ID，不保证等于 watch 页 URL 里的 ID。

header 有两种形态，取决于频道状态。有效频道的 `pageHeaderRenderer` 只有 `pageTitle` 和 `content`，**不含 channel ID**；ID 要从 `metadata.channelMetadataRenderer.externalId` 取。已失效频道返回 `c4TabbedHeaderRenderer` 且 `alerts[].alertRenderer.type` 为 `ERROR`。

失效频道的响应值得单独记一笔：它 HTTP 200、没有顶层 `error` 字段，`contents` 也是对象，只看这两处会把它当成一次成功的空响应。判定必须查 `alerts`。前一版 `browse.json` 存的就是这种响应（`browseId=UCwXdFgeE9KYzlDUR7te5Suq`，已失效），所以 `fetch_fixtures.dart` 现在有 `_validateBrowseResponse` 在写盘前拦它。

续页（`onResponseReceivedActions[].appendContinuationItemsAction.continuationItems`）返回与首屏 rich grid 相同的 `richItemRenderer` 条目，不是 section 结构。实测续页同样是 30 条 `richItemRenderer` + 1 个 `continuationItemRenderer`。

## 视频 Watch Next 的 renderer 形态

`getWatchNext` 解析 `twoColumnWatchNextResults.results.results.contents` 中的 `videoPrimaryInfoRenderer`（主视频标题、播放量、发布时间）和 `videoSecondaryInfoRenderer`（频道作者 ID、频道名称、头像、订阅数、视频简介）。续页响应的条目在 `onResponseReceivedActions[].appendContinuationItemsAction.continuationItems`，解析器两条路径都读。

抛错行为按实现分四种，不要照着文档想当然：

- 顶层有 `error` 字段 → `YpiInnerTubeException`（带 code / continuation / reason）。
- `alerts[].alertRenderer.type` 有值且非 `OK`（如 `ERROR`）→ `YpiInnerTubeException`，`reason` 取 alert 文本（`simpleText` 与 `runs` 两种形态都认；都取不到时退化为 `InnerTube alert: <type>`）。与 `network_youtube_browse.dart` 对失效频道的口径一致。
- 缺 `videoId` 或缺 `videoPrimaryInfoRenderer` 标题 → `FormatException`。标题是必填项：失效或受限视频会返回 HTTP 200 且 `results.results.contents` 非空，但两个 renderer 循环全程空转，只靠 `videoId` 兜底就会放行一个标题与作者全 null 的「成功」响应。
- `owner` 解析失败（`FormatException`）→ 忽略，`owner` 置 null。播放量、发布时间、视频简介缺失同理，都是可空字段。

## 播放列表搜索的 renderer 形态

`searchPlaylists` 解析 `lockupViewModel`，不解析 `playlistRenderer`。依据是实测：`contentType: 3` 的搜索响应里 **`playlistRenderer` 出现 0 次**，播放列表以 `contentId` 带 `PL` 前缀的 `lockupViewModel` 到达。2026-09-30 跨三个 client（WEB 2.20230818.00.00、WEB 2.20240726.00.00、ANDROID 19.09.37）各测一次，结论一致；2026-10-01 用 WEB 2.20230818.00.00 复测，`playlistRenderer` 仍为 0、`lockupViewModel` 为 2、`estimatedResults` 为 3628246（`search_playlist.json` 记录的是 3628154，同期取值，结果数随时间漂移）。

fixture 本身是 `0c11d88` 落盘的：该提交经 `tool/capture/fetch_fixtures.dart` 抓取并写入 `testing/search_playlist.json`，上表的请求方法、client、参数与抓取日期即该提交的记录。

若改回解析 `playlistRenderer`，`from_json_test.dart` 的 fixture 用例仍会全绿而真实响应解析出空列表——这正是 `0c11d88` 之前的缺陷形态：fixture 是按假定结构手写的，而非抓取所得。除查提交记录外，还可在不依赖提交历史的情况下复核：`from_json_test.dart` 中断言的具体 `playlistId`、owner `browseId` 与 `videoCountText` 是否三者自洽，手写数据无法同时对上真实播放列表的这三项。

## 抓取规则

- 抓取脚本放在 `tool/capture/`，只手动执行，不进入 CI。
- 新 fixture 写入 `testing/<endpoint>.json` 前必须确认响应为成功响应且结构可识别，并在本文件记录实际 HTTP status 和非敏感请求参数。
- 失败响应不得写入或覆盖已有 fixture。
- 抓取脚本在保存 response body 前递归移除 `trackingParams`、`clickTrackingParams` 和 `visitorData`；除 response body 外不保存 headers、Cookie、Token、带凭据 URL、client context 凭据或其他追踪字段。
- 新增 endpoint 必须同步更新本文件和包级 `AGENTS.md` 的来源记录。
