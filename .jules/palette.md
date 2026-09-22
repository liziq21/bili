## 2026-09-15 - Interactive Action Button Semantics & Screen Reader Accessibility

**Learning:** Custom interactive action buttons and inline like buttons that rely on `InkWell` or custom gestures lack implicit accessibility traits, preventing screen readers (TalkBack/VoiceOver) from announcing selection state (`selected`), button behavior (`button: true`), or contextual tooltips.

**Action:** Always wrap custom `InkWell` action widgets with explicit `Semantics(button: true, selected: ..., label: ..., tooltip: ...)` to ensure clear screen reader guidance and tactile accessibility across mobile platforms.

## 2026-09-17 - Composite Interactive Card Semantics & ExcludeSemantics Pitfall

**Learning:** When wrapping composite feed cards with `Semantics(excludeSemantics: true)` to condense multiple text labels into a concise screen reader description, `excludeSemantics: true` suppresses nested interactive buttons (such as "More Options" `IconButton`). Removing `excludeSemantics: true` or applying `Semantics` to child content regions while keeping independent action buttons as unexcluded siblings preserves both card accessibility summary and individual button accessibility.

**Action:** Avoid applying `excludeSemantics: true` at a parent card level if child widgets contain nested secondary actions (`IconButton`), ensuring secondary actions remain accessible to screen readers.
