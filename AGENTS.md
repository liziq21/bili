# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## 项目结构

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `youtube`, `data`, `model`). `packages/components/` is currently reserved and has no `pubspec.yaml`, so it is not a workspace package.

## 规范文档

Before writing or modifying code in this repository, read the specification files that govern your change. 这份清单是地图；每个文件是事实源——规则不在此重复。

### 规则归属与优先级

- Executable configuration is authoritative for what the tooling actually does: `.fvmrc`, the root `pubspec.yaml`, `analysis_options.yaml`, package `pubspec.yaml` files, and `.github/workflows/`.
- `AGENTS.md` rules apply to the directory they are in. When rules overlap, the most specific applicable `AGENTS.md` wins; a package rule may narrow a root rule but must not silently contradict it.
- `app/docs/design-system.md` owns color, theme, token, and contrast policy. `packages/AGENTS.md` owns shared package and API-package boundaries; `bpi/AGENTS.md` and `ypi/AGENTS.md` add platform-specific details only.
- `README.md`, learning journeys, journals, and postmortems provide context or history. They must link to the owning rule instead of creating a second source of truth. `docs/runbook.md` is normative only for incident recovery steps.
- If a document and executable configuration disagree, do not guess: fix the document or configuration in the same change, and state which behavior is intended.

### 文档维护义务

- 修改 workflow、SDK 版本、命令或版本号时，同一次改动必须检查并更新所有 AGENTS.md 中的引用。
- 文档与可执行配置不一致时，以可执行配置为准，文档须在同一次改动中修复。
- 改 CI workflow 或 golden 基线时，同步更新 `docs/postmortems/README.md` 中的引用。

**开工前必读：**

- [`AGENTS.md`](AGENTS.md) (root) — universal guidelines: language, module separation, UI framework constraints, generated files, screenshot testing, Dart 3.13 syntax, immutability, testing.
- [`app/AGENTS.md`](app/AGENTS.md) — application layer: architecture, `$styles` token usage, Drift database conventions, DI patterns, caching strategy.
- [`packages/AGENTS.md`](packages/AGENTS.md) — package classification, data layer rules, API sub-package conventions (`bilibili`/`youtube`), CI test scope.
- [`app/docs/design-system.md`](app/docs/design-system.md) — design token policy: color literal allow-list, contrast requirements, token roles. **Must read before touching any UI colors, tokens, or theme code.**
- [`packages/bilibili/bpi/AGENTS.md`](packages/bilibili/bpi/AGENTS.md) — Bilibili API sub-package rules.
- [`packages/youtube/ypi/AGENTS.md`](packages/youtube/ypi/AGENTS.md) — YouTube API sub-package rules.
- [`.coderabbit.yaml`](.coderabbit.yaml) — CodeRabbit review configuration (language, review profile, ignore rules).
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution workflow: branch naming, pre-commit checks, and CI status checks.
- [`.fvmrc`](.fvmrc), [`pubspec.yaml`](pubspec.yaml), [`analysis_options.yaml`](analysis_options.yaml), and [`.github/workflows/`](.github/workflows/) — executable SDK, dependency, analysis, and CI behavior; consult these when a rule mentions a command, version, or gate.
- [`docs/runbook.md`](docs/runbook.md) — incident recovery: reverting merged PRs, re-recording golden baselines, unsticking stale CHANGES_REQUESTED.
- [`docs/postmortems/`](docs/postmortems/README.md) — incident write-ups: root causes and the follow-up actions each one left open. Read before dispatching a task to an external coding agent, and before changing a rule that CI depends on.

### Linear 规范

Linear is the authoritative project tracking, scheduling, and progress synchronization system. Its specifications live in:

- [`docs/issue-triage-validation.md`](docs/issue-triage-validation.md) — real trial record of Linear MCP reviewing GitHub Issue sync entries; documents the sync boundary, comment threading, and evidence standards.
- [`.jules/issue-triage-prompt.md`](.jules/issue-triage-prompt.md) — the Jules agent prompt for Linear issue triage (entry review). Defines configuration, scope, identity verification, review budget, result taxonomy, write protocol, and handoff format. Versioned (current v2).
- [`CHANGELOG.md`](CHANGELOG.md) — generated changelog; bucketing uses `c:` label attached by Linear sync (see Release section).
- Linear team: `LIZ`; project: `bili` / `P-LIZ-2`. Sync entry issues may not yet be added to the project — **do not only query project-scoped issues**.
- GitHub mirror issues are an intentional sync mechanism; do not propose disabling it. Close the mirror issue in the same turn after verifying the work is landed (PATCH `state=closed` + closing rationale comment).

