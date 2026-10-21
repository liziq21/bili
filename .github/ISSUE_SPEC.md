# GitHub Issue Label Specification (Project `bili`)

**Authoritative version:** this file in the repository.  
**Linear sync:** when Linear is connected, these labels are mirrored to Linear via bidirectional sync.  
**Do not edit in Linear** — changes made in Linear may be overwritten by the next sync from GitHub. Edit here, push to `main`, and let sync propagate.

---

## Label System Overview

This project uses a **two-dimensional label system** for issues (not PRs):

| Dimension | Prefix | Purpose | Color | Mutually exclusive within dimension? |
|---|---|---|---|---|
| **Category** (what kind of work) | `c:` | classifies the nature of the issue | `#e02000` | **Yes** — exactly one per issue |
| **Area** (which product area) | `a:` | identifies the codebase surface | `#55ddbb` | **Yes** — exactly one per issue |
| **Blocked** | `blocked` | issue cannot proceed without external input | `#000000` | No — orthogonal flag |

**Priority is NOT a label.** Priority is expressed via GitHub's native issue priority field (or Linear's native priority when synced). Do not create `P0`–`P3` labels — they create a second source of truth.

---

## Category Labels (`c:`)

| Label | Description | When to apply |
|---|---|---|
| `c:feature` | New user-visible capability or enhancement | Adds something users can see/use |
| `c:tech-debt` | Internal improvement with no user-visible change | Refactors, migrations, dependency updates, cleanup |
| `c:test-gap` | Missing or insufficient test coverage | New code without tests; flaky tests; uncovered branches |
| `c:infra` | Build, CI, release, tooling, or developer experience | Workflows, scripts, local dev setup, automation |
| `c:process` | Workflow, governance, or contribution process changes | Templates, review policies, branching rules, docs |
| `c:decision` | Records an architectural or design decision | ADR-style entries; no code change required |

---

## Area Labels (`a:`)

| Label | Description | Typical files / packages |
|---|---|---|
| `a:player` | Video/audio playback, controls, queue, quality selection | `app/lib/feature/video/`, `packages/bilibili/bpi/`, `packages/youtube/ypi/` media parsing |
| `a:library` | Offline cache, history, favorites, downloads, local media | `app/lib/feature/library/`, `packages/data/` local DB |
| `a:discovery` | Home feed, search, recommendations, channel browse | `app/lib/feature/home/`, `app/lib/feature/search/`, `packages/bilibili/bpi/` browse endpoints |
| `a:content` | Video detail, comments, danmaku, creator profiles | `app/lib/feature/video/detail/`, `app/lib/feature/comment/` |
| `a:settings` | App preferences, account, theme, playback settings | `app/lib/feature/settings/`, `packages/data/` preferences |

---

## Blocked Label

| Label | Description |
|---|---|
| `blocked` | Work cannot proceed because it awaits an external decision, dependency, or resource (e.g., design review, upstream API change, user sign-off). Remove when unblocked. |

---

## Special Labels (managed by automation — do not add/remove manually)

| Label | Source | Purpose |
|---|---|---|
| `jules` | Added by dispatch workflow when `@jules` is mentioned | Marks issues dispatched to Jules agent |
| `golden` | Added by golden baseline workflow | Marks PRs that update golden baselines |
| `ci-generated` | Added by changelog workflow | Marks auto-generated changelog PRs |

---

## Label Application Rules

1. **Every issue must have exactly one `c:` label and exactly one `a:` label** at creation (or triage).
2. **`blocked` is optional** — add when the issue hits a hard external dependency.
3. **Labels are applied via GitHub** (web UI, CLI, or API). Linear sync will mirror them.
4. **Do not create ad-hoc labels.** If a new category/area is needed, propose it here first (PR to this file), then add to GitHub.
5. **When an issue moves to `Done`/closed**, labels are preserved for history.

---

## Creating Labels in GitHub

If labels are missing in a fresh repository, create them via API:

```bash
# Category labels
gh label create "c:feature" --color e02000 --description "New user-visible capability or enhancement"
gh label create "c:tech-debt" --color e02000 --description "Internal improvement with no user-visible change"
gh label create "c:test-gap" --color e02000 --description "Missing or insufficient test coverage"
gh label create "c:infra" --color e02000 --description "Build, CI, release, tooling, or developer experience"
gh label create "c:process" --color e02000 --description "Workflow, governance, or contribution process changes"
gh label create "c:decision" --color e02000 --description "Records an architectural or design decision"

# Area labels
gh label create "a:player" --color 55ddbb --description "Video/audio playback, controls, queue, quality selection"
gh label create "a:library" --color 55ddbb --description "Offline cache, history, favorites, downloads, local media"
gh label create "a:discovery" --color 55ddbb --description "Home feed, search, recommendations, channel browse"
gh label create "a:content" --color 55ddbb --description "Video detail, comments, danmaku, creator profiles"
gh label create "a:settings" --color 55ddbb --description "App preferences, account, theme, playback settings"

# Blocked
gh label create "blocked" --color 000000 --description "Work blocked on external dependency or decision"
```

---

## Sync with Linear (when connected)

- GitHub → Linear: labels sync bidirectionally in real time (seconds).
- Linear → GitHub: labels added in Linear appear in GitHub within seconds.
- **Source of truth remains this file.** If drift occurs, re-apply from this spec.
- Linear's native priority field maps to GitHub's issue priority (no label needed).