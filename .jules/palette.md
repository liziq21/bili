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

## 2026-09-28 - Creator Subscription Button Semantics & State Tooltips

**Learning:** Standard `ElevatedButton.icon` widgets used for toggle actions (like "关注/已关注") lack state-aware `tooltip` hints and explicit `Semantics(selected: ...)` attributes by default, leaving screen readers and hover users without context on the creator target name or un-subscribe action.

**Action:** Always wrap toggle `ElevatedButton` components with explicit `Tooltip(message: isSubscribed ? '取消关注创作者' : '关注创作者')` and `Semantics(button: true, selected: isSubscribed, label: ...)` alongside `HapticFeedback.lightImpact()` on tap.

## 2026-10-01 - Search Result Empty State & Font Subset Contract

**Learning:** When adding empty state copy or localized text in Flutter widgets, all Chinese string literals must strictly exist in `test/fonts/subset-characters.txt` to pass `golden_font_contract_test.dart`. Combining empty state icons (`Icons.search_off_rounded`) with supported Chinese text (`未找到内容`) prevents rendering tofu in golden tests while delivering clear visual empty state feedback.

**Action:** Before introducing new Chinese UI text, check `test/fonts/subset-characters.txt` to ensure all characters are present in the test font subset.

## 2026-10-01 - Live Room Feed Card Semantics & Tactile Feedback

**Learning:** Live room feed cards (`_LiveRoomCard`) that wrap `InkWell` directly without `Semantics` or `Tooltip` leave screen readers to announce unformatted child text fragments without button roles, while taps lack physical feedback. Wrapping card content in `Tooltip` and `Semantics(button: true, label: semanticLabel)` with `ExcludeSemantics` on inner layout produces clean screen reader announcements and provides desktop hover hints, while `HapticFeedback.lightImpact()` on tap matches video feed card feedback.

**Action:** Combine `Tooltip`, `Semantics(button: true, label: ...)` with `ExcludeSemantics` on inner layout, and `HapticFeedback.lightImpact()` on tap when building custom feed item cards.