**何时读哪个文件：**

| You are about to… | Read first |
|---|---|
| Write or change any app/ widget, Bloc, or repository | `app/AGENTS.md` |
| Touch colors, themes, or design tokens | `app/docs/design-system.md` + `app/AGENTS.md` (Global Style Access section) |
| Add or modify a package under `packages/` | `packages/AGENTS.md` + the relevant sub-package `AGENTS.md` |
| Add a new API endpoint or DTO in `bpi` or `ypi` | The corresponding sub-package `AGENTS.md` (API 子包通用规范 section) |
| Write a test (unit, widget, or golden) | Root `AGENTS.md` (Testing section) + the test's layer file |
| Use the Dart MCP server (code navigation, analysis, pub) | `app/AGENTS.md` (Dart MCP Server section) |
| Change CI workflows or golden baselines | `.github/workflows/ci-*.yml` + `.github/workflows/rerecord-goldens.yml` + `docs/postmortems/README.md` |
| Change SDK, formatter, analyzer, or package commands | `.fvmrc` + root `pubspec.yaml` + relevant `analysis_options.yaml` + `.github/workflows/ci-*.yml` |
| Dispatch a task to an external coding agent | `docs/postmortems/README.md` + the relevant `.github/workflows/` files — check that the brief has a satisfiable CI path before dispatching |
| Bump the app version or cut a release | The Release section below |

### CI Workflow Map

| Workflow | 触发条件 | 产出 check |
|---|---|---|
| `ci-format.yml` | push / PR | Check Formatting |
| `ci-test.yml` | push / PR | Run Flutter Test (矩阵) |
| `ci-build.yml` | push / PR | Build Flutter App (android) (矩阵) |
| `ci-tools.yml` | push / PR | Tool Tests |
| `rerecord-goldens.yml` | workflow_dispatch | 生成 golden 基线 PR |
| `changelog.yml` | push to main | 直接推送 CHANGELOG.md 到 main |
| `code-scanning.yml` | push / PR | Code Scanning |
| `skills_lint.yml` | push / PR | Skills Lint |
| `scan-skills.yml` | push / PR | Skills Code Scanning |
| `dispatch-coderabbit-to-jules.yml` | PR opened / synchronize | 派单到 Jules |
| `automerge-for-google-labs-jules-bot.yml` | PR from Jules bot | 自动合并 |
| `release.yml` | workflow_dispatch / tag | 发布构建 |

## 发布

- **Version source of truth** is `app/pubspec.yaml` `version: X.Y.Z+N`, not the git tag. Local `flutter build` reads the pubspec, so making the tag authoritative would silently produce a wrong `versionCode` on developer machines. The tag is a release marker; `.github/workflows/release.yml` fails the build when `vX.Y.Z` disagrees with the pubspec's `X.Y.Z`.
- **Build number** is injected by CI and never committed. The verification build in `ci-build.yml` uses `--build-number=${{ github.run_number }}`; the release build in `release.yml` uses `run_number * 10 + run_attempt` so that re-running a release workflow yields a distinct `versionCode` (Play rejects duplicates). `--build-name` / `--build-number` and `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` all override the pubspec value.
- **Release signing is mandatory.** `app/android/app/build.gradle.kts` throws `GradleException` when a release build has no `key.properties`, so a release build can never silently fall back to the debug keystore. `BILI_ALLOW_UNSIGNED_RELEASE=1` is the single opt-out; CI sets it to verify that the release variant compiles, and artifacts built that way are not publishable.
- **Status check names carry a version suffix for matrix jobs.** `ci-test.yml` and `ci-build.yml` emit `Run Flutter Test (3.47.7, 3.13.5)` and `Build Flutter App (android) (3.47.7, 3.13.5)` from the root `pubspec.yaml` `environment` matrix; `Check Formatting` is an independent, single-version job. The GitHub ruleset decides which emitted checks are required. **Upgrading Flutter or Dart requires updating the ruleset's required names in the same change**, or every PR can block on a missing check.

