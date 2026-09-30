# ypi 测试 fixture

`testing/` 中的 JSON 是 YouTube InnerTube API 经过追踪字段脱敏后的 HTTP response body，用于离线解析测试和接口结构回归。fixture 不包含 headers、Cookie、Token、client context 凭据或追踪字段。

## Fixture 记录

| Fixture | Endpoint | Method | HTTP status | 请求参数 | 来源 | 请求上下文 | 抓取日期 |
|---|---|---|---|---|---|---|---|
| `search_video.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 视频搜索 | 原始抓取日期未保留 |
| `search_channel.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 频道搜索 | 原始抓取日期未保留 |
| `search_playlist.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 200 | query=Flutter, hl=zh-CN, contentType=3（`params=QgIQAw==`） | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00，播放列表搜索 | 2026-09-30 |
| `search_suggest.json` | `https://suggestqueries.google.com/complete/search` | GET | 未知（原始记录未保留） | 未保留（原始记录未保留） | [Google Suggest](https://suggestqueries.google.com/complete/search) | 公共 | 原始抓取日期未保留 |
| `browse.json` | `https://www.youtube.com/youtubei/v1/browse` | POST | 200 | browseId=UCwXdFgeE9KYzlDUR7te5Suq, hl=zh-CN | [PipePipe / InnerTube](https://github.com/PipePipe-App/PipePipe) | WEB 2.20230818.00.00，浏览（频道/首页） | 2026-09-30 |

## 抓取规则

- 抓取脚本放在 `tool/capture/`，只手动执行，不进入 CI。
- 新 fixture 写入 `testing/<endpoint>.json` 前必须确认响应为成功响应且结构可识别，并在本文件记录实际 HTTP status 和非敏感请求参数。
- 失败响应不得写入或覆盖已有 fixture。
- 抓取脚本在保存 response body 前递归移除 `trackingParams`、`clickTrackingParams` 和 `visitorData`；除 response body 外不保存 headers、Cookie、Token、带凭据 URL、client context 凭据或其他追踪字段。
- 新增 endpoint 必须同步更新本文件和包级 `AGENTS.md` 的来源记录。
