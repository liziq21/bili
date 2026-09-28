# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `youtube`, `components`, `data`, `model`).

## Normative Documents

Before writing or modifying code in this repository, read the specification files that govern your change. This list is the map; each file is the source of truth — no rule is restated here.

**Before starting work, read:**

- [`AGENTS.md`](AGENTS.md) (root) — universal guidelines: language, module separation, UI framework constraints, generated files, screenshot testing, Dart 3.13 syntax, immutability, testing.
- [`app/AGENTS.md`](app/AGENTS.md) — application layer: architecture, `$styles` token usage, Drift database conventions, DI patterns, caching strategy.
- [`packages/AGENTS.md`](packages/AGENTS.md) — package classification, data layer rules, API sub-package conventions (`bilibili`/`youtube`), CI test scope.
- [`app/docs/design-system.md`](app/docs/design-system.md) — design token policy: color literal allow-list, contrast requirements, token roles. **Must read before touching any UI colors, tokens, or theme code.**
- [`packages/bilibili/bpi/AGENTS.md`](packages/bilibili/bpi/AGENTS.md) — Bilibili API sub-package rules.
- [`packages/youtube/ypi/AGENTS.md`](packages/youtube/ypi/AGENTS.md) — YouTube API sub-package rules.
- [`.coderabbit.yaml`](.coderabbit.yaml) — CodeRabbit review configuration (language, review profile, ignore rules).

**When to read each file:**

| You are about to… | Read first |
|---|---|
| Write or change any app/ widget, Bloc, or repository | `app/AGENTS.md` |
| Touch colors, themes, or design tokens | `app/docs/design-system.md` + `app/AGENTS.md` (Global Style Access section) |
| Add or modify a package under `packages/` | `packages/AGENTS.md` + the relevant sub-package `AGENTS.md` |
| Add a new API endpoint or DTO in `bpi` or `ypi` | The corresponding sub-package `AGENTS.md` (API 子包通用规范 section) |
| Write a test (unit, widget, or golden) | Root `AGENTS.md` (Testing section) + the test's layer file |
| Change CI workflow or golden baselines | `.github/workflows/ci.yml` + `.github/workflows/rerecord-goldens.yml` |

For architectural walkthroughs — not prescriptive rules, but context on why boundaries fall where they do:
- [`docs/architecture-learning-journey.md`](docs/architecture-learning-journey.md).
- [`docs/modularization-learning-journey.md`](docs/modularization-learning-journey.md).

## Universal Development Guidelines

### Language Flexibility
- 注释、文档、commit message 可用中文或英文，根据上下文灵活选择。
- 保持代码库内的一致性，同类文件建议统一语言。

### Modular Separation
- Add app features in `app/lib/feature/`. Add shared logic, utilities, or data models to the appropriate package under `packages/`.

### UI Framework
- Do not use `flutter/material.dart` or `flutter/cupertino.dart`. Use `material_ui` instead.

### Generated Files
- 不要手动修改生成文件（如 Drift .drift 产物、l10n 等）。需要变更时修改源文件，再运行对应的生成命令重新生成：修改 Drift 或其他由 build_runner 管理的源文件后，运行 `build_runner build`；修改 ARB 文件后，从对应 Flutter package 目录运行 `flutter gen-l10n`。

### Screenshot Tests

- The app uses **alchemist's CI goldens** (`app/test/flutter_test_config.dart` sets `platformGoldens: false`). They render through a fixed font with text masked into solid blocks, so a recorded baseline does not depend on the machine that recorded it. Do not switch to native `matchesGoldenFile` goldens: the Flutter API docs state that "custom fonts may render differently across different platforms, or between different versions of Flutter" (https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html).
- **Never hand-edit a baseline.** Baselines are generated, not drawn.
- **The target is for CI to record baselines, not workstations.** Baseline re-recording is performed exclusively by the [`rerecord-goldens.yml`](.github/workflows/rerecord-goldens.yml) workflow (manual trigger only); `ci.yml` compares but does not update baselines. A local re-record is never a substitute. `Run Flutter Test` fails only when the comparison exceeds `diffThreshold` — a rendering change small enough to fall inside the 0.01 tolerance passes without a baseline update, so a green check does not mean the baseline is current.
- `diffThreshold` is `0.01`, a comparison tolerance — the maximum fraction of differing pixels that still passes. A passing golden test does not prove pixel-exact equality.
- **Coverage limit**: a golden test proves only the widgets it renders, under the theme it records. Treating "the goldens did not change" as proof that no visible pixel changed anywhere is unsupported — anything outside a test's own `pumpWidget` tree is unverified.

### Dart Version & Syntax
- Do not arbitrarily downgrade the Dart SDK version.
- Prioritize using **Dart 3.13.0** primary constructors and concise syntax features.

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
