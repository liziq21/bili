# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `youtube`, `components`, `data`, `model`).

For directory-specific guidelines, refer to:
- [`app/AGENTS.md`](app/AGENTS.md) for application layer, Drift database, caching, UI styles, dependency injection, and app tooling commands.
- [`packages/AGENTS.md`](packages/AGENTS.md) for package classification, data layer models, remote data sources, and package tooling commands.

For a guided walkthrough of the architecture — one request traced from the widget down to the HTTP call, with the official documentation each principle comes from — see:
- [`docs/architecture-learning-journey.md`](docs/architecture-learning-journey.md).

For how the repository is split into packages, which dependency directions are allowed, and why the boundaries fall where they do — see:
- [`docs/modularization-learning-journey.md`](docs/modularization-learning-journey.md).

## Universal Development Guidelines

### Formatting
提交代码前对本次改动的文件运行格式检查；`analysis_options.yaml` 配置了 `formatter`，默认参数见 `dart format --help -v`。

```bash
dart format --set-exit-if-changed <changed files or directories>
```

该命令会直接改写被格式化的文件，退出码非 0 表示有文件被修改过（即原格式不符），但不代表修复后仍不符。看到退出码非 0 时，先确认文件已被改写，再重跑一次同样的命令，确认退出码为 0 后才可提交。

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
- **The target is for CI to record baselines, not workstations.** The repository has no baseline-recording step: `ci.yml` only compares. Until one is added, a change to what a covered widget renders is finished by re-recording from `app/` with `flutter test test/golden/<file>_golden_test.dart --update-goldens` and committing the result. `Run Flutter Test` fails only when the comparison exceeds `diffThreshold` — a rendering change small enough to fall inside the 0.01 tolerance passes without a baseline update, so a green check does not mean the baseline is current.
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
