# Packages Guidelines

This directory contains shared packages and modules (`packages/*`).

## Packages Overview

- `bilibili/`: Bilibili API wrapper (`bpi`), remote data source (`BilibiliSearchRemoteDataSource`), models.
- `components/`: Reusable UI widgets and Flutter components.
- `data/`: Core models (`VideoModel`, `LiveRoomModel`, `CreatorProfile`, etc.), abstract `RemoteDataSource`, `SearchQuery`, filter/pagination primitives.
- `model/`: Shared domain models (`UserData` with `ServiceSource` & `ThemeConfig`, `Result<T>`).

## Package Classification & Tooling Commands

| Package | Type | Analysis Command | Test Command | Notes |
|---------|------|------------------|--------------|-------|
| `packages/bilibili` | Dart-only | `dart analyze` | `dart test` | API client |
| `packages/components` | Flutter | `flutter analyze` | `flutter test` | UI component library (imports Flutter SDK) |
| `packages/data` | Dart-only | `dart analyze` | `dart test` | Shared models & RemoteDataSource abstraction |
| `packages/model` | Dart-only | `dart analyze` | `dart test` | Shared models (`UserData`, `Result<T>`) |

**Rule**: For Dart-only packages, use `dart` commands from the package directory. For Flutter packages (`components`), use `flutter` commands.

## Data Layer Conventions

- `packages/data` owns models, `RemoteDataSource`, and `SearchQuery`.
- `RemoteDataSource`: Each service module overrides `sourceId` to identify origin — `sourceId` lives on the source, not on model instances.
- Canonical models: Use `VideoModel` / `LiveRoomModel` (avoid deprecated `VideoInfoBase` / `LiveRoom` aliases).
