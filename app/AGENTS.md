# App Layer Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.
>
> Primary Constructors 规则见根 AGENTS.md。

This directory contains the main Flutter application (`app/`).

## 应用结构与架构

- `lib/`: Application source code
  - `feature/`: Screen-level UI features (`home/`, `search/`, `live/`, `video/`, `space/`, `setting/`, `theme/`, `not_found/`).
  - `data/`: Repository implementations and local data models bridging database to domain layer.
    - `repository/`: Repository implementations (`AppVideoSearchRepository`, `AppCreatorProfileSearchRepository`, `AppLiveRoomSearchRepository`, etc.).
    - `repository/recent_search_query/`: History repository backed by Drift.
    - `repository/user_data/`: Preferences repository backed by `PreferencesDataSource`.
  - `database/`: Drift (SQLite) database, table definitions, DAOs.
  - `datastore/`: Shared preferences / persistent key-value storage (`PreferencesDataSource`).
  - `domain/`: Use cases and business logic (`GetRecentSearchQueriesUseCase`, `GetSearchContentsUseCase`).
  - `l10n/`: ARB files and generated localizations (`AppLocalizations`).
  - `providers/`: Dependency injection wiring via `flutter_bloc` `RepositoryProvider`.
  - `routing/`: `go_router` route configuration.
  - `design/`, `ui/`, `utils/`: Design-system tokens, shared UI utilities, and general helpers.
- Platform code: `android/`, `ios/`, `linux/`, `web/`.
- `test/`: Unit and widget tests mirroring `lib/`.

## 核心原则与设计模式

### 可扩展数据源与本地个性化
- The application relies on third-party extensible data sources without platform login, online commenting, or platform-specific coin features.
- Personalization features such as subscriptions, favorites, and watch history are strictly managed in local storage (Drift SQLite / SharedPreferences).

### 全局样式访问（`$styles`）
- Defined in `lib/main.dart` as `AppStyle get $styles => AppScaffold.style`.
- Access the live singleton directly (`$styles.colors`, `$styles.corners`, `$styles.insets`, `$styles.text`, etc.) — do not create local copies.
- **Strict Rule**: When writing or updating UI components (including Stitch designs), strictly map visual elements to `$styles` design tokens. Never hardcode colors or stitch-specific style constants.
- See [`docs/design-system.md`](docs/design-system.md) for the color-literal policy, token roles, and contrast requirements. Within `app/lib/`, [`lib/design/brand_palette.dart`](lib/design/brand_palette.dart) is the **only** file where color literals are allowed. Decision rationale and measurements are deliberately kept out of the repository — read them from the git history of the commits that established each rule.

### 依赖注入与源提供者（`ServiceSourceProviders`）
- The complete source-injection contract is [`docs/source-injection.md`](docs/source-injection.md).
- `app/lib/data/` depends only on neutral capability interfaces from `packages/data`; it must not import concrete service packages such as `bilibili` or `youtube`.
- The composition root (`providers/media_sources_provider.dart`) registers source definitions and factories. The root tree injects `MediaSourceCatalog`, never live source instances.
- An empty source catalog is valid. Resolution returns `null` when no source exists; an empty string is not a no-source sentinel.
- `ServiceSourceProviders` creates and owns one route-scoped source instance, injects repositories from that instance's capabilities, and closes it exactly once on disposal.
- Repository injection is capability-driven, not a source-ID switch. A missing optional capability omits its provider and the UI must show an explicit unavailable state.
- Screen-level BlocProviders are assembled at the route/route-data composition point and receive dependencies from the source scope.

### 可选能力接口与路由验证
- Data source features (such as `VideoDetailRemoteDataSource` or `VideoCommentRemoteDataSource`) are optional capability interfaces.
- Navigation and route build logic must validate explicit source IDs and required context capabilities before showing source-dependent screens.
- Explicit source IDs attached to media records must not silently fall back to another source.

## 数据与缓存策略

- **Single Source of Truth (SSOT)**: `app/lib/data` acts as coordinator between remote sources (`packages/bilibili`, `packages/youtube`) and local cache (`app/lib/database`).
- **Offline-First**: For persistent lists (history, followed creators). Listen to local database streams; background fetches upsert into SQLite.
- **Network-First (Cache Fallback)**: For time-sensitive data (e.g. Trending). Fetch network first; upsert on success or fallback to cached database rows on error.

## 数据库层约定（Drift / SQLite）

- **Media Polymorphism**: `Media` is a base table. `Video`, `Article`, `Post` link via `mediaId` (FK with `onDelete: KeyAction.cascade`). Enforce `type` via `customConstraints` CHECK.
- **Type Constants**: Use `Media.typeVideo`, `Media.typeArticle`, `Media.typePost` string constants — never hardcode raw strings.
- **Upsert Pattern**: Use `insertReturning` with explicit `DoUpdate(target: [media.serviceId, media.type, media.originalId])`. Do not rely solely on `insertOnConflictUpdate`.
- **Foreign Keys**: Enabled via `PRAGMA foreign_keys = ON` in `AppDatabase.migration.beforeOpen`.
- **autoIncrement**: Do NOT override `primaryKey` on tables using `autoIncrement()`.
- **`customConstraints`**: Must be `const` string literals.

## 工具与命令

Use `flutter` commands for `app`:

| Task | Command |
|------|---------|
| Analyze | `flutter analyze`（在 `app/` 执行只覆盖本包；CI 在仓库根目录执行，覆盖 workspace 全部包，含 `app/test/`） |
| Test | `flutter test` |
| Test (single file) | `flutter test test/feature/home_bloc_test.dart` |
| Test (single case) | `flutter test test/feature/home_bloc_test.dart --plain-name "Refresh with no source emits refreshing then not refreshing"` |
| Build Runner (Drift) | `dart run build_runner build --build-filter="lib/database/**"` |
| Build Runner (go_router) | `dart run build_runner build --build-filter="lib/routing/**"` |
| Full Code Generation | `dart run build_runner build --delete-conflicting-outputs` |
| Pub Get | `flutter pub get` |

CI 对分析的处理分两档：Jules 相关 PR 用 `--fatal-infos --fatal-warnings`，其余 PR 用 `--no-fatal-infos --no-fatal-warnings`。也就是说 info 级问题在普通 PR 上不会让 CI 变红。要按 CI 的严格档自查，本地跑 `flutter analyze --fatal-infos --fatal-warnings`。

Generated outputs are committed, but never hand-edit them: change the source, run the narrowest generator above (or the full command when several generators are affected), then review the generated diff.

Database unit tests live in `app/test/database/` using `NativeDatabase.memory()`.
Note: Import `package:drift/drift.dart` with `hide isNotNull` to avoid collision with `package:flutter_test`.
