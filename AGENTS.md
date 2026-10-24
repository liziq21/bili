# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `youtube`, `data`, `model`). `packages/components/` is currently reserved and has no `pubspec.yaml`, so it is not a workspace package.

## Normative Documents

Before writing or modifying code in this repository, read the specification files that govern your change. This list is the map; each file is the source of truth — no rule is restated here.

### Rule ownership and precedence

- Executable configuration is authoritative for what the tooling actually does: `.fvmrc`, the root `pubspec.yaml`, `analysis_options.yaml`, package `pubspec.yaml` files, and `.github/workflows/`.
- `AGENTS.md` rules apply to the directory they are in. When rules overlap, the most specific applicable `AGENTS.md` wins; a package rule may narrow a root rule but must not silently contradict it.
- `app/docs/design-system.md` owns color, theme, token, and contrast policy. `packages/AGENTS.md` owns shared package and API-package boundaries; `bpi/AGENTS.md` and `ypi/AGENTS.md` add platform-specific details only.
- `README.md`, learning journeys, journals, and postmortems provide context or history. They must link to the owning rule instead of creating a second source of truth. `docs/runbook.md` is normative only for incident recovery steps.
- If a document and executable configuration disagree, do not guess: fix the document or configuration in the same change, and state which behavior is intended.

**Before starting work, read:**

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

### Linear Specifications

Linear is the authoritative project tracking, scheduling, and progress synchronization system. Its specifications live in:

- [`docs/issue-triage-validation.md`](docs/issue-triage-validation.md) — real trial record of Linear MCP reviewing GitHub Issue sync entries; documents the sync boundary, comment threading, and evidence standards.
- [`.jules/issue-triage-prompt.md`](.jules/issue-triage-prompt.md) — the Jules agent prompt for Linear issue triage (entry review). Defines configuration, scope, identity verification, review budget, result taxonomy, write protocol, and handoff format. Versioned (current v2).
- [`CHANGELOG.md`](CHANGELOG.md) — generated changelog; bucketing uses `c:` label attached by Linear sync (see Release section).
- Linear team: `LIZ`; project: `bili` / `P-LIZ-2`. Sync entry issues may not yet be added to the project — **do not only query project-scoped issues**.
- GitHub mirror issues are an intentional sync mechanism; do not propose disabling it. Close the mirror issue in the same turn after verifying the work is landed (PATCH `state=closed` + closing rationale comment).

**When to read each file:**

| You are about to… | Read first |
|---|---|
| Write or change any app/ widget, Bloc, or repository | `app/AGENTS.md` |
| Touch colors, themes, or design tokens | `app/docs/design-system.md` + `app/AGENTS.md` (Global Style Access section) |
| Add or modify a package under `packages/` | `packages/AGENTS.md` + the relevant sub-package `AGENTS.md` |
| Add a new API endpoint or DTO in `bpi` or `ypi` | The corresponding sub-package `AGENTS.md` (API 子包通用规范 section) |
| Write a test (unit, widget, or golden) | Root `AGENTS.md` (Testing section) + the test's layer file |
| Use the Dart MCP server (code navigation, analysis, pub) | `app/AGENTS.md` (Dart MCP Server section) |
| Change CI workflow or golden baselines | `.github/workflows/ci.yml` + `.github/workflows/rerecord-goldens.yml` + `docs/postmortems/README.md` |
| Change SDK, formatter, analyzer, or package commands | `.fvmrc` + root `pubspec.yaml` + relevant `analysis_options.yaml` + `.github/workflows/ci.yml` |
| Dispatch a task to an external coding agent | `docs/postmortems/README.md` + the relevant `.github/workflows/` files — check that the brief has a satisfiable CI path before dispatching |
| Bump the app version or cut a release | The Release section below |

## Release

