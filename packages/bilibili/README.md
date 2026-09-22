# bilibili

Bilibili 相关 API 客户端与远程数据源实现 package。

## 作用范围

- **负责**：封装 Bilibili API 客户端（`bpi`）、实现 `packages/data` 中定义的 `RemoteDataSource` 及相关能力接口（如 `BiliVideoSearchRemoteDataSource` 等）、管理 Bilibili 平台模型与本地化资源（l10n）。
- **不负责**：不直接提供 Flutter 页面 UI，不管理应用全局状态或本地 SQLite 数据库。

## 依赖关系

- **依赖项**：依赖 workspace 子包 `bpi`、`packages/data` 和 `packages/model`。
- **被依赖**：被 `app` 主工程依赖。

## 主要目录

- `lib/src/`：Bilibili API 客户端、数据源实现与特定数据模型
- `lib/l10n/`：本地化 ARB 文件及生成的本地化类 (`BilibiliLocalizations`)

## 开发命令

本 package 包含 Flutter SDK 及本地化依赖，请在 `packages/bilibili/` 目录下使用 `flutter` 命令：

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