- **`CHANGELOG.md` is generated, never hand-edited.** `tool/generate_changelog.py` rebuilds it from git tags plus the GitHub pulls API on every run, so the file is derived state and manual edits do not survive. `.github/workflows/changelog.yml` runs the generator after every push to `main` and pushes the changelog update directly to `main`（2026-10-28 从「开 PR 到 `ci/changelog` 分支」改为直推；changelog 是生成器产出的派生文件，开 PR 会走全套门禁，main 上任何 required check 变红会让 changelog 永久停更）。 Each tag becomes one `## vX.Y.Z - <tag date>` section holding the pull requests merged after the previous tag and no later than this one; the range newer than the newest tag lands under `## [Unreleased]`; the oldest tag absorbs everything merged before it so nothing is dropped. Section headings come from the tag, which means cutting a release needs no manual edit. Bucketing is by `c:` label when the Linear sync attached one, otherwise by the conventional-commit or agent-emoji prefix in the pull request title, with `Other` as the fallback rather than dropping the entry. When the bucketing looks wrong, change the generator, not the file. `generate_changelog.py` 排除来自 `ci/changelog` 分支的 PR（`GENERATED_BRANCH`）——历史 `ci/changelog` PR 仍在仓库中，不排除会让每个已合 changelog PR 产生下一个。该排除按分支名匹配，不按 `ci-generated` label 匹配——golden 基线 workflow 也用同一 label，重录基线是真实历史。 Its unit tests run in the `Tool Tests` job: `python3 -m unittest discover -s tool -p 'test_*.py'`.

For architectural walkthroughs — not prescriptive rules, but context on why boundaries fall where they do:
- [`docs/architecture-learning-journey.md`](docs/architecture-learning-journey.md).
- [`docs/modularization-learning-journey.md`](docs/modularization-learning-journey.md).

## 通用开发指南

### 提交信息格式

PR 标题的 conventional-commit 前缀决定 CHANGELOG.md 的分桶（`tool/generate_changelog.py` 的 `TITLE_SECTIONS`）：

| 前缀 | CHANGELOG 分桶 |
|---|---|
| `feat:` / `feat(` / `Add ` / `Implement ` | Added |
| `fix:` / `fix(` / `Fix ` | Fixed |
| `docs:` / `docs(` | Documentation |
| `test:` / `test(` | Tests |
| `refactor:` / `refactor(` / `design:` / `design(` / `style:` / `style(` / `perf:` / `perf(` | Changed |
| `chore:` / `chore(` / `ci:` / `ci(` | Maintenance |
| `⚡ Bolt:` | Changed |
| `🎨 Palette:` | Changed |
| `🛡️ Sentinel:` | Fixed |
| 无前缀（中文标题含「修复」「修正」等关键词） | Fixed / Other |

Linear sync 附带的 `c:` 标签优先于标题前缀分桶。agent 派单时须在 brief 中指定 PR 标题前缀。

### 不得触碰

- 不得手动修改生成文件（Drift .drift 产物、l10n 等）。修改源文件后运行对应生成命令。
- 不得硬编码面向用户的文案（日志与错误类文案除外）。
- 不得在测试中访问真实网络。
- 不得使用 `material.dart` 或 `cupertino.dart`，使用 `material_ui`。
- 不得降级 Dart SDK 版本。
- 不得对全库跑 `dart format`，只格式化本次改动触及的文件。
- 不得手写 golden 基线。
- 不得用 `ci/changelog` 分支开 PR（changelog 已改为直推 main）。

### SDK 版本

`.fvmrc` 是本地开发与单版本格式门禁的精确 SDK 来源，当前钉在 Flutter 3.47.7（Dart 3.13.5）；根 `pubspec.yaml` 的 `environment` 是包的最低约束，也是 CI 矩阵的输入。两者必须保持下限与本地 pin 一致。

**执行任何 `dart` / `flutter` 命令前，先分别确认两个 SDK 与 `.fvmrc` 一致**（`dart --version` 与 `flutter --version`）。不一致时不要继续，改用 `fvm dart` / `fvm flutter`，或先切到 3.47.7。两个都要看：PATH 里的 Dart 与 Flutter 可能来自不同 SDK，且 Flutter 自带的 Dart 可能与独立安装的 Dart 冲突——只核对 `dart --version` 匹配，仍可能让后续 `flutter` 命令跑在另一个版本上。

原因：`dart format` 的输出随 SDK 版本变化，同一份源码在不同 formatter 上会得到不同排版。agent 在与仓库不一致的 SDK 上跑一次格式化，它碰过的每个文件都会被整体重排；如果这些文件此后又与 main 前进过的版本撞车，PR 就会变成 dirty，而这类 dirty 的净差异里混着「把 main 已合内容改回旧写法」的回退，只能关单重开。2026-10-04 的六条 PR 全部是这个成因。