- **Version source of truth** is `app/pubspec.yaml` `version: X.Y.Z+N`, not the git tag. Local `flutter build` reads the pubspec, so making the tag authoritative would silently produce a wrong `versionCode` on developer machines. The tag is a release marker; `.github/workflows/release.yml` fails the build when `vX.Y.Z` disagrees with the pubspec's `X.Y.Z`.
- **Build number** is injected by CI and never committed. The verification build in `ci.yml` uses `--build-number=${{ github.run_number }}`; the release build in `release.yml` uses `run_number * 10 + run_attempt` so that re-running a release workflow yields a distinct `versionCode` (Play rejects duplicates). `--build-name` / `--build-number` and `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` all override the pubspec value.
- **Release signing is mandatory.** `app/android/app/build.gradle.kts` throws `GradleException` when a release build has no `key.properties`, so a release build can never silently fall back to the debug keystore. `BILI_ALLOW_UNSIGNED_RELEASE=1` is the single opt-out; CI sets it to verify that the release variant compiles, and artifacts built that way are not publishable.
- **Status check names carry a version suffix for matrix jobs.** `ci.yml` emits `Run Flutter Test (3.47.5, 3.13.4)` and `Build Flutter App (android) (3.47.5, 3.13.4)` from the root `pubspec.yaml` `environment` matrix; `Check Formatting` is an independent, single-version job. The GitHub ruleset decides which emitted checks are required. **Upgrading Flutter or Dart requires updating the ruleset's required names in the same change**, or every PR can block on a missing check.

- **`CHANGELOG.md` is generated, never hand-edited.** `tool/generate_changelog.py` rebuilds it from git tags plus the GitHub pulls API on every run, so the file is derived state and manual edits do not survive. `.github/workflows/changelog.yml` runs the generator after every push to `main` and opens a PR against the fixed branch `ci/changelog` only when the output actually changed. Each tag becomes one `## vX.Y.Z - <tag date>` section holding the pull requests merged after the previous tag and no later than this one; the range newer than the newest tag lands under `## [Unreleased]`; the oldest tag absorbs everything merged before it so nothing is dropped. Section headings come from the tag, which means cutting a release needs no manual edit. Bucketing is by `c:` label when the Linear sync attached one, otherwise by the conventional-commit or agent-emoji prefix in the pull request title, with `Other` as the fallback rather than dropping the entry. When the bucketing looks wrong, change the generator, not the file. Pull requests opened from the `ci/changelog` branch are excluded: the workflow runs on every merge, so without that exclusion each merged changelog pull request is itself a merged pull request and produces the next one forever. The exclusion matches the branch, not the `ci-generated` label — the golden-baseline workflow labels its pull requests the same way and re-recording a baseline is real history. Its unit tests run in the `Tool Tests` job: `python3 -m unittest discover -s tool -p 'test_*.py'`.

For architectural walkthroughs — not prescriptive rules, but context on why boundaries fall where they do:
- [`docs/architecture-learning-journey.md`](docs/architecture-learning-journey.md).
- [`docs/modularization-learning-journey.md`](docs/modularization-learning-journey.md).

## Universal Development Guidelines

### SDK 版本

`.fvmrc` 是本地开发与单版本格式门禁的精确 SDK 来源，当前钉在 Flutter 3.47.5（Dart 3.13.4）；根 `pubspec.yaml` 的 `environment` 是包的最低约束，也是 CI 矩阵的输入。两者必须保持下限与本地 pin 一致。

**执行任何 `dart` / `flutter` 命令前，先分别确认两个 SDK 与 `.fvmrc` 一致**（`dart --version` 与 `flutter --version`）。不一致时不要继续，改用 `fvm dart` / `fvm flutter`，或先切到 3.47.5。两个都要看：PATH 里的 Dart 与 Flutter 可能来自不同 SDK，且 Flutter 自带的 Dart 可能与独立安装的 Dart 冲突——只核对 `dart --version` 匹配，仍可能让后续 `flutter` 命令跑在另一个版本上。

原因不是洁癖：`dart format` 的输出随 SDK 版本变化，同一份源码在不同 formatter 上会得到不同排版。agent 在与仓库不一致的 SDK 上跑一次格式化，它碰过的每个文件都会被整体重排；如果这些文件此后又与 main 前进过的版本撞车，PR 就会变成 dirty，而这类 dirty 的净差异里混着「把 main 已合内容改回旧写法」的回退，只能关单重开。2026-10-04 的 #220、#222、#232、#234、#235、#236 六条 PR 全部是这个成因。

