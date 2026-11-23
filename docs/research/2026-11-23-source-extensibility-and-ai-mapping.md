# 可扩展源设计与 AI 通用映射可行性

- 研究日期：2026-11-23
- 研究状态：已完成
- 关联分支：`explore/source-extensibility`
- 研究问题：本项目的可扩展源设计在大量新增源时是否会有维护压力？能否用一个定制的 AI 模型，把任意源的推荐数据转换为通用模型？低风险 PoC 能否验证声明式映射这条路？

## 1. 结论

1. **当前架构的源间耦合度已经控制得不错**：`MediaSource` 能力接口 + 源目录 + 组合根，新增源不会把 `if (source == ...)` 泄漏到 UI。真正的维护压力在每源的 API/DTO、分页、鉴权/签名、错误信封、媒体流、语义归一化和 fixture 契约测试，字段映射只是其中一部分。
2. **把“任意源 → 通用模型”做成运行时 AI 模型，技术上可行，生产上不推荐**。确定性、精确值（ID/URL/时间/计数）、静默错误、离线 CI、成本/延迟、隐私与提示注入、跨平台端上推理、模型版本与评测都会成为新的维护面。
3. **推荐把 AI 放在构建期/运维期**：用 LLM 从 fixture + 目标 schema 生成/修复声明式描述符或适配器代码，再用确定性的 fixture 契约测试验收；运行时零模型调用。
4. **推荐数据是最适合确定性映射的场景**（结构化、字段少、量大），不是最需要 AI 的场景。当前 YouTube 源没有匿名推荐 Feed（`videoFeedDataSources` 为空），瓶颈是能力/端点，不是映射。
5. **低风险 PoC 已验证声明式映射可行**：新增通用映射引擎与 B 站热门/排行/用户投稿描述符，用现有 fixture 对比旧 adapter，相关包共 155 个测试通过（data 20、bilibili 135，其中新增 21 个），并加入 fixture → canonical golden 的 conformance 门禁与 `schemaVersion`；workspace 严格分析和 test matrix 门禁均通过。

## 2. 现状与证据

### 2.1 架构形状

```
MediaSourceCatalog（组合根，注册源工厂）
  → MediaSource（17 个能力 getter，可空）
    → RemoteDataSource 能力接口（搜索/详情/评论/弹幕/媒体流/Feed/播放列表…）
      → 各源 adapter（Bili*/YouTube*）
        → bpi / ypi DTO 与 HTTP 客户端
```

App 层只依赖中立能力接口，`ServiceSourceProviders` 按能力注入 Repository，不按源 ID 分支。新增源的影响面是线性、局部的。

### 2.2 量化（2026-11-23 实测）

| 指标 | 数值 |
|---|---|
| `RemoteDataSource` 抽象类型 | 20 个（含基类与泛型 Feed） |
| `MediaSource` 能力 getter | 17 个 |
| Bilibili adapter + 映射模型 | ~1,694 行 |
| YouTube adapter | ~1,145 行 |
| 两包 DTO/fromJson | ~9,693 行 |
| 测试文件 | 174 个（test matrix 统计） |
| 能力覆盖 | Bilibili 17/17；YouTube 8/17 |
| 推荐 Feed | Bilibili 2 个（热门、排行）；YouTube 0 个 |

YouTube 缺失的 9 项里，有些是平台没有（直播、弹幕、聚合搜索），有些是**缺少可复核 fixture 而主动不声明**（如评论二级回复）。能力可用性不仅取决于 API 存在，还取决于 fixture/契约是否可验证。

### 2.3 维护成本构成

每加一个源，实际要做的是：

- endpoint 定义、请求参数、WBI/签名/设备指纹/visitorData、限流与重试；
- DTO 与宽松解析（envelope、renderer 树、嵌套 owner/stat）；
- 分页语义（页码 vs continuation token）；
- 错误信封（B 站 `code != 0`、YouTube playability/登录墙）；
- 媒体流（DASH/HLS、音视频分离、分片、请求头、清晰度）；
- 语义归一化；
- 能力缺口对应的 UI 不可用态；
- fixture 抓取、契约测试、l10n、golden；
- 跨源身份/去重（如果要做聚合推荐）。

