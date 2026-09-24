# bpi 测试 fixture

`testing/` 中的 JSON 是 Bilibili API 的原始 HTTP response body，用于离线解析测试和接口结构回归。fixture 不包含 headers、Cookie、Token、WBI key 或其他凭据。

## Fixture 记录

| Fixture | Endpoint | Method | 请求参数 | 来源 | 鉴权 | 抓取日期 |
|---|---|---|---|---|---|---|
| `search_suggest.json` | `/main/suggest` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | 公共 | 原始抓取日期未保留 |
| `search_all.json` | `/x/web-interface/wbi/search/all/v2` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | WBI | 原始抓取日期未保留 |
| `search_*.json` | `/x/web-interface/wbi/search/type` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | WBI | 原始抓取日期未保留 |
| `video_detail.json` | `/x/web-interface/view` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | 公共 | 原始抓取日期未保留 |
| `video_relation.json` | `/x/web-interface/archive/relation` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | 公共 | 原始抓取日期未保留 |
| `related_videos.json` | `/x/web-interface/archive/related` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | 公共 | 原始抓取日期未保留 |
| `reply_*.json` | `/x/v2/reply/*` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | 公共 | 原始抓取日期未保留 |
| `play_url.json` | `/x/player/wbi/playurl` | GET | 未保留（原始记录未保留） | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | WBI | 原始抓取日期未保留 |

## 抓取规则

- 抓取脚本放在 `tool/capture/`，只手动执行，不进入 CI。
- 新 fixture 写入 `testing/<endpoint>.json` 前必须确认响应为成功响应且结构可识别，并在本文件记录实际非敏感请求参数。
- 失败响应不得写入或覆盖已有 fixture。
- 原始 response body 之外不保存 headers、Cookie、Token、带凭据 URL 或追踪凭据。
- 新增 endpoint 必须同步更新本文件和包级 `AGENTS.md` 的来源记录。
