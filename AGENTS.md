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

#### Primary Constructors & Concise Constructors (Dart 3.13+)

Primary constructors allow declaring constructors and instance fields directly in the class, enum, or extension type header, eliminating repetitive field declarations and assignment boilerplate while preserving full type safety and performance.

**Core Language Specifications & Syntax**:

1. **Declaring Parameters (`var` / `final`) vs Non-declaring Parameters**:
   - `var` or `final` before a parameter implicitly declares an instance field and initializes it.
   - Parameters without `var` or `final` do **not** declare fields; they are only in scope during initialization (e.g., passed to `super`, referenced in initializer list, or used in constructor body).
   ```dart
   // Declares instance fields `name` (final) and `age` (mutable field with getter/setter)
   class Person(final String name, var int age);

   // `id` is a non-declaring parameter used only for super constructor forwarding
   class User(final String name, String id) : super(id);
   ```

2. **Named Primary Constructors**:
   ```dart
   // Primary constructor with a named identifier
   class Point.custom(var int x, var int y);
   ```

3. **`this` Body Syntax (Initializer List & Constructor Body)**:
   When primary constructors require assertions, custom field initializations, or body execution, use the `this` keyword followed by an optional initializer list (`:`) and a body block (`{}`):
   ```dart
   class Rectangle(final int width, final int height) {
     final int area;
     this : assert(width > 0 && height > 0), area = width * height {
       print('Created rectangle with area: $area');
     }
   }
   ```

4. **`class const`, `enum const`, & `extension type const`**:
   For constant primary constructors, place the `const` modifier **before** the `class`, `enum`, or `extension type` keyword:
   ```dart
   // Constant primary class constructor
   class const Color(final int r, final int g, final int b);

   // Constant extension type
   extension type const UserId(final String id);

   // Constant enhanced enum
   enum const Priority(final int level) {
     low(1),
     high(2);
   }
   ```

5. **Concise `new` and `factory` Constructors in Class Body**:
   Inside class bodies, secondary generative constructors (`new`) and factory constructors (`factory`) omit repeating the class name:
   ```dart
   class Logger {
     final String name;

     // Concise unnamed generative constructor
     new(this.name);

     // Concise named generative constructor
     new internal(this.name);

     // Concise factory constructor
     factory fromJson(Map<String, dynamic> json) =>
         Logger(json['name'] as String);
   }
   ```

6. **Super Parameters & Named/Optional Parameters**:
   ```dart
   class BaseItem(final String id);

   // Super parameters in primary constructor
   class VideoItem(final String title, super.id) extends BaseItem;

   // Named and required parameters in primary constructor
   class Button({final String label = '', required var void Function() onClick});
   ```

**Usage Guidelines & Application Scenarios**:

- **Data Models / Value Objects**: Combine `@immutable` with `class const` and primary constructors for clean, immutable data classes.
  ```dart
  import 'package:meta/meta.dart';

  @immutable
  class const UserProfile(
    final String id,
    final String name,
    final String avatarUrl,
  ) {
    UserProfile copyWith({String? name, String? avatarUrl}) =>
        UserProfile(id, name ?? this.name, avatarUrl ?? this.avatarUrl);
  }
  ```

- **Enhanced Enums**: Use primary constructors for clean enum parameter definitions.
  ```dart
  enum Vehicle(
    final int tires,
    final int passengers,
  ) {
    car(4, 5),
    bus(6, 50),
    bicycle(2, 1);

    bool get isTwoWheeled => tires == 2;
  }
  ```

- **State Classes (BLoC / Cubit / Provider)**: Reduce state boilerplate.
  ```dart
  @immutable
  class const SearchState({
    final List<String> results = const [],
    final bool isLoading = false,
    final String? error,
  });
  ```

**Benefits**:
- Drastically reduces constructor boilerplate across models, widgets, and state classes
- Primary Initializer Scope enables referencing parameters directly in field initializers
- Modernized, concise constructor syntax (`new`, `factory`, `class const`) aligned with Dart 3.13+ standards

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