CI 的 Flutter 版本由根 `pubspec.yaml` 的 `environment` 约束经 `pubspec-matrix-action` 展开，当前产出 `3.47.7, 3.13.5`（下限）与最新 stable 两项；`.fvmrc` 与下限项一致，也是 `rerecord-goldens.yml` 录制 golden 基线所用的版本。**升级 SDK 时 `.fvmrc`、`pubspec.yaml`、ruleset 的 required check 名三者必须同一次改动里一起改。**

### 格式
提交代码前对本次改动的文件运行格式检查；`analysis_options.yaml` 配置了 `formatter`，默认参数见 `dart format --help -v`。

**只格式化本次改动触及的文件**，不要对整个目录或全库跑，也不要把目录作为参数传给 `dart format`——它会递归处理目录下所有 Dart 文件并改写它们，其中未改动的文件也会被重排。格式化一个你没改过的文件，会把它的排版整体换成当前 SDK formatter 的风格，与 main 上尚未重排的部分形成无意义的大范围差异。

```bash
dart format --set-exit-if-changed <本次改动触及的 Dart 文件，逐个列出>
```

该命令会直接改写被格式化的文件，退出码非 0 表示有文件被修改过（即原格式不符），但不代表修复后仍不符。看到退出码非 0 时，先确认文件已被改写，再重跑一次同样的命令，确认退出码为 0 后才可提交。

**CI 有 `Check Formatting` 门禁**；对全库跑 `dart format --output=none --set-exit-if-changed .`，用 `.fvmrc` 里的单个版本，不跑 pubspec 矩阵。门禁覆盖全库，但仍按上面的纪律只格式化本次改动触及的文件：全库已经是当前 SDK 的排版，改动未触及的文件本来就不会被改写，纪律是为了让你在提交前就看清自己那几个文件的变化，而不是依赖 CI 回头打回。

门禁刻意不跑矩阵版本：`dart_style` 会在 patch release 里带非语言版本化的样式修复（例如枚举主构造函数的尾逗号），两个 SDK 版本的 formatter 输出可能不同，同一份代码在一个版本绿、另一个版本红，门禁本身就变成随机失败。一个权威版本足够拦住「未格式化的代码进 main」这件事。**因此 `.fvmrc` 升级时门禁行为可能一次性变化**：先用 CI 同款命令 `dart format --output=none --set-exit-if-changed .` 评估变化；只有明确把全仓库格式迁移纳入该升级 PR 时，才按迁移清单逐文件格式化，否则仍只格式化本次改动触及的文件。

注意：代码格式化命令严禁频繁使用，理想情况下仅完成所有代码修改后使用一次。

### 语言灵活性
- 注释、文档、commit message 可用中文或英文，根据上下文灵活选择。
- 保持代码库内的一致性，同类文件建议统一语言。

### 模块分离
- 在 `app/lib/feature/` 中添加应用功能。将共享逻辑、工具或数据模型添加到 `packages/` 下的对应包。

### UI 框架
- 不得使用 `flutter/material.dart` 或 `flutter/cupertino.dart`，改用 `material_ui`。

### 生成文件
- 不要手动修改生成文件（如 Drift .drift 产物、l10n 等）。需要变更时修改源文件，再运行对应的生成命令重新生成：修改 Drift 或其他由 build_runner 管理的源文件后，运行 `build_runner build`；修改 ARB 文件后，从对应 Flutter package 目录运行 `flutter gen-l10n`。

### 文案与本地化

