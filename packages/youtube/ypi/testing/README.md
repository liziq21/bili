# ypi 测试 fixture

`testing/` 中的 JSON 是 YouTube InnerTube API 经过追踪字段脱敏后的 HTTP response body，用于离线解析测试和接口结构回归。fixture 不包含 headers、Cookie、Token、client context 凭据或追踪字段。

## Fixture 记录

| Fixture | Endpoint | Method | HTTP status | 请求参数 | 来源 | 请求上下文 | 抓取日期 |
|---|---|---|---|---|---|---|---|
| `search_video.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 视频搜索 | 原始抓取日期未保留 |
| `search_channel.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 频道搜索 | 原始抓取日期未保留 |
| `search_playlist.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 200 | query=Flutter, hl=zh-CN, contentType=3（`params=QgIQAw==`） | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00，播放列表搜索 | 2026-09-30 |
| `search_suggest.json` | `https://suggestqueries.google.com/complete/search` | GET | 未知（原始记录未保留） | 未保留（原始记录未保留） | [Google Suggest](https://suggestqueries.google.com/complete/search) | 公共 | 原始抓取日期未保留 |

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
