# Bili App Project Analysis

This is a Flutter application with a modular structure, separating the main application logic from reusable packages.

## Project Structure

- `app/`: The main Flutter application.
    - `lib/`: Application source code, organized by:
        - `feature/`: Screen-level UI features.
            - `home/`: Home screen and view model.
            - `search/`: Search functionality (bloc, widgets, result screens).
            - `live/`: Live streaming screen.
            - `video/`: Video detail and playback screen.
            - `space/`: User space/profile screen.
            - `setting/`: Settings screen with view model.
            - `theme/bloc/`: Theme management via Bloc (light/dark/auto).
            - `not_found/`: 404 fallback screen.
        - `data/`: Repository implementations and local data models (bridging the database to domain layer).
            - `repository/search_contents_repository.dart`: `SearchContentsRepository<T>` generic interface with typedefs (`VideoSearchRepository`, `CreatorProfileSearchRepository`, `LiveRoomSearchRepository`, `AggregateSearchRepository`).
            - `repository/search_suggest_repository.dart`: `SearchSuggestRepository` interface for autocomplete/suggestion support.
            - `repository/search/`: Concrete app-layer search repositories — each implements only the interfaces it supports (`AppVideoSearchRepository`, `AppUserSearchRepository`, `AppLiveRoomSearchRepository`, `AppAggregateSearchRepository`). A source lacking a capability simply does not register that provider.
                - **Note**: `AppUserSearchRepository` implements both `CreatorProfileSearchRepository` and `SearchSuggestRepository` (suggestions are sourced from the same remote data source).
                - **Note**: `AppAggregateSearchRepository` exists as an interface but its provider is currently commented out in `repo_providers.dart`.
            - `repository/recent_search_query/`: Local history repository backed by Drift (`DefaultRecentSearchQueryRepository`).
        - `repository/user_data/`: User preferences repository (`UserDataRepository` + `DefaultUserDataRepository`) backed by `PreferencesDataSource`.
        - `database/`: Drift (SQLite) database, including table definitions and DAOs.
        - `datastore/`: Shared preferences / persistent key-value storage (`PreferencesDataSource`).
        - `domain/`: Use cases (business logic) — e.g., `GetRecentSearchQueriesUseCase`, `GetSearchContentsUseCase`.
        - `l10n/`: Internationalization — generates `AppLocalizations` from `.arb` files (Chinese supported via `app_localizations_zh.dart`).
        - `app.dart`, `app_bloc.dart`, `app_scaffold.dart`, `main.dart`: Core app entry point and root widget configuration.
        - `providers/`: Dependency injection wiring via `flutter_bloc` `RepositoryProvider`.
        - `routing/`: `go_router` route configuration.
        - `styles/`, `ui/`, `utils/`: Shared UI utilities.
    - Platform-specific code (`android/`, `ios/`, `linux/`, `web/`).
    - `test/`: Unit and widget tests, mirroring the `lib/` structure.
- `packages/`: Shared packages/modules.
    - `bilibili/`: Handles Bilibili-specific logic, including API wrappers (`bpi` sub-package), models, and remote data source (`BilibiliSearchRemoteDataSource`).
    - `components/`: Contains reusable UI components.
    - `data/`: Defines models, data source abstractions, and search primitives shared across source modules.
        - `lib/src/model/`: Canonical model classes (`VideoModel`, `LiveRoomModel`, `CreatorProfile`, etc.).
            - Legacy type aliases `VideoInfoBase = VideoModel` and `LiveRoom = LiveRoomModel` exist only for backward compatibility — prefer `VideoModel` / `LiveRoomModel`.
            - Also includes `AggregateSearchPage`, `FilterGroup` (with `SingleFilterGroup`, `MultiFilterGroup`, `DateRangeFilterGroup`), `SortOption`, and `PagedResult<T>`.
        - `lib/src/remote_data_source.dart`: Abstract `RemoteDataSource` base class. Each service module (e.g. `packages/bilibili`) provides its own implementation and overrides `sourceId` to identify the data origin — `sourceId` lives on the source, **not** on individual model instances.
        - `lib/src/search_query.dart`: Immutable `SearchQuery` value object carrying query string, pagination key, sort option, and filters.
    - `model/`: Contains shared data models.
        - `UserData`: Freezed class with `ServiceSource` enum and `ThemeConfig`, persisted via JSON serialization.
        - `Result<T>`: Utility type for handling success/failure outcomes.

## Development Guidelines

