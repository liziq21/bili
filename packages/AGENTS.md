# Packages Guidelines

> **Important**: If you are not familiar with the contents of the root [`AGENTS.md`](../AGENTS.md) (such as Primary Constructors guidelines, UI framework constraints, Dart version rules, etc.), you **must** read it first before proceeding.

This directory contains shared packages and modules (`packages/*`).

## Packages Overview

- `bilibili/`: Bilibili API wrapper (`bpi`), remote data sources (`BiliVideoSearchRemoteDataSource`, etc.), models, and `BilibiliLocalizations` (l10n).
- `youtube/`: YouTube API wrapper (`ypi`), remote data sources (`YouTubeVideoSearchRemoteDataSource`, etc.), Chopper REST client, and custom pure Dart Protobuf encoders (`YoutubeProtobufEncoder` / `YoutubeParamsBuilder`) for InnerTube endpoints.
- `components/`: Reusable UI widgets and Flutter components.
- `data/`: Core canonical models (`VideoModel`, `LiveRoomModel`, `CreatorProfile`, etc.), abstract `RemoteDataSource`, `SearchQuery`, filter/pagination primitives, and optional capability interfaces.
- `model/`: Shared domain models (`UserData` with `ServiceSource` & `ThemeConfig`, `Result<T>`).

## Package Classification & Tooling Commands

| Package | Type | Analysis Command | Test Command | Notes |
|---------|------|------------------|--------------|-------|
| `packages/bilibili` | Flutter | `flutter analyze` | `flutter test` | API client & l10n (imports Flutter SDK) |
| `packages/youtube` | Dart-only | `dart analyze` | `dart test` | API client (`ypi`), Chopper & Protobuf encoder |
| `packages/components` | Flutter | `flutter analyze` | `flutter test` | UI component library (imports Flutter SDK) |
| `packages/data` | Dart-only | `dart analyze` | `dart test` | Shared models & RemoteDataSource abstraction |
| `packages/model` | Dart-only | `dart analyze` | `dart test` | Shared models (`UserData`, `Result<T>`) |

**Rule**: For Dart-only packages, use `dart` commands from the package directory. For Flutter packages (`bilibili`, `components`), use `flutter` commands.

## Data Layer & Remote Data Source Conventions

- `packages/data` owns domain models, `RemoteDataSource`, and `SearchQuery`.
- **`sourceId` Placement**: Each service module overrides `sourceId` on its `RemoteDataSource` implementation to identify origin — `sourceId` lives on the source, not on model instances.
- **Canonical Models**: Use `VideoModel` / `LiveRoomModel` (avoid deprecated `VideoInfoBase` / `LiveRoom` aliases).
- **Optional Capability Interfaces**: Design specific features as mixins or optional interfaces (e.g. `VideoDetailRemoteDataSource`, `VideoCommentRemoteDataSource`). Implementations pick and choose supported capabilities; consumers check interface availability before invocation.
