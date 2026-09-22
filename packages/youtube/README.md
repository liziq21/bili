# youtube

YouTube 相关 API 客户端与远程数据源实现 package。

## 作用范围

- **负责**：封装 YouTube API 客户端（`ypi`）、实现 Chopper REST 客户端与 Protobuf 编码器（`YoutubeProtobufEncoder` / `YoutubeParamsBuilder`）、实现 `packages/data` 中定义的 `RemoteDataSource` 接口，以及管理 YouTube 平台本地化资源（l10n）。
- **不负责**：不直接提供 Flutter 页面 UI，不处理本地缓存或 SQLite 持久化。

## 依赖关系

- **依赖项**：依赖 `packages/data` 和 `packages/model`。
- **被依赖**：被 `app` 主工程依赖。

## 主要目录

- `lib/src/`：YouTube 远程数据源实现、Chopper 客户端与 Protobuf 编码模块
- `lib/l10n/`：本地化 ARB 文件及生成的本地化类 (`YoutubeLocalizations`)
- `ypi/`：YouTube API 子包与底层客户端

## 开发命令

本 package 包含 Flutter SDK 及本地化依赖，请在 `packages/youtube/` 目录下使用 `flutter` 命令：

```bash
# 依赖安装
flutter pub get

# 静态分析
flutter analyze

# 单元测试
flutter test
```

## 相关规范

详细的开发规范与代码约定请参阅：
- [packages/AGENTS.md](../AGENTS.md)