- **Features**: Implement new features in `app/lib/feature/`.
- **Packages**: Add shared logic or models to the appropriate package under `packages/` to maintain a clean separation of concerns.
- **Data Layer**: `packages/data` owns models, `RemoteDataSource`, and `SearchQuery` — things any source module needs. The app layer (`app/lib/data/repository`) owns repository interfaces (`SearchContentsRepository<T>`, `SearchSuggestRepository`) and their concrete implementations (`AppVideoSearchRepository`, `AppUserSearchRepository`, etc.). Each app repository implements only the interfaces it supports; providers are injected conditionally so a source that lacks a capability simply doesn't register that repository.
- **Caching & Data Strategy**:
    - **Single Source of Truth (SSOT)**: The `app/lib/data` layer acts as the coordinator. The remote source (`packages/bilibili`) provides data, the local source (`app/lib/database`) caches it, and the Repository exposes it to the UI.
    - **Offline-First**: Use for persistent lists (history, followed creators). UI listens to local database streams; network fetch occurs in the background and upserts into the database, triggering a UI refresh automatically.
    - **Network-First (with Cache Fallback)**: Use for highly time-sensitive data (e.g., Trending pages). The Repository explicitly fetches from the network first (showing loading state). Upon success, it upserts to the database and returns data. On failure, it catches the exception and falls back to cached data from the database.
- **Dart Syntax**: 
    - **Primary Constructors**: Prefer using Dart's **Primary Constructors** syntax to reduce boilerplate. Combine field declarations, parameter declarations, and initialization directly in the class header (e.g., `class User(final String name, final int age);`).
    - Use the empty body semicolon shorthand (`class C(int x);`) when the body is empty.
    - Use abbreviated concise constructor syntax (e.g., `new() {}` or `const new();`) for in-body constructors when applicable.
- **Global Style Access (`$styles`)**: Defined in `lib/main.dart` as `AppStyle get $styles => AppScaffold.style`. Access the live singleton directly — do not create local copies. Full member reference: `lib/styles/styles.dart`.

## Database Layer (Drift/SQLite)

The app uses [Drift](https://drift.simonbinder.eu/) for local SQLite persistence. Database code is in `app/lib/database/`.

### Key Conventions

- **Media type polymorphism**: `Media` is a shared base table. `Video`, `Article`, and `Post` are specialization tables linked via `mediaId` (FK with `onDelete: KeyAction.cascade`). The `type` column is enforced by a `customConstraints` CHECK.
- **Type constants**: Use `Media.typeVideo`, `Media.typeArticle`, `Media.typePost` string constants — never hardcode the raw string values.
- **Upsert pattern**: When inserting into `Media` with a potential conflict on the unique key `(serviceId, type, originalId)`, always use `insertReturning` with an explicit `DoUpdate(target: [media.serviceId, media.type, media.originalId])`. Do **not** use `insertOnConflictUpdate` alone (it targets only the primary key and cannot reliably return the updated row's `internalId`).
- **Foreign keys**: SQLite foreign key enforcement is enabled at runtime via `PRAGMA foreign_keys = ON` in `AppDatabase.migration.beforeOpen`.
- **autoIncrement tables**: Do **not** override `primaryKey` on tables that use `autoIncrement()` (Drift will warn and ignore it).
- **`customConstraints`**: Must be `const` string literals — string interpolation is not supported by the Drift analyzer.

### Tooling Commands

**Use `flutter` over `dart` whenever possible.** Flutter wraps Dart with additional type checking (e.g., widget tree validity, framework API correctness). Only fall back to `dart` for pure-Dart packages that have no Flutter SDK dependency.

| Task | Preferred Command | Fallback | Scope |
|------|-------------------|----------|-------|
| Analyze app lib/ | `flutter analyze lib/` | `dart analyze` | app only |
| Run tests | `flutter test` | — | app |
| Build runner (Drift / go_router) | `dart pub run build_runner` | — | pure-Dart code generation |
| Pub get | `flutter pub get` | — | app + workspace |
| Analyze pure-Dart package | `dart analyze` | — | packages/* only |
| Test pure-Dart package | `dart test` | — | packages/* only |

**Package types:**

| Package | Type | Notes |
|---------|------|-------|
| `app` | Flutter | Main application; import Flutter SDK |
| `packages/components` | Flutter | UI widget library; imports `flutter: sdk: flutter` |
| `packages/bilibili` | Dart-only | Bilibili API client; no Flutter dependency |
| `packages/data` | Dart-only | Models, `RemoteDataSource`, `SearchQuery` |
| `packages/model` | Dart-only | Shared data models (`UserData`, `Result<T>`) |

For Dart-only packages, use `dart` commands directly. For Flutter packages (including the app and `components`), prefer `flutter` commands.

### Code Generation

After modifying any `table/*.dart` or `dao/*.dart` file, regenerate the `.g.dart` files:

```bash
cd app
# Database (Drift)
dart pub run build_runner build --build-filter="lib/database/**"
# Routing (go_router)
dart pub run build_runner build --build-filter="lib/routing/**"
```

Or for a full rebuild:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Testing

Database unit tests live in `app/test/database/`. They use an in-memory SQLite database (`NativeDatabase.memory()`):

```bash
flutter test test/database/
```

Pure-Dart package tests use `dart test` from the package root:

```bash
cd packages/model && dart test
```

> **Note**: Import `package:drift/drift.dart` with `hide isNotNull` to avoid a name collision with `package:flutter_test`.


