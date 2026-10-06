# bpi API 包规范

本文件只记录 `packages/bilibili/bpi` 的平台特有规则。通用 API 包规则见 [`packages/AGENTS.md`](../../AGENTS.md)，根目录规则见 [`AGENTS.md`](../../../AGENTS.md)。

## 范围与依赖

- `bpi` 是纯 Dart Bilibili Web API 网络包，不依赖任何 workspace 包，也不依赖 Flutter SDK。
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
| 视频播放器信息/字幕 | `GET /x/player/v2` | 公共请求 | PipePipe / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/player_v2.json` | 2026-09-25 |
| 热门视频 | `GET /x/web-interface/popular` | 公共请求 | Bilibili 实际公开 Web API 响应 / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/popular.json` | 2026-09-25 |
| 排行榜 | `GET /x/web-interface/ranking/v2` | 公共请求 | Bilibili 实际公开 Web API 响应 / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/ranking.json` | 2026-09-25 |
| 直播间详情 | `GET /xlive/web-room/v1/index/getH5InfoByRoom` | 公共请求 | PipePipe / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/live_room_detail.json` | 2026-09-30 |
| 直播间播放流信息 | `GET /xlive/web-room/v2/index/getRoomPlayInfo` | 公共请求 | PipePipe / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/live_room_play_info.json` | 2026-10-02 |
| 用户名片/信息 | `GET /x/web-interface/card` | 公共请求 | PipePipe / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/user_card.json` | 2026-10-03 |
| 用户专栏文章列表 | `GET /x/space/article` | 公共请求 | PipePipe / [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) | `testing/user_articles.json` | 2026-10-04 |

`getH5InfoByRoom` 和 `getRoomPlayInfo` 已完成真实请求、fixture 保存和来源记录；实现与测试必须以对应的 fixture 为准。

## Bili DTO 与异常

- DTO 保留 Bilibili envelope 和 item 的原始语义及嵌套结构，例如 `code`、`message`、`ttl`、`data`、`owner`、`stat`。
- 现有搜索模型中的 `HtmlTitle`、图片、作者和统计字段是平台字段，不在 `bpi` 内转换为领域模型。
- 稳定 DTO 可以使用 `json_serializable`；对字段类型变化、广告/特殊 item 和不稳定的嵌套结构使用手写容错 `fromJson`。
- 缺少 `bvid`/`aid` 等核心标识的 item 必须跳过；其他缺失字段使用 `null` 或默认值，不让未知字段影响整个响应。
- Bili 错误按包内独立分类表达，至少区分网络错误、HTTP 错误、API 业务错误、JSON 解码错误和 WBI/鉴权错误；不使用跨包异常基类。
- WBI key、Cookie、登录 Token 和请求签名不得写入 fixture、日志或测试输出。

## 抓取与测试

- 真实抓取脚本放在 `tool/capture/`，从 `packages/bilibili/bpi/` 目录手动运行；输出到 `testing/<endpoint>.json`。脚本不进入 CI。
- fixture 保存 HTTP response body 本身，不保存 headers、Cookie、Token 或追踪凭据。`play_url.json` 的媒体流 URL 带 `e=`、`uparams`、`equery` 等时效签名参数，必须原样保留，解析测试依赖完整查询串。
- 写盘前脚本按 JSON 键扫描凭据（WBI key、Token、Cookie 等），命中即拒绝写入并非零退出；不做静默改写，因为重编码会改变 fixture 字节。
- 目标 fixture 已存在时脚本默认跳过并打印清单，`--force` 才覆盖，因此新增 endpoint 时其余 fixture 被跳过而抓取可正常进行。校验只保证结构可识别；结构合法但业务无效的响应仍属业务失败，人工确认也不得写入。
- 抓取遇到非 2xx、Bilibili 业务失败或无法识别结构时不得写入或覆盖 fixture，并返回非零状态。
- fixture 文件名：单端点用 `<endpoint>.json`；同端点多变体用 `<endpoint>_<variant>.json`（如 `search_<type>.json`、`reply_<variant>.json`）；分页续页单独存 `<endpoint>_continuation.json`。
- 每个新增 endpoint 必须包含真实 fixture、MockClient 请求形状测试、fixture 解析测试和失败路径测试。
- 本包测试必须完全离线：禁止在测试中访问真实 Bilibili 服务。CI 的 `Run Flutter Test` check 覆盖本包。本包无 Flutter 依赖，本地自查用 `dart test` 与 `dart analyze`，覆盖与 CI 相同的用例集。

## 新增 endpoint 流程

1. 确认来源：平台 Web 客户端实际请求为最高事实来源，社区逆向文档只作请求格式参考。无来源不实现。
2. 在 `tool/capture/fetch_fixtures.dart` 增加抓取分支与结构校验函数，响应通过校验后才写盘。
3. 在本文件「已确认的来源与端点」表格加一行：Endpoint、Method/Path、鉴权/签名、来源、Fixture、实测日期。
4. 在 `testing/README.md` 的 Fixture 记录表加一行，补齐非敏感请求参数、HTTP status、来源与抓取日期。
5. 实现 service 与 DTO，一个 endpoint 对应一个 service 方法；DTO 用 `Network` 前缀加平台或域标识加端点语义命名（`NetworkBili*` / `NetworkLive*` / `NetworkReply*`）。service 按域拆分为 `NetworkSearchDataSource`、`NetworkVideoDataSource`、`NetworkLiveDataSource`、`NetworkFeedDataSource`。
6. 写四项测试：fixture 解析、MockClient 请求形状、失败路径，加 fixture 本身。
7. 在 `test/doc_guardrail_test.dart` 的 `endpointSpecs` 登记新方法：填 `method`、`fixtures`（它的 fixture 文件名）与 `docCell`（它在上面两张表里的 Fixture 单元格文本，去反引号与 `testing/` 前缀，通配行写通配）。该测试强制七条一致性：每个公开方法都在表内、每个 fixture 文件都存在、每个 fixture 只被一个方法声明、`AGENTS.md` 端点表与 `testing/README.md` fixture 表逐行记录 spec 表声明的单元格且不多不少、每张表覆盖 `testing/` 下全部 fixture、每个 fixture 都由 `tool/capture/fetch_fixtures.dart` 真正写出、抓取脚本的 map 键确有循环写盘。漏登记任何一处该测试失败，所以本步必须在第 8 步之前完成。
8. 从包目录跑 `dart test` 与 `dart analyze --fatal-infos`，两者全绿。
