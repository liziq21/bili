# Packages Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.
>
> Primary Constructors 规则见根 AGENTS.md。

This directory contains shared packages and modules (`packages/*`).

## Packages Overview

- `bilibili/`: Bilibili API wrapper (`bpi`), remote data sources (`BiliVideoSearchRemoteDataSource`, etc.), models, and `BilibiliLocalizations` (l10n).
- `youtube/`: YouTube API wrapper (`ypi`), remote data sources (`YouTubeVideoSearchRemoteDataSource`, etc.), Chopper REST client, custom pure Dart Protobuf encoders (`YoutubeProtobufEncoder` / `YoutubeParamsBuilder`) for InnerTube endpoints, and `YoutubeLocalizations` (l10n).
- `components/`: Reusable UI widgets and Flutter components.
- `data/`: Core canonical models (`VideoModel`, `LiveRoomModel`, `CreatorProfile`, etc.), abstract `RemoteDataSource`, `SearchQuery`, filter/pagination primitives, and optional capability interfaces.
- `model/`: Shared domain models (`UserData` with `ServiceSource` & `ThemeConfig`, `Result<T>`).

## Package Classification & Tooling Commands

| Package | Type | Analysis Command | Test Command | Notes |
|---------|------|------------------|--------------|-------|
| `packages/bilibili` | Flutter | `flutter analyze` | `flutter test` | API client & l10n (imports Flutter SDK) |
| `packages/youtube` | Flutter | `flutter analyze` | `flutter test` | API client (`ypi`), l10n, Chopper & Protobuf encoder |
| `packages/components` | Flutter | `flutter analyze` | `flutter test` | UI component library (imports Flutter SDK) |
| `packages/data` | Dart-only | `dart analyze` | `dart test` | Shared models & RemoteDataSource abstraction |
| `packages/model` | Dart-only | `dart analyze` | `dart test` | Shared models (`UserData`, `Result<T>`) |

**Rule**: For Dart-only packages, use `dart` commands from the package directory. For Flutter packages (`bilibili`, `youtube`, `components`), use `flutter` commands.

## Data Layer & Remote Data Source Conventions

- `packages/data` owns domain models, `RemoteDataSource`, and `SearchQuery`.
- **`sourceId` Placement**: Each service module overrides `sourceId` on its `RemoteDataSource` implementation to identify origin — `sourceId` lives on the source, not on model instances.
- **Canonical Models**: Use `VideoModel` / `LiveRoomModel` (avoid deprecated `VideoInfoBase` / `LiveRoom` aliases).
- **Optional Capability Interfaces**: Design specific features as mixins or optional interfaces (e.g. `VideoDetailRemoteDataSource`, `VideoCommentRemoteDataSource`, `VideoFeedRemoteDataSource`, `LiveRoomFeedRemoteDataSource`). Implementations pick and choose supported capabilities; consumers check interface availability before invocation.

## API 子包通用规范

以下规则适用于 `packages/bilibili/bpi` 和 `packages/youtube/ypi`。包级 `AGENTS.md` 只记录平台特有规则，不得复制本节。

### 边界与依赖

- API 子包只负责平台请求、响应 envelope/DTO、网络错误和客户端配置。
- API 子包不得依赖任何 workspace 包，包括 `data`、`model`、平台 wrapper、`app` 或 UI 包。`ypi` 仅可在历史 `data` path dependency 移除前保留现有依赖；新增或修改的 API 代码不得扩大该依赖。除该过渡例外外，API 子包只允许依赖 Dart 第三方包和自身源码。
- API 子包不得返回或接收 `VideoModel`、`CreatorProfile`、`Page`、`Result` 等外层领域模型，也不得负责外层分页状态。
- `lib/<package>.dart` 的公共导出只包含 service、网络 DTO、包级 typed exception、Token/客户端配置；内部 parser、fixture、tool 和测试代码不导出。

### Endpoint 与来源

- 没有可复核来源和真实响应 fixture 的 endpoint 不得实现。
- 每个 endpoint 必须记录来源 URL、HTTP method、path、请求参数、鉴权/签名要求、实测日期和对应 fixture；记录在包级 `AGENTS.md`，fixture 抓取元数据记录在包级 `testing/README.md`。
- 平台 Web/App 客户端的实际请求是最高事实来源；社区逆向文档和开源实现是参考，不等同于官方稳定性保证。
- 不得使用第三方聚合 API 或抓取服务作为应用运行时数据源。

### DTO 与响应解析

- DTO 使用 `Network` 前缀，并按平台和端点命名，例如 `NetworkBiliPopularVideo`、`NetworkYouTubeBrowseVideo`；不得强行合并不同平台或不同端点的模型。
- DTO 尽量保持平台 JSON 的语义和层级，包括 envelope、`owner`、`stat` 等嵌套对象；不得在 API 包内提前转换为领域模型。
- DTO 只声明已确认的稳定业务字段，不在 DTO 中保存完整 raw JSON Map；未知字段允许被忽略。
- 稳定且扁平的字段可以使用 `json_serializable`；复杂 renderer、平台嵌套结构和不稳定字段使用手写 `fromJson` factory。生成代码只能由生成命令更新。
- 解析采用宽松策略：缺失或变化的非核心字段返回 `null`/默认值；缺少核心 ID 的 item 丢弃并继续处理；完整 envelope 或 HTTP/API 错误必须由 API 包明确处理。
- API 包的成功结果返回 DTO，失败抛出该包自己的 typed exception；不得把网络失败静默转换成空列表。

### 测试与真实请求

- 单元测试和 CI 不得访问真实网络；使用固定 JSON fixture、fake client 或 `MockClient`。
- 每个新增 endpoint 固定包含四项测试：真实响应 fixture、MockClient 请求形状测试、fixture 解析测试、失败路径测试。
- 真实请求只能通过 `tool/capture/` 下的抓取脚本手动执行，输出到 `testing/<endpoint>.json`；脚本不得进入 CI。
- fixture 只保存按包级规则处理后的 HTTP response body，不保存 headers、Cookie、Token、带凭据 URL 或追踪凭据。
- 抓取遇到非 2xx、业务失败或无法识别的响应结构时不得写入或覆盖 fixture，必须返回非零并打印状态。
- 抓取元数据、来源和非敏感请求参数记录在包级 `testing/README.md`，不得记录秘密。