LLM 只能覆盖其中“DTO → 通用模型”的一部分，其余部分不会因为有了模型而消失。

## 3. 为什么“任意源推荐数据 → 通用格式”不是纯映射

通用模型（`VideoModel`/`LiveRoomModel`）是有损、源中立的，难点是**语义契约**：

| 字段 | 语义陷阱 | 仓库中的例子 |
|---|---|---|
| `id` | 源内稳定，不是全局唯一；跨源聚合必须用 `(sourceId, id)` | B 站 `bvid`、YouTube `videoId` |
| `uploadDate` | 绝对时间 vs 相对文案；相对文案在解析时用 `DateTime.now()`，不可复现 | YouTube `publishedTimeText`（“3天前”/“3 days ago”） |
| `viewCount` | 平台口径不同；可能是缩写、可能过期 | YouTube `viewCountText`（“1.2万”/“1.2M”） |
| `duration` | 秒 / `mm:ss` / ISO 8601 混用 | B 站 `length` 与 `duration` 两种字段 |
| `title` | 可能含 HTML/控制字符 | B 站搜索标题 `<em class="keyword">Flutter</em>` |
| `url` | 要生成规范观看地址并做安全清洗，不能直接透传 API URL | `buildBiliWatchUrl` 会剥离 `? # / \` |
| `thumbnailUrl` | 协议相对、http、可能带时效签名 | `normalizeBiliUrl` / `normalizeYoutubeUrl` |
| `creatorProfileId` | 源内 ID，跨源不可比 | B 站 `mid`、YouTube `browseId` |
| `playlist.id` | 平台编码规则可能承载多个参数 | B 站 `<mid>:<seasonId>` |

再叠加传输层问题：推荐流的分页/continuation、匿名可用性、媒体地址鉴权、错误信封。这些都不是“把 JSON 映射成另一个 JSON”能解决的。

所以：

- **推荐数据是“容易确定性映射”的典型**：列表 + 少量字段 + 固定形状。
- **它也是最不适合运行时 LLM 的典型**：量大、刷新频繁、要求低延迟、分页必须稳定。
- **YouTube 推荐 Feed 目前根本不可用**：`videoFeedDataSources => const []`。瓶颈是匿名端点/能力，不是映射。

## 4. 定制 AI 模型的可行性评估

### 4.1 技术可行的部分

- LLM 做 schema matching 有潜力，但上下文太少或太多都会降低质量，且需要人工验证（[Schema Matching with LLMs: an Experimental Study, 2024](https://arxiv.org/abs/2407.11852)）。
- 小模型 + 大模型级联（检索候选 → LLM 重排）可以降成本，但小模型仍需训练数据（[Magneto, 2024](https://arxiv.org/abs/2412.08194)）。
- LLM 在 schema matching 上仍会幻觉，需要知识图谱/RAG 等手段缓解（[KG-RAG4SM, 2025](https://arxiv.org/abs/2501.08686)）。
- 结构化抽取中，提示策略比模型大小更重要；约束输出能提高“结构合法率”，但可能增加“语义错误”（[LLMStructBench, 2026](https://arxiv.org/abs/2602.14743)）。
- 对小模型，硬性 JSON schema 约束存在“constraint tax”：输出更合法，但答案/可执行正确率可能下降（[The Constraint Tax, 2026](https://arxiv.org/abs/2605.26128)）。
- LLM 生成 Web API 调用代码仍会幻觉 endpoint、用错参数，开源模型在基准上解决率不足 40%（[WAPIIBench, 2025](https://arxiv.org/abs/2509.20172)）。

结论：**“多数字段大致正确”可以做到；“任意源、生产级、确定性正确”做不到。**

### 4.2 生产级不可行的原因

| 问题 | 说明 |
|---|---|
| 精确值 | ID、URL、时间戳、计数、时长是硬约束；LLM 擅长语义，不擅长逐字符精确与算术 |
| 静默错误 | 映射错了不会抛异常，只会显示错数据；比崩溃更难发现 |
| 不确定性 | 同一输入两次输出可能不同；分页、去重、缓存 key 都会受影响 |
| 可测试性 | CI 禁止真实网络；运行时 LLM 要么 mock（测不到真实路径），要么联网（违规）；录播输出只测了“冻结的转录” |
| 成本/延迟 | 每次刷新 × 每条 × 每用户；推荐流是最不适合按条调用模型的场景 |
| 隐私/合规 | 把第三方 API payload 发给外部模型是数据出境；端上模型可避免，但见 4.3 |
| 提示注入 | 第三方 payload 是不可信输入，标题/描述里可埋指令；这是间接提示注入的典型面（[SecAlign, 2024](https://arxiv.org/abs/2410.05451)） |
| 模型漂移 | 托管模型会静默升级；本地模型要随源/通用模型变化重训；两者都需要新的评测体系 |
| MLOps | 数据生成、训练、评测、发布、监控、回滚，是一整套新流水线 |

### 4.3 端上“定制小模型”的额外问题

本项目要跑 Android、iOS、Linux、macOS、Windows、Web 六个平台。端上小模型意味着模型体积、量化、内存、耗电、首 token 延迟、六套推理后端（Web 尤其困难）、随 App 发版、仍然需要确定性校验与回退。当前规模下不划算。

### 4.4 什么时候值得考虑

| 源数量/形态 | 建议 |
|---|---|
| < 20 个，主要是结构化 JSON | 声明式描述符 + LLM 辅助编写；不要运行时模型 |
| 20–100 个，混合结构 | 描述符 + 每源 escape hatch + LLM 漂移修复 |
| 100+ 个，大量非结构化/HTML | 运行时 LLM 抽取 + 严格护栏 + 确定性缓存/晋升，才可能摊薄成本 |

若做实验，必须用现有 adapter 作为 oracle 构造评测集，并留出未见过的新 schema；指标至少包含字段级 exact match、**静默错误率**、schema 合法率、P95 延迟、单次成本。建议门槛：静默错误率 < 0.1%，且在新源上优于描述符引擎，才考虑上线。

## 5. 方案与取舍

### 5.1 声明式描述符 + 通用引擎（首选）

每源一份描述符 + 一个通用引擎。描述符是数据，可 diff、可校验、可版本化、可由 LLM 生成。

```yaml
source: bilibili
capability: videoFeed
schemaVersion: 1
feeds:
  - id: popular
    title: 热门视频
    request:
      method: GET
      path: /x/web-interface/popular
      query: { pn: $page, ps: 20 }
    envelope: { ok: "$.code == 0", error: "$.message" }
    pagination: { hasMore: "$.data.no_more == false" }
    items: "$.data.list[*]"
    map:
      id:                 { path: "$.bvid" }
      title:              { path: "$.title", transform: htmlText }
      url:                { transform: watchUrl, args: { id: "$.bvid" } }
      thumbnailUrl:       { path: "$.pic", transform: httpsUrl }
      viewCount:          { path: "$.stat.view" }
      uploadDate:         { path: "$.pubdate", transform: epochSeconds }
      duration:           { path: "$.duration" }
      creatorProfileName: { path: "$.owner.name" }
      creatorProfileId:   { path: "$.owner.mid", transform: string }
