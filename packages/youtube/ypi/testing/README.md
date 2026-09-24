# ypi 测试 fixture

`testing/` 中的 JSON 是 YouTube InnerTube API 的原始 HTTP response body，用于离线解析测试和接口结构回归。fixture 不包含 headers、Cookie、Token、client context 凭据或追踪字段。

## Fixture 记录

| Fixture | Endpoint | Method | HTTP status | 请求参数 | 来源 | 请求上下文 | 抓取日期 |
|---|---|---|---|---|---|---|---|
| `search_video.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 视频搜索 | 原始抓取日期未保留 |
| `search_channel.json` | `https://www.youtube.com/youtubei/v1/search` | POST | 未知（原始记录未保留） | 未保留（原始记录未保留） | [YouTube.js](https://github.com/LuanRT/YouTube.js) | 频道搜索 | 原始抓取日期未保留 |
| `search_suggest.json` | `https://suggestqueries.google.com/complete/search` | GET | 未知（原始记录未保留） | 未保留（原始记录未保留） | [Google Suggest](https://suggestqueries.google.com/complete/search) | 公共 | 原始抓取日期未保留 |

## 抓取规则

- 抓取脚本放在 `tool/capture/`，只手动执行，不进入 CI。
- 新 fixture 写入 `testing/<endpoint>.json` 前必须确认响应为成功响应且结构可识别，并在本文件记录实际 HTTP status 和非敏感请求参数。
- 失败响应不得写入或覆盖已有 fixture。
- 原始 response body 之外不保存 headers、Cookie、Token、带凭据 URL、client context 凭据或追踪字段。
- 新增 endpoint 必须同步更新本文件和包级 `AGENTS.md` 的来源记录。
