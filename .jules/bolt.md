# Bolt's Performance Journal

This journal stores CRITICAL codebase-specific learnings, performance pitfalls, and rendering discoveries.

## 2026-09-15 - Reject RepaintBoundary on simple list items
**Learning:** Adding `RepaintBoundary` to simple `_CommentItem` list widgets in `ListView.separated` over-allocates compositing layers, ballooning GPU memory footprint without providing measurable paint time improvements.
**Action:** Profile actual render layers in DevTools before introducing `RepaintBoundary`, and avoid wrapping lightweight static/semi-static list items in dedicated paint boundaries.
