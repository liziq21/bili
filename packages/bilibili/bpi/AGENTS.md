# bpi API 包规范

本文件只记录 `packages/bilibili/bpi` 的平台特有规则。通用 API 包规则见 [`packages/AGENTS.md`](../../AGENTS.md)，根目录规则见 [`AGENTS.md`](../../../AGENTS.md)。

## 范围与依赖

- `bpi` 是纯 Dart Bilibili Web API 网络包，不依赖任何 workspace 包。
- `bpi` 只提供 Bilibili 响应 envelope、平台 DTO、HTTP client、WBI 签名和包级异常；不依赖 `data`、`model`、平台 wrapper 或 UI。
- `lib/bpi.dart` 只导出正式 service、DTO、typed exception、Token/客户端配置；parser、fixture、tool 和测试代码保持内部。
- 现有 API 行为以已保存的真实响应 fixture 和 Bilibili Web 客户端实际请求为准；社区逆向文档只作参考。

## 已确认的来源与端点

| Endpoint | Method / Path | 鉴权/签名 | 来源 | Fixture | 实测日期 |
|---|---|---|---|---|---|
| 搜索建议 | `GET /main/suggest` | 公共请求 | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/search_suggest.json` | 已有原始 fixture；抓取日期未记录 |
| 全站搜索 | `GET /x/web-interface/wbi/search/all/v2` | WBI | [WBI 文档](https://github.com/pskdje/bilibili-API-collect/blob/main/docs/misc/sign/wbi.md) | `testing/search_all.json` | 已有原始 fixture；抓取日期未记录 |
| 按类型搜索 | `GET /x/web-interface/wbi/search/type` | WBI | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/search_*.json` | 已有原始 fixture；抓取日期未记录 |
| 视频详情 | `GET /x/web-interface/view` | 公共请求 | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/video_detail.json` | 已有原始 fixture；抓取日期未记录 |
| 视频关系 | `GET /x/web-interface/archive/relation` | 公共请求 | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/video_relation.json` | 已有原始 fixture；抓取日期未记录 |
| 相关视频 | `GET /x/web-interface/archive/related` | 公共请求 | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/related_videos.json` | 已有原始 fixture；抓取日期未记录 |
| 评论 | `GET /x/v2/reply/*` | 公共请求 | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/reply_*.json` | 已有原始 fixture；抓取日期未记录 |
| 播放地址 | `GET /x/player/wbi/playurl` | WBI | [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/play_url.json` | 已有原始 fixture；抓取日期未记录 |
| 热门视频 | `GET /x/web-interface/popular` | 公共请求 | Bilibili 实际公开 Web API 响应 / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/popular.json` | 2026-09-25 |
| 排行榜/推荐 | 待探针确认 | 依端点而定 | 社区文档和 Bilibili Web 实际请求，未验证前不得实现 | 尚无 | 未实测 |

`https://api.bilibili.com/x/web-interface/ranking/v2` 可作为后续探针候选，但只有完成真实请求、保存响应和记录来源后才能进入实现。

## Bili DTO 与异常

- DTO 保留 Bilibili envelope 和 item 的原始语义及嵌套结构，例如 `code`、`message`、`ttl`、`data`、`owner`、`stat`。
- 现有搜索模型中的 `HtmlTitle`、图片、作者和统计字段是平台字段，不在 `bpi` 内转换为领域模型。
- 稳定 DTO 可以使用 `json_serializable`；对字段类型变化、广告/特殊 item 和不稳定的嵌套结构使用手写容错 `fromJson`。
- 缺少 `bvid`/`aid` 等核心标识的 item 必须跳过；其他缺失字段使用 `null` 或默认值，不让未知字段影响整个响应。
- Bili 错误按包内独立分类表达，至少区分网络错误、HTTP 错误、API 业务错误、JSON 解码错误和 WBI/鉴权错误；不使用跨包异常基类。
- WBI key、Cookie、登录 Token 和请求签名不得写入 fixture、日志或测试输出。

## 抓取与测试

- 真实抓取脚本放在 `tool/capture/`，从 `packages/bilibili/bpi/` 目录手动运行；输出到 `testing/<endpoint>.json`。
- fixture 只保存原始 HTTP response body，不保存 headers、Cookie、Token、带凭据 URL 或追踪凭据。
- 抓取遇到非 2xx、Bilibili 业务失败或无法识别结构时不得写入或覆盖 fixture，并返回非零状态。
- 每个新增 endpoint 必须包含真实 fixture、MockClient 请求形状测试、fixture 解析测试和失败路径测试。
- CI 只运行离线 `dart test`；禁止在单元测试或 CI 中访问真实 Bilibili 服务。
