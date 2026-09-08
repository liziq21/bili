# Bili App Project Overview & Guidelines

This repository is a Flutter workspace project with a modular structure separating the main application in `app/` and reusable sub-packages in `packages/`.

## Project Structure

- `app/`: The main Flutter application.
- `packages/`: Shared packages/modules (`bilibili`, `components`, `data`, `model`).

For directory-specific guidelines, refer to:
- [`app/AGENTS.md`](app/AGENTS.md) for application layer, Drift database, caching, UI styles, and app tooling commands.
- [`packages/AGENTS.md`](packages/AGENTS.md) for package types, data layer models, and package tooling commands.

## Universal Development Guidelines

- **Modular Separation**: Add app features in `app/lib/feature/`. Add shared logic, utilities, or data models to the appropriate package under `packages/`.
- **Dart Version & Syntax**:
  - Do not arbitrarily downgrade the Dart SDK version.
  - **Primary Constructors**: Prioritize using Dart 3.13.0's **Primary Constructors** syntax to reduce boilerplate. Combine field declarations, parameter declarations, and initialization directly in the class header (e.g., `class User(final String name, final int age);`).
  - Use the empty body semicolon shorthand (`class C(int x);`) when the body is empty.
  - Use abbreviated concise constructor syntax (e.g., `new() {}` or `const new();`) for in-body constructors when applicable.
