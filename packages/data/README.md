# data

共享数据层接口和抽象 package。

## 作用范围

- **负责**：定义核心规范模型（`VideoModel`, `LiveRoomModel`, `CreatorProfile` 等）、`RemoteDataSource` 抽象接口、`SearchQuery` 过滤/分页原语以及数据源可选能力接口（如 `VideoDetailRemoteDataSource`, `VideoCommentRemoteDataSource` 等）。
- **不负责**：不处理具体的 API HTTP 请求实现，不包含特定数据源（如 Bilibili、YouTube）的平台私有解析逻辑。

## 依赖关系

- **依赖项**：依赖 `packages/model`（使用共享 `UserData` 与 `Result<T>`）及纯 Dart 基础包。
- **被依赖**：被 `app` 主工程以及 `packages/bilibili`、`packages/youtube` 等具体数据源包依赖。

## 主要目录

- `lib/src/models/`：共享规范数据模型与领域原语
- `lib/src/remote_data_source.dart`：`RemoteDataSource` 核心抽象与能力接口

## 开发命令

本 package 为 **Dart-only package**，请在 `packages/data/` 目录下使用 `dart` 命令：

```bash
# 依赖安装
dart pub get

# 静态分析
dart analyze

# 单元测试
dart test
```

## 相关规范

详细的数据层设计模式与 `sourceId` 约定请参阅：
- [packages/AGENTS.md](../AGENTS.md)
