# Bolt's Performance Journal

This journal stores CRITICAL codebase-specific learnings, performance pitfalls, and rendering discoveries.

## 2026-09-15 - Reject RepaintBoundary on simple list items
**Learning:** Adding `RepaintBoundary` to simple `_CommentItem` list widgets in `ListView.separated` over-allocates compositing layers, ballooning GPU memory footprint without providing measurable paint time improvements.
**Action:** Profile actual render layers in DevTools before introducing `RepaintBoundary`, and avoid wrapping lightweight static/semi-static list items in dedicated paint boundaries.

## 2026-09-17 - Avoid LayoutBuilder inside list/grid item widgets
**Learning:** Wrapping item widgets (like `VideoCard`) in an unused `LayoutBuilder` defers child widget construction to Flutter's layout phase during list/grid scroll rendering, adding unnecessary layout callbacks and delay. Additionally, unbounded `CachedNetworkImage` thumbnail decodes consume excessive GPU RAM on scroll.
**Action:** Ensure item widgets in grids/lists build directly without superfluous `LayoutBuilder` wrappers, and specify `memCacheWidth` on `CachedNetworkImage` to bound thumbnail memory footprint.

## 2026-09-18 - Isolate BLoC state rebuilding above TabControllers
**Learning:** Wrapping a screen's root layout in a broad `BlocBuilder` re-instantiates descendant `DefaultTabController`, `TabBar`, and `TabBarView` subtrees on every BLoC state change (e.g., like/favorite toggles), resetting tab states and causing unnecessary rebuild passes across the screen.
**Action:** Use targeted `BlocSelector` (or `context.select`) scoped tightly to only the widgets consuming specific state fields, keeping `DefaultTabController` and lower tab content outside reactive rebuild boundaries.

## 2026-09-20 - Cap image decode size on small avatars using ResizeImage.resizeIfNeeded
**Learning:** Displaying network avatar images inside small `CircleAvatar` widgets (36x36px to 40x40px) without bounding target decode dimensions causes Flutter's image pipeline to decode uncompressed high-resolution (1080p/4K) network bitmaps into GPU memory (~4MB–16MB per avatar), leading to memory bloat and raster thread decode jank when scrolling lists.
**Action:** Always wrap network `ImageProvider`s for small avatar icons with `ResizeImage.resizeIfNeeded(128, 128, provider)`, limiting decoded bitmap size to ~64KB per avatar while preserving high-DPI display quality.

## 2026-09-21 - Decompose monolithic detail view BlocBuilders into fine-grained selectors
**Learning:** Wrapping complex screen subviews (like `VideoInfoView`) in a single root `BlocBuilder<VideoBloc, VideoState>` causes every user action (e.g. toggling like or favorite) to force rebuild passes across the entire view, including static video metadata, creator profile info, expandable synopsis, and recommended video lists.
**Action:** Split monolithic screen widgets into scoped sub-components (`_VideoHeaderSection`, `_CreatorProfileSection`, `_ActionButtonsSection`, `_SynopsisSection`), each consuming only their specific fields via `context.select` or `BlocSelector` to restrict rebuild passes strictly to the interacted elements.

## 2026-10-06 - Avoid tearing off static methods for indicator builders in cold paths
**Learning:** Tearing off static methods for error/empty state indicator builders in `PagedChildBuilderDelegate` provides no measurable performance or memory benefit during normal list rendering/scrolling, as those builders represent cold paths and static tear-offs in Dart build methods still create closure instances.
**Action:** Do not micro-optimize cold error/empty indicators or introduce tear-offs unless a profile-mode trace confirms a real rendering or allocation bottleneck.
