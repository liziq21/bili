# model

跨 package 共享的数据模型与值对象 package。

## 作用范围

- **负责**：定义跨 package 共享的基础数据结构、配置对象（`UserData`, `ServiceSource`, `ThemeConfig`）以及通用的结果类型（`Result<T>`）。
- **不负责**：不处理具体的业务逻辑、UI 组件或 API 通信。

## 依赖关系

- **依赖项**：依赖 `json_annotation`、`freezed_annotation` 和 `equatable`。
- **被依赖**：被 `app`、`packages/data`、`packages/bilibili` 和 `packages/youtube` 依赖。

## 主要目录

- `lib/src/`：领域配置模型、数据源类型定义与通用结果类型

## 开发命令

本 package 为 **Dart-only package**，请在 `packages/model/` 目录下使用 `dart` 命令：

```bash
# 依赖安装
dart pub get

# 静态分析
dart analyze

# 单元测试
dart test
```

## 相关规范

详细的数据模型不可变性（`@immutable`）与相等性（`EquatableMixin`）约定请参阅：
- [packages/AGENTS.md](../AGENTS.md)
