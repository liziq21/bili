# Contributing to bili

本仓库的具体规范不在这里。改动前请读 [`AGENTS.md`](AGENTS.md) 的 Normative Documents 段——它列出按改动类型该读哪份文件，各文件是唯一真相源。

本页只说明流程。

## 开发环境

- **Dart**: `^3.13.4`
- **Flutter**: `>=3.47.5`
- Flutter workspace：依赖安装在仓库根目录执行 `flutter pub get`

## 提交前

```bash
flutter analyze              # 分析器必须无新增告警
```

测试必须逐包在自己的目录下执行，命令与 `.github/workflows/ci.yml` 的 `Run Flutter Test` job 一致。仓库根跑 `flutter test` 不等价于 CI，部分 package 会失败：

```bash
cd app && flutter test                    # 主应用与golden
cd packages/bilibili && flutter test test/
cd packages/bilibili/bpi && flutter test test/
cd packages/youtube && flutter test test/
cd packages/youtube/ypi && flutter test test/
```

`pubspec.lock` 不提交。

## Pull request

1. 从 `main` 开分支，分支名用 `类型/描述`（如 `feat/p4-token-scale`、`ci/drop-dependabot`）。
2. 改动前读上表对应的规范文件。UI 颜色或 token 的改动必须先读 `app/docs/design-system.md`。
3. PR 描述写清动机与验证方式，不要只写改了什么。
4. 提交后等 CI。合并需要三个检查通过：

   | 检查 | 来源 |
   |---|---|
   | `CodeRabbit` | CodeRabbit 自动评审，配置见 [`.coderabbit.yaml`](.coderabbit.yaml) |
   | `Run Flutter Test (3.47.5, 3.13.4)` | `ci.yml` |
   | `Build Flutter App (android) (3.47.5, 3.13.4)` | `ci.yml` |

   check 名带括号里的版本号，来自根 `pubspec.yaml` 的 `environment` 段经 `pubspec-matrix-action` 生成的矩阵。**升级 Flutter 或 Dart 版本时需要同步更新 ruleset**，否则 PR 会卡在缺少必需检查。

5. CodeRabbit 提出 issues 后逐条处理。推新 commit 会自动触发增量评审；CodeRabbit 因累计评审数过多自动暂停时，发 `@coderabbitai resume`。

## 截图基线

基线只由 CI 产出，不在本地重录、不提交 PNG 进仓库。基线过期时手动触发 `rerecord-goldens.yml`，`target_ref` 填要重录的分支（`main` 或功能分支）。