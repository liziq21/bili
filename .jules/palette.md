## 2026-09-15 - Interactive Action Button Semantics & Screen Reader Accessibility

**Learning:** Custom interactive action buttons and inline like buttons that rely on `InkWell` or custom gestures lack implicit accessibility traits, preventing screen readers (TalkBack/VoiceOver) from announcing selection state (`selected`), button behavior (`button: true`), or contextual tooltips.

**Action:** Always wrap custom `InkWell` action widgets with explicit `Semantics(button: true, selected: ..., label: ..., tooltip: ...)` to ensure clear screen reader guidance and tactile accessibility across mobile platforms.

## 2026-09-17 - Composite Interactive Card Semantics & ExcludeSemantics Pitfall

**Learning:** When wrapping composite feed cards with `Semantics(excludeSemantics: true)` to condense multiple text labels into a concise screen reader description, `excludeSemantics: true` suppresses nested interactive buttons (such as "More Options" `IconButton`). Removing `excludeSemantics: true` or applying `Semantics` to child content regions while keeping independent action buttons as unexcluded siblings preserves both card accessibility summary and individual button accessibility.

**Action:** Avoid applying `excludeSemantics: true` at a parent card level if child widgets contain nested secondary actions (`IconButton`), ensuring secondary actions remain accessible to screen readers.

## 2026-09-24 - Collapsible Text Section Semantics & Smooth Size Animations

**Learning:** Replacing abrupt text maxLines toggles with `AnimatedSize` combined with `Semantics(button: true, expanded: ...)` on the toggle button creates a polished micro-interaction that provides both visual smoothness and essential screen reader state updates (`expanded: true/false`).

**Action:** Always pair `AnimatedSize` layout transitions with explicit `Semantics(button: true, expanded: ...)` and `HapticFeedback.lightImpact()` when building expandable text or summary sections.

## 2026-09-25 - Navigation Filter Chips Tactile Feedback & Tooltip Accessibility

**Learning:** Navigation `FilterChip` elements in horizontal filter bars provide visual tab selection, but lacking tactile `HapticFeedback.selectionClick()` and explicit `tooltip` attributes reduces physical responsiveness on touch screens and leaves desktop/screen-reader users without context on long-press or hover.

**Action:** Always combine `HapticFeedback.selectionClick()` with `tooltip: filter.label` on filter chip selection handlers to ensure clear tactile feedback and accessibility.

## 2026-09-25 - Action Button Metric Semantics & Dynamic Action Context

**Learning:** When custom action buttons display numeric stats (e.g. view/like/favorite counts like "3.8万"), passing only the formatted number string to `Semantics(label: ..., tooltip: ...)` leaves screen readers (TalkBack/VoiceOver) without action context (announcing "3.8万, button" instead of "点赞 3.8万, button"), and causes hover tooltips to show useless metric numbers instead of action hints.

**Action:** Always combine explicit action names with formatted metric counts in `Semantics(label: '$actionName $count')` and supply state-aware dynamic tooltips (e.g., `isLiked ? '取消点赞' : '点赞'`).