CI 的 Flutter 版本由根 `pubspec.yaml` 的 `environment` 约束经 `pubspec-matrix-action` 展开，当前产出 `3.47.5, 3.13.4`（下限）与最新 stable 两项；`.fvmrc` 与下限项一致，也是 `rerecord-goldens.yml` 录制 golden 基线所用的版本。**升级 SDK 时 `.fvmrc`、`pubspec.yaml`、ruleset 的 required check 名三者必须同一次改动里一起改。**

### Formatting
提交代码前对本次改动的文件运行格式检查；`analysis_options.yaml` 配置了 `formatter`，默认参数见 `dart format --help -v`。

**只格式化本次改动触及的文件**，不要对整个目录或全库跑，也不要把目录作为参数传给 `dart format`——它会递归处理目录下所有 Dart 文件并改写它们，其中未改动的文件也会被重排。格式化一个你没改过的文件，会把它的排版整体换成当前 SDK formatter 的风格，与 main 上尚未重排的部分形成无意义的大范围差异。

```bash
dart format --set-exit-if-changed <本次改动触及的 Dart 文件，逐个列出>
```

该命令会直接改写被格式化的文件，退出码非 0 表示有文件被修改过（即原格式不符），但不代表修复后仍不符。看到退出码非 0 时，先确认文件已被改写，再重跑一次同样的命令，确认退出码为 0 后才可提交。

**CI 有 `Check Formatting` 门禁**；对全库跑 `dart format --output=none --set-exit-if-changed .`，用 `.fvmrc` 里的单个版本，不跑 pubspec 矩阵。门禁覆盖全库，但仍按上面的纪律只格式化本次改动触及的文件：全库已经是当前 SDK 的排版，改动未触及的文件本来就不会被改写，纪律是为了让你在提交前就看清自己那几个文件的变化，而不是依赖 CI 回头打回。

门禁刻意不跑矩阵版本：`dart_style` 会在 patch release 里带非语言版本化的样式修复（例如枚举主构造函数的尾逗号），两个 SDK 版本的 formatter 输出可能不同，同一份代码在一个版本绿、另一个版本红，门禁本身就变成随机失败。一个权威版本足够拦住「未格式化的代码进 main」这件事。**因此 `.fvmrc` 升级时门禁行为可能一次性变化**：先用 CI 同款命令 `dart format --output=none --set-exit-if-changed .` 评估变化；只有明确把全仓库格式迁移纳入该升级 PR 时，才按迁移清单逐文件格式化，否则仍只格式化本次改动触及的文件。

注意：代码格式化命令严禁频繁使用，理想情况下仅完成所有代码修改后使用一次。

### Language Flexibility
- 注释、文档、commit message 可用中文或英文，根据上下文灵活选择。
- 保持代码库内的一致性，同类文件建议统一语言。

### Modular Separation
- Add app features in `app/lib/feature/`. Add shared logic, utilities, or data models to the appropriate package under `packages/`.

### UI Framework
- Do not use `flutter/material.dart` or `flutter/cupertino.dart`. Use `material_ui` instead.

### Generated Files
- 不要手动修改生成文件（如 Drift .drift 产物、l10n 等）。需要变更时修改源文件，再运行对应的生成命令重新生成：修改 Drift 或其他由 build_runner 管理的源文件后，运行 `build_runner build`；修改 ARB 文件后，从对应 Flutter package 目录运行 `flutter gen-l10n`。

### 文案与本地化（Copy and Localization）

