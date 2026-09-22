# bili

这是一个处于早期开发阶段的 Flutter workspace。当前主要用于代码结构、数据层和基础界面的持续开发，不代表已经具备完整可用的应用功能。

## 当前状态

- 项目处于早期阶段
- 功能尚未完整实现
- API、UI 和数据层仍可能发生较大变化
- 文档只描述当前代码结构和开发方式
- 不对应用可用性、功能完整性或发布状态做承诺

## 开发环境

- **Dart**: `^3.13.4`
- **Flutter**: `>=3.47.5`
- **项目类型**: Flutter/Dart workspace
- **详细规范**: 请参考 [AGENTS.md](AGENTS.md)

## 仓库结构

- `app/`：主 Flutter 应用
- `packages/bilibili/`：Bilibili 相关 API 和数据源
- `packages/youtube/`：YouTube 相关 API 和数据源
- `packages/components/`：可复用 Flutter UI 组件
- `packages/data/`：共享数据层接口和抽象
- `packages/model/`：共享模型和值对象
- `.github/workflows/`：CI 配置

## 初始化项目

在仓库根目录下执行依赖安装：

```bash
flutter pub get
```

如需为子 package 显式更新或安装依赖，可分别进入各目录执行：

```bash
# app 主工程
cd app && flutter pub get

# Flutter packages
cd packages/bilibili && flutter pub get
cd packages/youtube && flutter pub get
cd packages/components && flutter pub get

# Dart-only packages
cd packages/data && dart pub get
cd packages/model && dart pub get
```

## 运行应用

从 `app/` 目录启动应用：

```bash
cd app
flutter run
```

## 代码生成

项目使用 `build_runner` 为 Drift 数据库和 `go_router` 路由生成代码。

### 全量生成

在 `app/` 目录下运行全量生成命令：

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

或在根目录下执行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 定向生成

如果仅修改了数据库或路由部分，可以在 `app/` 目录下进行定向生成以节省时间：

```bash
# 定向生成 Drift 数据库代码
cd app
dart pub run build_runner build --build-filter="lib/database/**"

# 定向生成 go_router 路由代码
cd app
dart pub run build_runner build --build-filter="lib/routing/**"
```

详细的生成器规范与机制请参考 [app/AGENTS.md](app/AGENTS.md)。生成的文件（如 `*.g.dart`）需要提交至版本控制。

## 检查与测试

### app 模块

```bash
cd app
flutter analyze lib/
flutter test
```

### Flutter packages

对于包含 Flutter SDK 依赖或本地化（l10n）资源的 package，使用 `flutter` 命令：

```bash
# packages/bilibili
cd packages/bilibili
flutter analyze
flutter test

# packages/youtube
cd packages/youtube
flutter analyze
flutter test

# packages/components
cd packages/components
flutter analyze
flutter test
```

### Dart-only packages

对于纯 Dart 逻辑与模型 package，使用 `dart` 命令：

```bash
# packages/data
cd packages/data
dart analyze
dart test

# packages/model
cd packages/model
dart analyze
dart test
```

### 完整检查建议

提交变更前，建议在各自目录下依次运行对应的 analyze 与 test 命令，确保全局类型检查和单元测试全部通过。

## 开发约定

仓库已在 [AGENTS.md](AGENTS.md)、[app/AGENTS.md](app/AGENTS.md) 及 [packages/AGENTS.md](packages/AGENTS.md) 中定义了 workspace 结构和代码组织规则，主要包括：

- **应用代码结构**：应用级别的 feature 页面与组件放在 `app/lib/feature/`。
- **模块化下沉**：共享业务逻辑、数据接口与数据源下沉到对应的 package 中。
- **命令区分**：Flutter package 使用 `flutter analyze` / `flutter test`，Dart-only package 使用 `dart analyze` / `dart test`。
- **UI 依赖约束**：UI 组件统一使用项目指定的 `material_ui`，严禁直接依赖 `flutter/material.dart` 或 `flutter/cupertino.dart`。
- **语法与不可变规范**：遵循 Dart 3.13 语法（如 Primary Constructors），模型类需使用 `@immutable` 标注并保持不可变性。

## 提交变更前检查

1. 运行相关 package 的 analyze 静态分析
2. 运行相关单元与 Widget 测试
3. 如涉及生成代码（Drift/go_router/l10n），运行对应的代码生成命令
4. 确认生成文件无误且格式化结果正常 (`dart format .`)
5. 检查 `git diff` 确保没有无关修改

## Known Limitations / 已知限制

- 当前代码库处于持续重构与基础搭建阶段。
- 各数据源和页面接口的实现细节仍可能随设计调整而变化。
