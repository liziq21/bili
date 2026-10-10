# App Layer Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.
>
> Primary Constructors 规则见根 AGENTS.md。

This directory contains the main Flutter application (`app/`).

## App Structure & Architecture

- `lib/`: Application source code
  - `feature/`: Screen-level UI features (`home/`, `search/`, `live/`, `video/`, `space/`, `setting/`, `theme/`, `not_found/`).
  - `data/`: Repository implementations and local data models bridging database to domain layer.
    - `repository/`: Repository implementations (`AppVideoSearchRepository`, `AppUserSearchRepository`, `AppLiveRoomSearchRepository`, etc.).
    - `repository/recent_search_query/`: History repository backed by Drift.
  - `repository/user_data/`: Preferences repository backed by `PreferencesDataSource`.
  - `database/`: Drift (SQLite) database, table definitions, DAOs.
  - `datastore/`: Shared preferences / persistent key-value storage (`PreferencesDataSource`).
  - `domain/`: Use cases and business logic (`GetRecentSearchQueriesUseCase`, `GetSearchContentsUseCase`).
  - `l10n/`: ARB files and generated localizations (`AppLocalizations`).
  - `providers/`: Dependency injection wiring via `flutter_bloc` `RepositoryProvider`.
  - `routing/`: `go_router` route configuration.
  - `styles/`, `ui/`, `utils/`: Shared UI utilities.
- Platform code: `android/`, `ios/`, `linux/`, `web/`.
- `test/`: Unit and widget tests mirroring `lib/`.

## Core Principles & Design Patterns

### Extensible Data Sources & Local-Only Personalization
- The application relies on third-party extensible data sources without platform login, online commenting, or platform-specific coin features.
- Personalization features such as subscriptions, favorites, and watch history are strictly managed in local storage (Drift SQLite / SharedPreferences).

### Global Style Access (`$styles`)
- Defined in `lib/main.dart` as `AppStyle get $styles => AppScaffold.style`.
- Access the live singleton directly (`$styles.colors`, `$styles.corners`, `$styles.insets`, `$styles.text`, etc.) — do not create local copies.
- **Strict Rule**: When writing or updating UI components (including Stitch designs), strictly map visual elements to `$styles` design tokens. Never hardcode colors or stitch-specific style constants.
- See [`docs/design-system.md`](docs/design-system.md) for the color-literal policy, token roles, and contrast requirements. Within `app/lib/`, [`lib/design/brand_palette.dart`](lib/design/brand_palette.dart) is the **only** file where color literals are allowed. Decision rationale and measurements are deliberately kept out of the repository — read them from the git history of the commits that established each rule.

### Dependency Injection & Source Providers (`ServiceSourceProviders`)
- The complete source-injection contract is [`docs/source-injection.md`](docs/source-injection.md).
- `app/lib/data/` depends only on neutral capability interfaces from `packages/data`; it must not import concrete service packages such as `bilibili` or `youtube`.
- The composition root (`providers/media_sources_provider.dart`) registers source definitions and factories. The root tree injects `MediaSourceCatalog`, never live source instances.
- An empty source catalog is valid. Resolution returns `null` when no source exists; an empty string is not a no-source sentinel.
- `ServiceSourceProviders` creates and owns one route-scoped source instance, injects repositories from that instance's capabilities, and closes it exactly once on disposal.
- Repository injection is capability-driven, not a source-ID switch. A missing optional capability omits its provider and the UI must show an explicit unavailable state.
- Screen-level BlocProviders are assembled at the route/route-data composition point and receive dependencies from the source scope.

### Optional Capability Interfaces & Route Validation
- Data source features (such as `VideoDetailRemoteDataSource` or `VideoCommentRemoteDataSource`) are optional capability interfaces.
- Navigation and route build logic must validate explicit source IDs and required context capabilities before showing source-dependent screens.
- Explicit source IDs attached to media records must not silently fall back to another source.

## Data & Caching Strategy

- **Single Source of Truth (SSOT)**: `app/lib/data` acts as coordinator between remote sources (`packages/bilibili`, `packages/youtube`) and local cache (`app/lib/database`).
- **Offline-First**: For persistent lists (history, followed creators). Listen to local database streams; background fetches upsert into SQLite.
- **Network-First (Cache Fallback)**: For time-sensitive data (e.g. Trending). Fetch network first; upsert on success or fallback to cached database rows on error.

## Database Layer Conventions (Drift / SQLite)

- **Media Polymorphism**: `Media` is a base table. `Video`, `Article`, `Post` link via `mediaId` (FK with `onDelete: KeyAction.cascade`). Enforce `type` via `customConstraints` CHECK.
- **Type Constants**: Use `Media.typeVideo`, `Media.typeArticle`, `Media.typePost` string constants — never hardcode raw strings.
- **Upsert Pattern**: Use `insertReturning` with explicit `DoUpdate(target: [media.serviceId, media.type, media.originalId])`. Do not rely solely on `insertOnConflictUpdate`.
- **Foreign Keys**: Enabled via `PRAGMA foreign_keys = ON` in `AppDatabase.migration.beforeOpen`.
- **autoIncrement**: Do NOT override `primaryKey` on tables using `autoIncrement()`.
- **`customConstraints`**: Must be `const` string literals.

## Tooling & Commands

Use `flutter` commands for `app`:

| Task | Command |
|------|---------|
| Analyze | `flutter analyze`（在 `app/` 执行只覆盖本包；CI 在仓库根目录执行，覆盖 workspace 全部包，含 `app/test/`） |
| Test | `flutter test` |
| Test (single file) | `flutter test test/feature/home_bloc_test.dart` |
| Test (single case) | `flutter test test/feature/home_bloc_test.dart --plain-name "Refresh with no source emits refreshing then not refreshing"` |
| Build Runner (Drift) | `dart pub run build_runner build --build-filter="lib/database/**"` |
| Build Runner (go_router) | `dart pub run build_runner build --build-filter="lib/routing/**"` |
| Full Code Generation | `dart run build_runner build --delete-conflicting-outputs` |
| Pub Get | `flutter pub get` |

CI 对分析的处理分两档：Jules 相关 PR 用 `--fatal-infos --fatal-warnings`，其余 PR 用 `--no-fatal-infos --no-fatal-warnings`。也就是说 info 级问题在普通 PR 上不会让 CI 变红。要按 CI 的严格档自查，本地跑 `flutter analyze --fatal-infos --fatal-warnings`。

Database unit tests live in `app/test/database/` using `NativeDatabase.memory()`.
Note: Import `package:drift/drift.dart` with `hide isNotNull` to avoid collision with `package:flutter_test`.

## Dart MCP Server

仓库根的 `.mcp.json` 声明了一个 `dart` MCP server（`dart mcp-server`），连接后可用其工具操作 Dart/Flutter 工具链（包源码读取、pub、pub.dev 搜索、代码导航、分析等）。工具清单与参数以 server 当前版本为准，直接从连接后的工具列表读取，不在此罗列。

需注意其中分析/代码导航类工具依赖一个对整个 workspace 建立全量索引的分析服务器，单进程内存占用可达 1.5 GiB 量级；内存不足时该服务器会被操作系统杀死，表现为请求超时。这是工具的实现特性，不是连接或配置问题——遇到超时时改用 CLI 自查（与 CI 同命令的 `flutter analyze`，可传单个文件缩小分析范围，例如 `flutter analyze test/foo_bar_test.dart`），或确认运行环境内存充足后重试。
