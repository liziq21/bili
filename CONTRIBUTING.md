# Contributing to bili

本页负责贡献流程；代码规则按 [`AGENTS.md`](AGENTS.md#normative-documents) 的索引查阅，不在此复制。

## 开发环境

- 本地精确 SDK 以 [`.fvmrc`](.fvmrc) 为准；包的最低约束与 CI 矩阵输入以根 [`pubspec.yaml`](pubspec.yaml) 为准。二者的维护规则见 [SDK 版本](AGENTS.md#sdk-版本)。
- 执行开发命令前分别确认 `dart --version` 和 `flutter --version`；不匹配时切换到仓库 pin（使用 FVM 时也要检查 `fvm dart --version` / `fvm flutter --version`）。
- 确认 SDK 后，在仓库根执行 `flutter pub get`。workspace 共用依赖解析；`pubspec.lock` 按 [`.gitignore`](.gitignore) 不提交。

## 提交前

1. 涉及生成代码时，先修改源文件，再运行对应生成器。命令见 [`app/AGENTS.md`](app/AGENTS.md#tooling--commands)；已有受版本控制的生成产物随源文件一起提交。
2. 按根 [Formatting](AGENTS.md#formatting) 规则检查本次触及的 Dart 文件，逐个列出文件名，不格式化目录。
3. 从根目录运行 workspace 分析，不能只分析 `app/lib/` 而漏掉测试与包：

   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   ```

   这是严格自查档；CI 当前对 Jules 作者或被指派 Jules 的 PR 使用严格档，其余使用非 fatal 的 info/warning 档，见 [`ci-test.yml`](.github/workflows/ci-test.yml)。已有问题须单独报告，不借机做全库修复，也不把未运行的检查记为通过。

4. 测试从包目录运行。以下命令都从**仓库根目录**开始，括号保证连续复制执行不会改变后续命令的工作目录：

   ```bash
   (cd app && flutter test)
   (cd packages/bilibili && flutter test test/)
   (cd packages/bilibili/bpi && dart test test/)
   (cd packages/youtube && flutter test test/)
   (cd packages/youtube/ypi && dart test test/)
   (cd packages/data && dart test)
   (cd packages/model && dart analyze) # 当前没有 test/，不是测试通过
   ```

   本地至少运行受影响包的检查；跨包改动需覆盖调用方。CI 测试范围由 workflow 决定，包分类见 [`packages/AGENTS.md`](packages/AGENTS.md#package-classification--tooling-commands)。新增包或测试目录时同步检查 CI 是否收录。

5. 用 `git diff --check` 和 `git diff` 排除无关格式、生成产物和临时文件。纯文档改动至少检查相对链接、引用的路径/命令和对应的文档门禁测试；不用为此重新生成代码或录制基线。

### Flutter runner 不可用时

如果本机因平台或动态库缺失无法启动 `flutter_tester`，不要删除或在测试内部跳过 Flutter/widget/golden 测试。使用仓库提供的本地入口：

```bash
dart run tool/test_local.dart
```

该入口会先探测 Flutter 测试进程。runner 可用时运行完整本地测试矩阵；runner 仅因主机环境无法启动时，运行仍可执行的纯 Dart 检查，并明确报告未运行的 Flutter 测试。降级结果只代表本地可执行部分通过，完整结果仍以 CI 为准。

需要强制要求 Flutter 测试可启动时使用：

```bash
dart run tool/test_local.dart --require-flutter
```

当前 CI 不使用降级入口，仍按 `.github/workflows/ci-test.yml` 执行完整测试。

## Pull request

1. 从最新 `main` 开分支，分支名用 `类型/描述`（如 `feat/media-history`、`docs/rule-ownership`）。保留已有未提交工作，不用 reset/force-push 清理他人的改动。
2. PR 描述使用 [模板](.github/PULL_REQUEST_TEMPLATE.md)，写明动机、变更边界、实际验证结果及未验证项。
3. 提交后检查 CI 和 review。以下是主要检查，**不是远端 required 清单的副本**：

   | 检查 | 来源 |
   |---|---|
   | `CodeRabbit` | 外部评审服务，配置见 [`.coderabbit.yaml`](.coderabbit.yaml)；不由 `ci-*.yml` 产生 |
   | `Check Formatting` | `ci-format.yml`，使用 `.fvmrc` 的单一 SDK |
   | `Run Flutter Test (…)` | `ci-test.yml`，后缀来自 pubspec 矩阵 |
   | `Build Flutter App (android) (…)` | `ci-build.yml`，后缀来自 pubspec 矩阵 |
   | Skills Code Scanning 的 `scan-skills` job | [`code-scanning.yml`](.github/workflows/code-scanning.yml) |

   哪些检查必需、适用哪些分支、谁能 bypass，必须查看 GitHub 当前 ruleset 和 PR Checks；仅看 workflow 或本文不能证明权限。升级 SDK 的同步要求见根 [Release](AGENTS.md#release) 与 [SDK 版本](AGENTS.md#sdk-版本)。

4. 逐条处理评审意见。CodeRabbit 暂停或旧 CHANGES_REQUESTED 未解除时按 [runbook](docs/runbook.md#pr-卡在-stale-的-changes_requested) 处理。被 `ignore_usernames` 排除的作者不保证收到自动 review；若缺少 required 状态，交由维护者核对配置，不能伪造状态。

## 截图基线

基线政策以根 [Screenshot Tests](AGENTS.md#screenshot-tests) 为准。不要本地重录或手工提交 PNG；CI 生成的基线 PR 经审查后可以合入版本控制。

新增/变更 golden 时，基线 PR 合入前 CI 可能暂时变红。按 [重录流程](docs/runbook.md#重录截图基线) 对拥有改动的分支运行 `rerecord-goldens.yml`，审查来源与图像差异，不能用放宽容差或删测试消除失败。