- 面向用户的文案（label、title、tooltip、hint、SnackBar、错误提示、空态文案）必须放在 `app/lib/l10n/app_.arb`（英文，模板/默认语言）与 `app/lib/l10n/app_zh.arb`（中文），两个文件**键必须完全一致**，值分别为英文与中文。通过 `AppLocalizations.of(context)` 读取，不得硬编码在 Dart 源文件里。
- **日志与错误类文案可以硬编码英文**。这是本规则唯一需要的例外，且不需要任何豁免机制：护栏断言的是「不得有非 ASCII 字面量」，ASCII 天然满足。不要为此引入 ignore 注释或白名单。
- 注释、文档、commit message 不受本规则约束（见 Language Flexibility 段）。
- 这条规则由 `app/test/golden/hardcoded_copy_test.dart` 机器执行，不是纸面约定：断言 `app/lib` 下非生成的 `.dart` 文件里不存在非 ASCII 字符串字面量。唯一的路径级排除是 gen-l10n 的产物目录 `app/lib/l10n/localization_file/`（ARB 的值是它的源，不是硬编码处）。
- 该护栏与 Screenshot Tests 段的字体子集契约是**两件事**：前者管文案放在哪，后者管渲染时有没有字形。新增中文文案需同步改 `app_zh.arb`；子集缺字由 `tool/generate_subset_characters.py` 从生成产物自动收进，再跑 `bin/bili-fonts` 重切 OTF。
- `l10n.yaml` 的 `supported-locales` 必须显式列出 `en` 与 `zh`，确保生成的 `AppLocalizations.supportedLocales` 以英文为首（默认语言）。


### 截图测试

- 应用使用 Alchemist 的 CI golden 基线（`app/test/flutter_test_config.dart` 禁用了 `platformGoldensConfig`）。文字以仓库锁定的字体子集（`app/test/fonts/NotoSansSC-golden-subset.otf`，通过 `FontLoader` 加载）的真实字形渲染，而非 Ahem 占位框——同文件的 `ciGoldensConfig` 中 `obscureText: false` 允许此行为。Alchemist 的 `obscureText` 默认值（`true`）会强制 CI 变体使用 Ahem 字体并忽略主题的 `fontFamily`，该设置是关键配置。
- **为什么用可读字形**：Ahem 将每个字形绘制为 1em 宽且任意两个字符渲染为相同像素，因此 12 个 `i` 的标题与 12 个 `W` 的标题字节完全相同（实测 0 字节差异），文字换行、溢出和字形宽度回归对门禁不可见。字体子集使这些差异可见。
- **代价明确说明**：可读字形换来了对栅格化的依赖。相同字体字节不保证跨 Flutter 版本或平台的相同像素。跨机器一致性依赖 `diffThreshold`，在一个工具链下录制的基线不自动适用于另一个工具链。
- **基线只由 `rerecord-goldens.yml` 录制**：`ci-test.yml` 只比较不更新基线。不得手写基线，不得用本地 PNG 让 CI 变绿。功能分支需要更新基线时，用 `rerecord-goldens.yml` 的 `target_ref` 输入指向该分支。
- `diffThreshold` 为 `0.01`，是比较容差——差异像素比例低于此值的测试仍会通过，通过不等于像素精确相等。
- **覆盖范围限制**：golden test 只证明其渲染的 widget 在该主题下的表现。测试 `pumpWidget` 树外的任何像素变化均未被验证。
- **经验教训**：格式不一致（同一 SDK 下 `dart format` 输出不同）曾导致 2026-10-04 的六条 PR 全部 dirty，只能关单重开。

### Dart 版本与语法
- Do not arbitrarily downgrade the Dart SDK version.
- Prioritize using the repository's **Dart 3.13.x** primary constructors and concise syntax features; do not write syntax that requires a newer SDK than the root constraint.

#### 主构造函数与简洁语法（Dart 3.13+）
权威规范见 Dart constructors — Concise constructor syntax: https://dart.dev/language/constructors#concise-constructor-syntax；本仓库特例见下文的无参类规则。

- **Primary constructors may be parameterless for enums.** Keep explicit empty parentheses for parameterless enum constructors.
  ```dart
  enum ThemeConfig() { followSystem, light, dark; }
  ```
- **Parameterized primary constructors**: Use `var`/`final` in the parameter header to implicitly declare and initialize fields.
  ```dart
  class Person(final String name, var int age);
  ```

- **Constant Constructors**: Place `const` before `class`, `enum`, or `extension type`.
  ```dart
  class const UserProfile(final String id, final String name);
  enum Priority(final int level) { low(1), high(2); }
  ```
- **Class Body Constructors**: Omit repeating class names for secondary (`new`) and factory (`factory`) constructors in class bodies.
  ```dart
  class Logger {
    new(this.name);
    factory fromJson(Map<String, dynamic> json) => Logger(json['name'] as String);
    final String name;
  }
  ```
- **Initializer Scope & Body**: Use `this : initializerList { body }` for assertions or post-initialization logic.
  ```dart
  class Rectangle(final int width, final int height) {
    final int area;
    this : assert(width > 0), area = width * height;
  }
  ```

