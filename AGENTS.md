# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `components`, `data`, `model`).

For directory-specific guidelines, refer to:
- [`app/AGENTS.md`](app/AGENTS.md) for application layer, Drift database, caching, UI styles, and app tooling commands.
- [`packages/AGENTS.md`](packages/AGENTS.md) for package types, data layer models, and package tooling commands.

## Universal Development Guidelines

### Language Flexibility
- 注释、文档、commit message 可用中文或英文，根据上下文灵活选择。
- 保持代码库内的一致性，同类文件建议统一语言。

### Modular Separation
- Add app features in `app/lib/feature/`. Add shared logic, utilities, or data models to the appropriate package under `packages/`.

### UI Framework
- Do not use `flutter/material.dart` or `flutter/cupertino.dart`. Use `material_ui` instead.

### Dart Version & Syntax
- Do not arbitrarily downgrade the Dart SDK version.
- Prioritize using **Dart 3.13.0** features for cleaner, more expressive code.

#### Primary Constructors (Dart 3.13+)

Primary constructors allow declaring fields and constructors directly in the class header, significantly reducing boilerplate.

**Key Syntax**:
```dart
// Basic primary constructor with declaring parameters
class User(final String name, final int age);

// With custom initializer list
class Point(final int x, int delta) {
  this : assert(x >= 0), y = x + delta;
  final int y;
}

// Empty body uses semicolon
class Config(String key, String value);

// Const primary constructor
class const Color(int r, int g, int b);
```

**Usage Scenarios**:
- **Data Models**: Convert traditional constructors to primary constructors
- **Value Objects**: Immutability-friendly classes
- **State Classes**: BLoC/Cubit state classes
- **Business Entities**: Domain models
- **UI Components**: Widget classes with required parameters

**Benefits**:
- Eliminates `this.field = field` boilerplate
- Primary Initializer Scope allows referencing parameters in field initializers
- Empty body shorthand (`;`) replaces `{}`
- Supports `copyWith`, getters, and methods in the body

#### @immutable Annotation

Apply `@immutable` from `package:meta` to enforce compile-time immutability.

**Applicable to**:
- Data models and DTOs
- Value objects
- Business entities
- State classes
- Request/Response objects
- Any object that should not be mutated after creation

```dart
import 'package:meta/meta.dart';

@immutable
class const User(final String id, final String name, final int age) {
  User copyWith({String? name, int? age}) =>
      User(name ?? this.name, age ?? this.age);
}
```

**Benefits**:
- IDE highlights mutation attempts
- Documented intent for consumers
- Prevents accidental state mutations
- Works well with `copyWith` pattern

#### equatable Package

Use `package:equatable` for value-based equality when identity equality (`==`) is insufficient.

**Applicable to**:
- Data classes used as map keys or set members
- State classes in state management (Provider, riverpod, BLoC)
- Test fixtures and mock objects
- Any class where structural equality matters

```dart
import 'package:equatable/equatable.dart';

// Using EquatableMixin
@immutable
class VideoItem extends Equatable {
  final String id;
  final String title;
  final Duration duration;

  const VideoItem(this.id, this.title, this.duration);

  @override
  List<Object?> get props => [id, title, duration];
}

// Or using EquatableMixin with fields
@immutable
class SearchQuery extends EquatableMixin {
  final String query;
  final int page;

  const SearchQuery(this.query, this.page);

  @override
  List<Object?> get props => [query, page];
}
```

**Best Practices**:
- Combine with `@immutable` for immutable data classes
- Include all relevant fields in `props`
- Exclude computed/calculated fields
- Avoid circular references in props
- Consider performance impact for frequently compared objects

**Note**: Use `EquatableMixin` (not base class inheritance) to preserve class hierarchy.
