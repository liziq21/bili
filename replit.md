# bili Flutter

从 GitHub 导入的 bili Flutter 多包项目，应用源码位于 `bili/app`，共享 Dart/Flutter 包位于 `bili/packages`。

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string
- Flutter source: `bili/`
- Flutter app entry: `bili/app/lib/main.dart`
- Flutter workspace dependencies: run `flutter pub get` from `bili/` after installing Flutter 3.47 / Dart 3.13 or newer

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

- `bili/app` — Flutter application, routing, UI, database and tests
- `bili/packages` — shared `bilibili`, `components`, `data` and `model` packages
- `lib/api-spec/openapi.yaml` — API contract for the workspace template

## Architecture decisions

_Populate as you build — non-obvious choices a reader couldn't infer from the code (3-5 bullets)._

## Product

`bili` is the imported Flutter application. The current workspace keeps the upstream source intact so feature work can continue from the `main` branch snapshot.

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- The imported Flutter workspace requires Dart `^3.13.0` and Flutter `3.47.0`; do not lower these constraints just to accommodate an older local SDK.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