- 面向用户的文案（label、title、tooltip、hint、SnackBar、错误提示、空态文案）必须放在 `app/lib/l10n/app_.arb`（英文，模板/默认语言）与 `app/lib/l10n/app_zh.arb`（中文），两个文件**键必须完全一致**，值分别为英文与中文。通过 `AppLocalizations.of(context)` 读取，不得硬编码在 Dart 源文件里。
- **日志与错误类文案可以硬编码英文**。这是本规则唯一需要的例外，且不需要任何豁免机制：护栏断言的是「不得有非 ASCII 字面量」，ASCII 天然满足。不要为此引入 ignore 注释或白名单。
- 注释、文档、commit message 不受本规则约束（见 Language Flexibility 段）。
- 这条规则由 `app/test/golden/hardcoded_copy_test.dart` 机器执行，不是纸面约定：断言 `app/lib` 下非生成的 `.dart` 文件里不存在非 ASCII 字符串字面量。唯一的路径级排除是 gen-l10n 的产物目录 `app/lib/l10n/localization_file/`（ARB 的值是它的源，不是硬编码处）。
- 该护栏与 Screenshot Tests 段的字体子集契约是**两件事**：前者管文案放在哪，后者管渲染时有没有字形。新增中文文案需同步改 `app_zh.arb`；子集缺字由 `tool/generate_subset_characters.py` 从生成产物自动收进，再跑 `bin/bili-fonts` 重切 OTF。
- `l10n.yaml` 的 `supported-locales` 必须显式列出 `en` 与 `zh`，确保生成的 `AppLocalizations.supportedLocales` 以英文为首（默认语言）。


### Screenshot Tests

