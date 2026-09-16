## 2026-09-15 - Interactive Action Button Semantics & Screen Reader Accessibility

**Learning:** Custom interactive action buttons and inline like buttons that rely on `InkWell` or custom gestures lack implicit accessibility traits, preventing screen readers (TalkBack/VoiceOver) from announcing selection state (`selected`), button behavior (`button: true`), or contextual tooltips.

**Action:** Always wrap custom `InkWell` action widgets with explicit `Semantics(button: true, selected: ..., label: ..., tooltip: ...)` to ensure clear screen reader guidance and tactile accessibility across mobile platforms.