#### 不可变性与值相等
- **`@immutable`**: Always apply `@immutable` from `package:meta` to data models, state classes, DTOs, and value objects.
- **`EquatableMixin`**: Use `package:equatable` (preferably `EquatableMixin` to preserve class hierarchies) for structural equality on state classes and models. Include all identifying properties in `props`.

## 外部 agent 派单

派单给外部编码 agent 前，先读 [`docs/postmortems/README.md`](docs/postmortems/README.md) 并对照实际 workflow 能力。brief 必须说明预期 CI 状态和依赖生成产物的门禁的合规恢复路径。

派单前核实 brief 中的每条要求在 `.github/workflows/` 中有可执行路径（交集检查），不存在合规路径时停止并升级。

## 测试

Flutter 自身对该层的指导见 `flutter/flutter` 仓库的 `docs/rules/rules.md`（Testing）；以下规则是本仓库实际需要的。

- **测试位置**：单元测试覆盖领域逻辑、仓库和状态管理；widget 测试覆盖 UI；渲染回归由 Alchemist CI golden 覆盖而非断言。
- **准备-执行-断言**：每个测试按 given / when / then 编写，一个行为一个测试。
- **优先 fake 而非 mock**：优先使用手写 fake 和通过构造函数注入的依赖。仅当没有 fake 的接缝时才使用生成的 mock。
- **禁止真实网络**：测试和 CI 均不得访问网络。使用录制 fixture、fake client 或 `MockClient`。
- **Widget 测试框架**：断言缩略图实际**加载**的测试必须将其 pump 包裹在 `network_image_mock` 的 `mockNetworkImagesFor` 中——加载失败的 `CachedNetworkImage` 仍留在树中，断言组件存在证明不了任何事。只断言文字、布局或语义的测试无需 mock。`app/test/flutter_test_config.dart` 已安装假 `path_provider` 和按文件的临时根目录，测试文件中无需再次设置。
- **Widget 测试外壳**：用 `material_ui` fork 的 `MaterialApp` 构建树并注册 `GlobalMaterialLocalizations.delegates`。Flutter 自身的 `MaterialApp` 不提供 fork 的 `MaterialLocalizations`，在非英文 locale 下会抛出异常。
- **断言 widget 树**：当被测代码读取可变全局状态（如 `$styles`）时，测试必须改变该状态并断言渲染输出。从测试中读回同一静态值无论 widget 树是否重建都会通过。
- **泄漏追踪**：从 `app/` 运行 `LEAK_TRACKING=true flutter test` 报告未释放的 disposable。测试在清理前抛出导致的泄漏是可接受的例外；将其标记为例外而非删除测试。

### Flutter 测试运行器主机故障

- `flutter test` 是 Flutter 测试命令，但测试进程实际由平台特定的 `flutter_tester` 二进制启动。测试加载前的失败不证明测试或应用代码有问题。
- 在 Linux/Termux 主机上，已知失败为 `CANNOT LINK EXECUTABLE ... flutter_tester: library "libvk_swiftshader.so" not found`。先确认锁定的 SDK 版本，再尝试 `flutter precache --linux`。若库仍缺失，本地 Flutter SDK 不含该主机兼容的 Linux 测试引擎。
- **不得**通过将任意 `libvulkan*.so` 符号链接为 `libvk_swiftshader.so` 来解决此问题：ABI 和渲染器不同，这会将清晰的启动错误变成 `flutter_tester` 崩溃或无效测试结果。不得向仓库添加主机特定库或测试跳过。
- 使用 `dart run tool/test_local.dart` 运行纯 Dart 回退。它先探测运行器，再运行主机上可用的全部离线检查。在 Termux 上，缺失 `libvk_swiftshader.so` 是已知的 Flutter SDK 主机限制，不是仓库测试失败：完成可本地运行的检查，不要仅因此原因将不可用的 Flutter 套件报告为失败。CI 仍须运行 `.github/workflows/ci-test.yml` 的完整 Flutter 矩阵。仅在明确要求本地 Flutter 运行器且不可用运行器必须立即失败时，使用 `dart run tool/test_local.dart --require-flutter`。
- 对于 PR，核实 CI 的 `Run Flutter Test (…)` 检查覆盖 Flutter/widget/golden。纯 Dart 回退对其实际运行的本地检查是充分证据；已知 Termux 限制无需特殊运行器故障报告（除非有要求）。
