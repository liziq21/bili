# App Layer Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.
>
> Primary Constructors 规则见根 AGENTS.md。

This directory contains the main Flutter application (`app/`).

## App Structure & Architecture

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
| Build Runner (Drift) | `dart run build_runner build --build-filter="lib/database/**"` |
| Build Runner (go_router) | `dart run build_runner build --build-filter="lib/routing/**"` |
| Full Code Generation | `dart run build_runner build --delete-conflicting-outputs` |
| Pub Get | `flutter pub get` |

CI 对分析的处理分两档：Jules 相关 PR 用 `--fatal-infos --fatal-warnings`，其余 PR 用 `--no-fatal-infos --no-fatal-warnings`。也就是说 info 级问题在普通 PR 上不会让 CI 变红。要按 CI 的严格档自查，本地跑 `flutter analyze --fatal-infos --fatal-warnings`。

Generated outputs are committed, but never hand-edit them: change the source, run the narrowest generator above (or the full command when several generators are affected), then review the generated diff.

Database unit tests live in `app/test/database/` using `NativeDatabase.memory()`.
Note: Import `package:drift/drift.dart` with `hide isNotNull` to avoid collision with `package:flutter_test`.

# Storage and Path Restrictions in Termux

Due to Android's security sandbox and non-root execution environment, Termux does not adhere to the standard Filesystem Hierarchy Standard (FHS). Agents must adapt file operations to Termux-specific paths.

## 🛑 Restricted Directories & Alternatives

| Restricted Directory | Reason for Failure | Termux Alternative (`$PREFIX` / `$HOME`) |
| :--- | :--- | :--- |
| `/tmp` | No root/write access to system root | `$PREFIX/tmp` (Or use standard `$TMPDIR`) |
| `/bin`, `/sbin` | Standard Linux binary paths do not exist | `$PREFIX/bin` |
| `/usr/bin`, `/usr/lib` | Standard shared libraries/binaries missing | `$PREFIX/bin`, `$PREFIX/lib` |
| `/etc` | System configuration registry is read-only | `$PREFIX/etc` |
| `/var` | Variable data directory is restricted | `$PREFIX/var` |
| `/sdcard/Android/data` | Android scoped storage restrictions (Android 11+) | Use Termux private storage or `$HOME/storage/shared` |

## 🛠️ Implementation Guidance for Agents

### 1. Dynamic Path Resolution
Never hardcode absolute paths like `/tmp` or `/bin/sh`. Always utilize environment variables to resolve paths dynamically:
* Use **`$TMPDIR`** instead of `/tmp`
* Use **`$PREFIX`** to reference the base userland environment (equivalent to `/usr`)
* Use **`$HOME`** for user-space persistent storage

```bash
# Bad
echo "data" > /tmp/test.txt

# Good
echo "data" > "\$TMPDIR/test.txt"
```

### 2. Handling Shebangs (`#!`)
Scripts pulled from standard Linux environments containing `#!/bin/bash` or `#!/usr/bin/env` will fail with `No such file or directory`. 
* **Fix:** Run `termux-fix-shebang <script_file>` before execution to rewrite paths to `$PREFIX/bin/...`.

### 3. FHS Emulation (proot)
If a dependency rigidly requires standard Linux paths (e.g., pre-compiled binaries looking for `/lib`), wrap the execution inside a `proot` environment:
```bash
pkg install proot
termux-chroot # Simulates a standard FHS layout locally
```