- The app uses **alchemist's CI goldens** (`app/test/flutter_test_config.dart` disables `platformGoldensConfig`). Text renders as **real glyphs** from a repository-pinned font subset (`app/test/fonts/NotoSansSC-golden-subset.otf`, loaded with `FontLoader` in `app/test/golden/golden_font.dart`), not as Ahem boxes — `obscureText: false` in the same file's `ciGoldensConfig` is what allows it. Alchemist's `obscureText` default (`true`) forces the Ahem family onto the CI variant and ignores the theme's `fontFamily`, so the setting is load-bearing, not cosmetic.
- **Why readable glyphs**: Ahem draws every glyph 1em wide and renders identical pixels for any two characters, so with Ahem a 12-character title of `i` and one of `W` are byte-identical (measured: 0 differing bytes) and text wrapping, overflow, and glyph-width regressions are invisible to the gate. The subset makes those visible, at the cost below.
- **The cost, stated plainly**: readable glyphs buy width sensitivity at the price of depending on the rasteriser. Identical font bytes do not guarantee identical pixels across differing Flutter versions or platforms — the same caveat the Flutter docs give for `matchesGoldenFile` (https://api.flutter.dev/flutter_test/matchesGoldenFile.html). Cross-machine agreement therefore rests on `diffThreshold`, and a baseline recorded under one toolchain is not automatically valid under another.
- **What has actually been verified**: byte-exact agreement across two independent Linux machines at Flutter 3.47.5 stable. A sandbox recording (commit `5321b5c`, git blob `634d67a4…` / `1bd5f1dd…`) and the `ubuntu-latest` recording made by `rerecord-goldens.yml` run 36560934576 produced **identical blob SHAs** for both baselines — byte-for-byte equal, not a tolerance pass. Both sides used the version the workflows pin (`rerecord-goldens.yml` pins 3.47.5 in its `flutter-actions/setup-flutter` step, and `ci.yml`'s matrix both resolve to 3.47.5). Recording is also stable across commits that change the font: `ea5089e` added 13 code points to the subset (new font blob `df51cba9…`) and all three baselines kept their original blob SHAs, so extending the subset does not perturb existing glyph rendering. Re-run the blob-SHA comparison after any Flutter version bump, platform change, or font re-subset; a green `Run Flutter Test` alone does **not** demonstrate byte-exactness, because a pass within `diffThreshold` is indistinguishable from a smaller-but-real difference.
- The font is a **test asset only**. It must never reach the app bundle: `pubspec.yaml` declares no `fonts:` or `assets:` entry for it, and `golden_font_contract_test.dart` fails if one appears. `FontLoader` keeps it inside the test process, so production pixels and APK size are unaffected.
- The subset must keep covering every character the app can render; a character it lacks silently renders as a tofu box, and the baseline still looks plausible. `golden_font_contract_test.dart` reads coverage from the OTF's own `cmap` (not from the `subset-characters.txt` input snapshot) and walks `lib/`+`test/` string literals through `package:analyzer`. When it reports missing characters, re-subset rather than editing the list alone. Astral characters (U+1F44D) are outside the subset's reach: Noto Sans CJK stops at U+3106C and carries no emoji, and that character belongs to a widget test, not a golden fixture.
- **Never hand-edit a baseline.** Baselines are generated, not drawn.
- **The target is for CI to record baselines, not workstations.** Baseline re-recording is performed exclusively by the [`rerecord-goldens.yml`](.github/workflows/rerecord-goldens.yml) workflow (manual trigger only); `ci.yml` compares but does not update baselines. A local re-record is never a substitute. When a golden comparison has loaded a readable baseline and its matcher setup succeeds, a pixel-difference failure occurs only when the difference exceeds `diffThreshold` — a rendering change small enough to fall inside the 0.01 tolerance may pass without a baseline update, so a green check does not mean the baseline is current.
- **Feature branch recording**: `rerecord-goldens.yml` declares a required `target_ref` input under `on.workflow_dispatch.inputs` (default `main`), passes it to the `actions/checkout` step as its `ref:` input, and opens the generated PR with `create-pull-request`'s `base: ${{ inputs.target_ref }}`, so a PR that changes a widget covered by an existing golden test can have its baseline updated from the PR's own branch — dispatch the workflow with `target_ref` set to that branch. A `/` in the branch name is sanitised to `-` for the generated PR branch name, because a branch name cannot contain `/` without becoming a nested ref. Such a PR targets a non-`main` base, and `ci.yml` runs on pull requests to any base, so the generated baseline PR is not merged without the same checks a `main` PR gets.
- `diffThreshold` is `0.01`, a comparison tolerance — the maximum fraction of differing pixels that still passes. A passing golden test does not prove pixel-exact equality.
- **Coverage limit**: a golden test proves only the widgets it renders, under the theme it records. Treating "the goldens did not change" as proof that no visible pixel changed anywhere is unsupported — anything outside a test's own `pumpWidget` tree is unverified.

### Dart Version & Syntax
- Do not arbitrarily downgrade the Dart SDK version.
- Prioritize using the repository's **Dart 3.13.x** primary constructors and concise syntax features; do not write syntax that requires a newer SDK than the root constraint.

#### Primary Constructors & Concise Syntax (Dart 3.13+)
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

#### Immutability & Value Equality
- **`@immutable`**: Always apply `@immutable` from `package:meta` to data models, state classes, DTOs, and value objects.
- **`EquatableMixin`**: Use `package:equatable` (preferably `EquatableMixin` to preserve class hierarchies) for structural equality on state classes and models. Include all identifying properties in `props`.

## External agent dispatch

Before dispatching an external coding agent, read [`docs/postmortems/README.md`](docs/postmortems/README.md) and compare the brief with the actual workflow capabilities. The brief must state the expected CI state and the compliant recovery path when a gate depends on generated output.

For any golden-test task, the brief must explicitly state all three items:

1. CI may remain red until a baseline is present; do not create a local PNG to make it green.
2. The only recording path is `rerecord-goldens.yml`; use `target_ref` for the branch that owns the change.
3. The task must not merge or hand-edit baselines; review the CI-generated baseline PR and its provenance instead.

Before dispatching, verify that each requirement in the brief has an executable path in `.github/workflows/` (an intersection check), and stop/escalate when no compliant path exists.

## Testing

Flutter's own guidance for this layer is `docs/rules/rules.md` (Testing) in the `flutter/flutter` repository; the rules below are the ones this repository actually needs.

- **Where a test goes**: Unit tests cover domain logic, repositories, and state management; widget tests cover UI; rendering regressions are covered by Alchemist CI goldens rather than by assertions.
- **Arrange-Act-Assert**: Write each test as given / when / then, one behaviour per test.
- **Fakes over mocks**: Prefer hand-written fakes and dependencies injected through the constructor. Use a generated mock only where no seam exists for a fake.
- **No real network**: Neither tests nor CI may reach the network. Use a recorded fixture, a fake client, or `MockClient`.
- **Widget test harness**: A test that asserts a thumbnail actually **loaded** must wrap its pumps in `mockNetworkImagesFor` from `network_image_mock` — a `CachedNetworkImage` that fails to load still stays in the tree, so asserting the component exists proves nothing. Tests that assert only text, layout, or semantics need no mock. `app/test/flutter_test_config.dart` already installs a fake `path_provider` and a per-file temp root, so neither is set up again in the test file.
- **Widget test shell**: Build the tree with the `material_ui` fork's `MaterialApp` and register `GlobalMaterialLocalizations.delegates`. Flutter's own `MaterialApp` does not supply the fork's `MaterialLocalizations` and throws under a non-English locale.
- **Assert on the widget tree**: When the code under test reads mutable global state such as `$styles`, the test must change that state and assert on rendered output. Reading the same static back from the test passes whether or not the widget tree rebuilt.
- **Leak tracking**: Run `LEAK_TRACKING=true flutter test` from `app/` to report disposables that were never disposed. A leak caused by a test that threw before it could clean up is an acceptable exception; mark it as one rather than deleting the test.

### Flutter Test Runner Host Failures

- `flutter test` is a Flutter test command, but the test process is actually
  started by the platform-specific `flutter_tester` binary. A failure before a
  test is loaded is therefore not evidence that the test or application code
  failed.
- On Linux/Termux hosts, a known failure is
  `CANNOT LINK EXECUTABLE ... flutter_tester: library "libvk_swiftshader.so"
  not found`. First confirm the pinned SDK versions, then try
  `flutter precache --linux`. If the library is still absent, the local Flutter
  SDK does not contain a compatible Linux test engine for that host.
- Do **not** solve this by symlinking an arbitrary `libvulkan*.so` as
  `libvk_swiftshader.so`: the ABI and renderer are different, and this can
  turn a clear startup error into a `flutter_tester` crash or invalid test
  result. Do not add a host-specific library or a test skip to the repository.
- Use `dart run tool/test_local.dart` to run the pure-Dart fallback. It probes
  the runner first and runs every offline check available on the host. On
  Termux, a missing `libvk_swiftshader.so` is a known Flutter SDK host
  limitation, not a repository test failure: complete the checks that can run
  locally, and do not report the unavailable Flutter suites as failed solely
  for this reason. CI must still run the complete Flutter matrix from
  `.github/workflows/ci.yml`. Use `dart run tool/test_local.dart --require-flutter`
  only when a local Flutter runner is explicitly required and an unavailable
  runner must fail immediately.
- For a pull request, verify the CI `Run Flutter Test (…)` checks for
  Flutter/widget/golden coverage. The pure-Dart fallback is sufficient
  evidence for the local checks it actually ran; no special runner-failure
  report is needed for the known Termux limitation unless requested.

---

## Appendix: Linear Specifications (require Linear MCP access)

These three specifications live in Linear (team `LIZ`, project `bili` / `P-LIZ-2`) and are read via Linear MCP. They are **not** in the git repository.

| 规范 | 作用 | 读取方式 |
|---|---|---|
| **《AI 工单接取规范》** | 定义 Backlog → Todo 移交条件、实现接取使用 Draft PR + `[AI CLAIM]` 标记 | Linear MCP `get_document` / `list_documents` |
| **《Backlog HITL/AFK 分类》** | Backlog 项按「有没有岔路口需人拍板」分 HITL/AFK，与 P0–P3 正交 | Linear MCP `get_document` / `list_documents` |
| **《项目标签规范》** | 项目标签体系、单选/多选分组、标签命名约定 | Linear MCP `get_document` / `list_documents` |

**读取提示**：这些文档在 Linear 的 project resources 或 team 文档区。通过 Linear MCP 搜索标题精确匹配；若同步到 GitHub 会有对应 issue 附件，但以 Linear 侧最新版为准。`.jules/issue-triage-prompt.md` §1 第 5 条要求 triage agent 开工前读取这三份最新版。