```

关键设计：transform 是受控函数库；描述符有 `schemaVersion`；复杂源保留 Dart escape hatch；引擎实现为另一个 `VideoFeedRemoteDataSource`，与现有 adapter 并存，渐进迁移。

### 5.2 LLM 辅助编写（构建期）

```
tool/capture 抓 fixture
  → LLM 读 fixture + 目标 schema + transform 目录
  → 生成描述符/适配器草稿
  → tool/mapping_conformance 用 fixture 跑出 canonical JSON
  → 与 golden 对比 + 人工 review
  → 提交描述符 + fixture + golden
  → CI 离线跑契约测试
```

这与“LLM 生成转换代码”的研究方向一致：SQLMorpher 让 LLM 生成 SQL 做数据转换（[2309.01957](https://arxiv.org/abs/2309.01957)），TabulaX 让 LLM 生成可读的转换函数（[2411.17110](https://arxiv.org/abs/2411.17110)）。**产物是确定性代码/配置，不是运行时推理。**

### 5.3 运维期：漂移检测 + LLM 修复建议

上游 schema 变化时，契约测试先红；再由 LLM 读 diff/fixture 生成修复 patch，跑 shadow test，人工批准后合并。AegisFlow 就是这类“检测 → 修复 → 验证”的数据管道思路（[2610.06971](https://arxiv.org/abs/2610.06971)）。

### 5.4 运行时 LLM 的边界

只建议用在允许模糊的地方：搜索 query → 结构化 `SearchQuery` 的意图解析、标题清洗、语言/分类、跨源去重/实体对齐、非结构化 HTML 源的长尾抽取。核心字段（ID/URL/时间/计数/时长）仍应走确定性路径。

### 5.5 方案对比

| 方案 | 确定性 | 新增源边际成本 | 运行成本 | 可测试性 | 建议 |
|---|---|---|---|---|---|
| 手写 adapter（现状） | 高 | 高 | 零 | 高 | 少量源 |
| 声明式描述符 + 通用引擎 | 高 | 低 | 零 | 高 | ✅ 主推 |
| LLM 构建期生成描述符/代码 | 高（产物确定） | 很低 | 零 | 高 | ✅ 推荐 |
| 运维期 LLM 漂移修复 | 高（经测试） | 低 | 很低 | 高 | ✅ 推荐 |
| 运行时 LLM 核心字段归一化 | 低 | 低 | 高 | 低 | ❌ 不推荐 |
| 端上定制小模型 | 中低 | 中 | 设备成本 | 低 | ❌ 当前不推荐 |

## 6. PoC 与验证

### 6.1 实现

- `packages/data/lib/src/mapping/`
  - `json_path.dart`：最小 JSON path（`$`、点号、`[n]`、`[*]`）。
  - `mapping_descriptor.dart`：`FieldMapping` / `FeedMappingDescriptor`，后者带 `schemaVersion`，分页支持 `hasMorePath` 或 `totalCountPath` + `pageSize`。
  - `mapping_transform.dart`：确定性 transform 注册表（`string`、`int`、`parseCount`、`parseDuration`、`epochSeconds`、`httpsUrl`、`htmlText`、`pathSegment`）。
  - `declarative_feed_data_source.dart`：`MappingEvaluator` + `DeclarativeFeedDataSource<T>`，暴露 `schemaVersion`，并按描述符计算 `totalPages`。
  - `mapping_conformance.dart`：结构化 JSON 差异比较，供测试与 CLI 共用。
- `packages/data/lib/src/model/video_model.dart` / `live_room_model.dart`
  - 各自声明 `schemaVersion` 常量，描述符显式指向该版本。
- `packages/bilibili/lib/src/data/source/declarative/bili_feed_descriptors.dart`
  - 共享的 B 站视频字段规则；
  - 热门 / 排行两个 `FeedMappingDescriptor`；
  - 用户投稿描述符（`$.data.list.vlist[*]`，`totalCountPath` + `pageSize`），用于验证第二种分页语义与不同 item 形状；
  - B 站专属 transform（`biliWatchUrl`、`biliUrl`）；
  - `createBiliPopularDeclarativeFeed` / `createBiliRankingDeclarativeFeed` / `createBiliUserVideosDeclarativeFeed`。
- `packages/bilibili/lib/src/data/source/declarative/bili_feed_conformance.dart`
  - `canonicalVideoJson`：把 `VideoModel` 序列化为稳定、可 diff 的 canonical JSON。
- `packages/bilibili/tool/mapping_conformance.dart`
  - 从 `packages/bilibili` 运行：`dart run tool/mapping_conformance.dart --feed popular`；
  - `--update` 从旧 adapter 重新生成 golden，避免用声明式引擎自己的输出自证。
- `packages/bilibili/test/fixtures/declarative/{popular,ranking}.json`
  - 由旧 adapter 生成的 canonical golden，作为 conformance 门的基准。
- 现有 `BiliPopularVideoFeedRemoteDataSource` / `BiliRankingVideoFeedRemoteDataSource` 未改动，未接入 `Bili.videoFeedDataSources`，因此 PoC 不影响运行时。

### 6.2 测试与结果

新增：

- `packages/data/test/declarative_feed_data_source_test.dart`：8 个测试，覆盖 transform、envelope、分页（`hasMore` 与 total count）、丢弃无效条目、未知 transform、`schemaVersion`、JSON path。
- `packages/data/test/mapping_conformance_test.dart`：3 个测试，覆盖结构化 JSON 差异比较的相等、嵌套值/缺失 key/列表长度、类型不匹配。
- `packages/bilibili/test/bili_declarative_feed_test.dart`：5 个测试，使用真实 `popular.json` / `ranking.json` fixture，逐项对比声明式 Feed 与旧 adapter 的输出；覆盖 envelope 失败、`no_more`、缺少 `bvid` 的条目。
- `packages/bilibili/test/bili_mapping_conformance_test.dart`：3 个测试，把声明式输出与由旧 adapter 生成的 canonical golden 做结构 diff，并校验描述符指向的 canonical `schemaVersion`。
- `packages/bilibili/test/bili_user_videos_mapping_test.dart`：2 个测试，用 `space_videos.json` 对比声明式用户投稿 Feed 与 `BiliUserVideosRemoteDataSource`，覆盖 `totalCountPath` 分页与不同的 item 字段形状。

实际执行（Flutter 3.50.0 / Dart 3.14.0，与 `.fvmrc` 一致）：

```text
(cd packages/bilibili && dart run tool/mapping_conformance.dart --feed popular)  # 20 items conform
(cd packages/bilibili && dart run tool/mapping_conformance.dart --feed ranking)  # 100 items conform
(cd packages/data && dart analyze --fatal-infos --fatal-warnings)               # No issues found!
(cd packages/data && dart test)                                                  # 20 tests passed
(cd packages/bilibili && flutter analyze --fatal-infos --fatal-warnings)         # No issues found!
(cd packages/bilibili && flutter test test/)                                     # 135 tests passed
flutter analyze --fatal-infos --fatal-warnings                                   # No issues found!
python3 tool/test_matrix.py --check                                              # 177/177 classified
```

结论：对 B 站热门、排行与用户投稿，声明式描述符产出的 `VideoModel` 与旧 adapter 一致；热门/排行由 conformance 门禁再用旧 adapter 生成的 golden 锁住，用户投稿由等价性测试锁住。PoC 的风险被限制在新增文件与测试内。

### 6.3 限制

- 引擎目前只覆盖“简单 JSON feed”：不处理签名、WBI、continuation token、媒体流、复杂 renderer 树；这些继续用 Dart adapter。分页已支持布尔 `hasMore` 与 total count，continuation token 未支持。
- `tool/mapping_conformance.dart` 已实现，但尚未接入独立的 CI job；当前由 `packages/bilibili` 的测试套件执行同一 conformance 检查。
- LLM 生成描述符的流水线尚未实现；本次只验证“确定性端”可行。
- 三个 feed 的 PoC 仍然引入了共享引擎代码；在 3 个源的规模上，代码量不一定下降。收益来自第 N 个简单源的边际成本：第三个 feed 主要新增一份字段表 + 描述符 + 一个等价性测试，引擎只为 total-count 分页增加了约 20 行。
- 用户投稿是 mapping-only PoC，尚未接入生产 capability；它用于验证不同 item 形状与分页语义，不代表推荐流已经全部迁移。
- 跨源聚合的 `(sourceId, id)` 复合键尚未引入；`schemaVersion` 已加入 descriptor 与 canonical model，但还没有迁移/升级策略。

## 7. 未决问题

- 是否把描述符从 Dart 常量迁移到 YAML/JSON 资产，以便非 Dart 工具和 LLM 直接生成？
- 是否把 `tool/mapping_conformance.dart` 接入独立 CI job，还是继续由包测试套件承担？
- 是否为跨源聚合引入 `(sourceId, id)` 复合键？
- 是否需要为 continuation token 分页增加描述符字段？
- 是否把用户投稿的声明式映射接入生产 capability，还是保持 mapping-only PoC？
- 运行时 LLM 兜底是否需要，以及如何在“测试/CI 不联网”的约束下评测？
- `app/AGENTS.md` 引用的 `docs/source-injection.md` 在当前 checkout 中不存在；源注入契约文档需要补回。

## 8. 参考资料

### 仓库内

- [`AGENTS.md`](../../AGENTS.md) — 模块分离、静态分析、测试与格式规则。
- [`packages/AGENTS.md`](../../packages/AGENTS.md) — 包边界、能力接口、API 子包规则。
- [`docs/product-boundary.md`](../product-boundary.md) — 只读客户端边界。
- [`packages/data/lib/src/remote_data_source.dart`](../../packages/data/lib/src/remote_data_source.dart) — 能力接口。
- [`packages/bilibili/lib/src/bili.dart`](../../packages/bilibili/lib/src/bili.dart) — B 站源与 Feed 注册。
- [`packages/bilibili/lib/src/data/model/video_model.dart`](../../packages/bilibili/lib/src/data/model/video_model.dart) — DTO → `VideoModel` 的现有映射。
- [`packages/youtube/lib/src/data/source/search/youtube_video_search_remote_data_source.dart`](../../packages/youtube/lib/src/data/source/search/youtube_video_search_remote_data_source.dart) — 相对日期、缩写计数、时长解析的现有实现。
- [`packages/bilibili/bpi/testing/popular.json`](../../packages/bilibili/bpi/testing/popular.json)、[`ranking.json`](../../packages/bilibili/bpi/testing/ranking.json) — PoC 使用的真实 fixture。
- [`packages/data/lib/src/mapping/`](../../packages/data/lib/src/mapping/) — 本次 PoC 的通用映射引擎。
- [`packages/bilibili/lib/src/data/source/declarative/`](../../packages/bilibili/lib/src/data/source/declarative/) — 本次 PoC 的 B 站描述符。

### 外部研究（不自动构成本仓库规则）

- [Schema Matching with Large Language Models: an Experimental Study (2024)](https://arxiv.org/abs/2407.11852)
- [Magneto: Combining Small and Large Language Models for Schema Matching (2024)](https://arxiv.org/abs/2412.08194)
- [KG-RAG4SM: Knowledge Graph-based RAG for Schema Matching (2025)](https://arxiv.org/abs/2501.08686)
- [LLMStructBench: Benchmarking LLM Structured Data Extraction (2026)](https://arxiv.org/abs/2602.14743)
- [The Constraint Tax: Validity-Correctness Tradeoffs in Structured Outputs for SLMs (2026)](https://arxiv.org/abs/2605.26128)
- [Benchmarking Web API Integration Code Generation (2025)](https://arxiv.org/abs/2509.20172)
- [Automatic Data Transformation Using LLM: SQLMorpher (2023)](https://arxiv.org/abs/2309.01957)
- [TabulaX: LLM for Multi-Class Table Transformations (2024)](https://arxiv.org/abs/2411.17110)
- [AegisFlow: Agentic Self-Healing for Fragile Data Ecosystems (2026)](https://arxiv.org/abs/2610.06971)
- [SecAlign: Defending Against Prompt Injection (2024)](https://arxiv.org/abs/2410.05451)
