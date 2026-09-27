# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `youtube`, `components`, `data`, `model`).

For directory-specific guidelines, refer to:
- [`app/AGENTS.md`](app/AGENTS.md) for application layer, Drift database, caching, UI styles, dependency injection, and app tooling commands.
- [`packages/AGENTS.md`](packages/AGENTS.md) for package classification, data layer models, remote data sources, and package tooling commands.

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
