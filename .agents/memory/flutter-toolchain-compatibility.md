---
name: Flutter toolchain compatibility
description: Imported Flutter workspaces may require a newer Dart/Flutter SDK than the environment provides.
---

Check the repository's Dart and Flutter constraints before resolving dependencies or configuring a run workflow. If the available SDK is older, preserve the upstream constraints and look for a matching toolchain rather than silently lowering them.

**Why:** Dart workspace syntax and package APIs can depend on newer SDK releases, so an older toolchain can produce misleading dependency or resolution failures.

**How to apply:** Compare `environment.sdk` and `environment.flutter` with `dart --version` and `flutter --version` immediately after importing a Flutter repository.