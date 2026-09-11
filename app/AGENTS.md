# App Layer Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.

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

## Data & Caching Strategy

- **Single Source of Truth (SSOT)**: `app/lib/data` acts as coordinator between remote sources (`packages/bilibili`) and local cache (`app/lib/database`).
- **Offline-First**: For persistent lists (history, followed creators). Listen to local database streams; background fetches upsert into SQLite.
- **Network-First (Cache Fallback)**: For time-sensitive data (e.g. Trending). Fetch network first; upsert on success or fallback to cached database rows on error.

## Global Style Access (`$styles`)

- Defined in `lib/main.dart` as `AppStyle get $styles => AppScaffold.style`.
- Access the live singleton directly — do not create local copies. Reference: `lib/styles/styles.dart`.

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
| Analyze | `flutter analyze lib/` |
| Test | `flutter test` |
| Build Runner (Drift) | `dart pub run build_runner build --build-filter="lib/database/**"` |
| Build Runner (go_router) | `dart pub run build_runner build --build-filter="lib/routing/**"` |
| Full Code Generation | `dart run build_runner build --delete-conflicting-outputs` |
| Pub Get | `flutter pub get` |

Database unit tests live in `app/test/database/` using `NativeDatabase.memory()`.
Note: Import `package:drift/drift.dart` with `hide isNotNull` to avoid collision with `package:flutter_test`.
