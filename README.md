# bili

这是一个处于早期开发阶段的 Flutter workspace，主要用于数据层和基础界面的持续开发。功能尚未完整实现，API、UI 和包边界仍可能变化；不对应用可用性或发布状态做承诺。

## 开发入口

- [AGENTS.md](AGENTS.md)：规范索引、规则归属、SDK、生成文件与测试政策。
- [CONTRIBUTING.md](CONTRIBUTING.md)：环境确认、可连续执行的逐包检查命令、PR 流程。
- [app/AGENTS.md](app/AGENTS.md)：应用架构、DI、数据库与生成命令。
- [packages/AGENTS.md](packages/AGENTS.md)：包分类、依赖边界及 API 子包通用规则。
- [设计系统](app/docs/design-system.md)：颜色、主题、token 和对比度政策。

本文是项目介绍，不另立开发规则。SDK 的精确版本见 [`.fvmrc`](.fvmrc)，最低约束与 CI 矩阵输入见根 [`pubspec.yaml`](pubspec.yaml)。

## 仓库结构

- `app/`：主 Flutter 应用。
- `packages/bilibili/`、`packages/youtube/`：平台数据源适配与本地化；其中 `bpi/`、`ypi/` 是纯 Dart API 子包。
- `packages/data/`：共享数据模型、接口和能力抽象。
- `packages/model/`：共享模型和值对象。
- `packages/components/`：本地可能仍有预留目录，但没有 `pubspec.yaml`，不是 workspace package。
- `.github/workflows/`：测试、格式检查、构建、基线录制及发布工作流。

## 初始化与运行

按 [SDK 规则](AGENTS.md#sdk-版本) 确认 Dart 与 Flutter 后，从仓库根执行：

```bash
flutter pub get
(cd app && flutter run)
```

Android 签名要求及仅用于验证的构建方式见 [Release](AGENTS.md#release)，不能把 CI 的验证 APK 当成可发布产物。

## 代码生成与检查

- 修改 Drift、路由或其他生成器的输入后，按 [应用生成命令](app/AGENTS.md#tooling--commands) 重新生成；修改 ARB 后，在对应 Flutter 包执行 `flutter gen-l10n`。
- [贡献指南](CONTRIBUTING.md#提交前) 集中维护格式、分析与逐包测试流程，不要用仓库根的一次 `flutter test` 代替逐包测试。
- 基线只由 [rerecord-goldens.yml](.github/workflows/rerecord-goldens.yml) 录制；处置流程见 [runbook](docs/runbook.md)。
- App 版本以 `app/pubspec.yaml` 为准，发布标记和签名政策见 [Release](AGENTS.md#release)。

## 架构背景

以下文档提供理解路径，不代替上面的规范文件：

- [架构学习路径](docs/architecture-learning-journey.md)
- [模块化学习路径](docs/modularization-learning-journey.md)
- [事故复盘](docs/postmortems/README.md)
