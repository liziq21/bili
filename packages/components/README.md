# components

可复用 Flutter UI 组件 package。

## 作用范围

- **负责**：提供跨页面、跨数据源可复用的基础 Flutter UI 组件和样式扩展（如 `ToggleSwitchComponent`）。
- **不负责**：不包含特定的应用页面逻辑、路由导航或 API 请求。

## 依赖关系

- **依赖项**：依赖 Flutter SDK。
- **被依赖**：被 `app` 主工程依赖。

## 主要目录

- `lib/`：通用 UI 组件实现
- `lib/theme/`：组件层主题与样式定义
- `test/`：UI 组件测试

## 开发命令

本 package 为 **Flutter package**，请在 `packages/components/` 目录下使用 `flutter` 命令：

```bash
# 依赖安装
flutter pub get

# 静态分析
flutter analyze

# 单元测试
flutter test
```

## 相关规范

详细的组件开发规则与 UI 约束请参阅：
- [packages/AGENTS.md](../AGENTS.md)
