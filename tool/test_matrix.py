#!/usr/bin/env python3
"""Test classification matrix for the bili repo.

Maps every ``*_test.dart`` file to one of six categories and powers the
workflows around it:

  --check                  Fail if any discovered test file is unclassified
                           or any mapping entry points at a missing file.
  --report [PATH]          Write the human-readable matrix document
                           (default: app/test/TEST_MATRIX.md).
  --files CATEGORY --area A --rel BASE
                           Print the file list for one category/area with
                           paths relative to BASE (used by CI to split test
                           runs per category).
  --summary MATRIX_DIR     Aggregate the per-category lcov + JSON reporter
                           outputs produced by the CI matrix job into a
                           summary table and summary.md.

Categories describe what the test actually does, not where it lives:

  unit         pure Dart logic driven by test(), no widget pumping
  widget       testWidgets/WidgetTester, no golden assertions
  golden       alchemist goldenTest() scenarios asserting pixels
  contract     guardrails: structural constraints across the codebase
               (hardcoded copy, font subset, design tokens, fixture
               mapping tables, routing table integrity)
  integration  cross-layer composition (app bootstrap, full-shell smoke)
  performance  frame-time/benchmark suites (currently none)

Usage:
    python3 tool/test_matrix.py --check
    python3 tool/test_matrix.py --report
    python3 tool/test_matrix.py --files unit --area app --rel app
    python3 tool/test_matrix.py --summary test-matrix
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CATEGORIES = ['unit', 'widget', 'golden', 'contract', 'integration',
              'performance']

# Repo-relative test file paths, grouped by category. Single source of
# truth: TEST_MATRIX.md and the CI per-category file lists are generated
# from this mapping.
TEST_MATRIX = {
    'contract': [
        'app/test/golden/golden_font_contract_test.dart',
        'app/test/golden/hardcoded_copy_test.dart',
        'app/test/design/app_style_test.dart',
        'app/test/design/contrast_test.dart',
        'app/test/design/hardcoded_color_test.dart',
        'app/test/design/palette_test.dart',
        'app/test/design/theme_wrapper_test.dart',
        'app/test/design/token_wiring_test.dart',
        'app/test/routing/router_security_test.dart',
        'app/test/routing/router_structure_test.dart',
        'packages/bilibili/bpi/test/doc_guardrail_test.dart',
        'packages/youtube/ypi/test/doc_guardrail_test.dart',
    ],
    'golden': [
        'app/test/golden/creator_profile_item_golden_test.dart',
        'app/test/golden/dark_theme_golden_test.dart',
        'app/test/golden/filter_bar_golden_test.dart',
        'app/test/golden/home_screen_golden_test.dart',
        'app/test/golden/not_found_screen_golden_test.dart',
        'app/test/golden/video_card_golden_test.dart',
        'app/test/golden/video_feed_section_golden_test.dart',
        'app/test/golden/video_info_view_golden_test.dart',
    ],
    'integration': [
        'app/test/main_test.dart',
        'app/test/widget_test.dart',
    ],
    'widget': [
        'app/test/feature/app_search_anchor_test.dart',
        'app/test/feature/filter_bar_test.dart',
        'app/test/feature/history_settings_screen_test.dart',
        'app/test/feature/home/feed_status_view_test.dart',
        'app/test/feature/home/home_config_editor_screen_test.dart',
        'app/test/feature/home/live_feed_section_test.dart',
        'app/test/feature/home_bloc_test.dart',
        'app/test/feature/home_filter_bar_test.dart',
        'app/test/feature/home_source_selector_test.dart',
        'app/test/feature/live/live_screen_test.dart',
        'app/test/feature/media_library/local_library_screen_test.dart',
        'app/test/feature/media_library/media_library_screen_test.dart',
        'app/test/feature/media_library/playlist_picker_test.dart',
        'app/test/feature/not_found_screen_test.dart',
        'app/test/feature/player_settings_screen_test.dart',
        'app/test/feature/search/search_result_screen_test.dart',
        'app/test/feature/search_result_test.dart',
        'app/test/feature/search_screen_test.dart',
        'app/test/feature/setting_screen_test.dart',
        'app/test/feature/space/space_screen_test.dart',
        'app/test/feature/video/playback_speed_chip_test.dart',
        'app/test/feature/video/player_gesture_layer_test.dart',
        'app/test/feature/video/player_keyboard_shortcuts_test.dart',
        'app/test/feature/video/quality_picker_chip_test.dart',
        'app/test/feature/video/sleep_timer_chip_test.dart',
        'app/test/feature/video/video_info_view_chapters_test.dart',
        'app/test/feature/video/video_info_view_queue_test.dart',
        'app/test/feature/video/video_player_placeholder_test.dart',
        'app/test/feature/video/video_player_test.dart',
        'app/test/feature/video/video_screen_test.dart',
        'app/test/feature/video_comments_view_test.dart',
        'app/test/feature/video_error_masking_test.dart',
        'app/test/feature/video_info_view_test.dart',
        'app/test/providers/bloc_providers_test.dart',
        'app/test/providers/repo_providers_test.dart',
        'app/test/providers/service_source_providers_test.dart',
        'app/test/routing/route_data_build_test.dart',
        'app/test/routing/router_resolve_source_test.dart',
        'app/test/routing/router_search_focus_test.dart',
        'app/test/routing/router_settings_test.dart',
        'app/test/ui/app_navigation_shell_test.dart',
        'app/test/ui/app_scroll_behavior_test.dart',
        'app/test/ui/creator_profile_item_test.dart',
        'app/test/ui/video_card_test.dart',
        'packages/bilibili/test/widget_test.dart',
    ],
    'unit': [
        'app/test/data/local_library_repository_test.dart',
        'app/test/data/repository/creator_profile_repository_test.dart',
        'app/test/data/repository/video_comment_repository_test.dart',
        'app/test/data/repository/video_detail_repository_test.dart',
        'app/test/database/app_database_test.dart',
        'app/test/database/local_library_dao_test.dart',
        'app/test/database/local_media_key_test.dart',
        'app/test/database/local_playlist_dao_test.dart',
        'app/test/database/local_playlist_migration_test.dart',
        'app/test/datastore/media_history_settings_test.dart',
        'app/test/datastore/preferences_data_source_test.dart',
        'app/test/domain/get_recent_search_queries_use_case_test.dart',
        'app/test/domain/get_search_contents_use_case_test.dart',
        'app/test/feature/home/home_config_test.dart',
        'app/test/feature/media_library/media_history_cubit_test.dart',
        'app/test/feature/search_state_test.dart',
        'app/test/feature/video/media_stream_bloc_test.dart',
        'app/test/feature/video/player/media_edl_test.dart',
        'app/test/feature/video/player/media_playback_controller_test.dart',
        'app/test/feature/video/player/playback_error_test.dart',
        'app/test/feature/video/probe_test.dart',
        'app/test/feature/video_bloc_test.dart',
        'app/test/layout_breakpoints_test.dart',
        'app/test/providers/media_sources_provider_test.dart',
        'app/test/utils/command_test.dart',
        'app/test/utils/platform_info_test.dart',
        'packages/bilibili/bpi/test/api_interceptor_test.dart',
        'packages/bilibili/bpi/test/api_result_test.dart',
        'packages/bilibili/bpi/test/bangumi_play_url_test.dart',
        'packages/bilibili/bpi/test/bangumi_season_test.dart',
        'packages/bilibili/bpi/test/danmaku_test.dart',
        'packages/bilibili/bpi/test/danmaku_ws/danmaku_message_test.dart',
        'packages/bilibili/bpi/test/danmaku_ws/packet_test.dart',
        'packages/bilibili/bpi/test/from_json_test.dart',
        'packages/bilibili/bpi/test/live_danmaku_test.dart',
        'packages/bilibili/bpi/test/live_room_detail_test.dart',
        'packages/bilibili/bpi/test/live_room_play_info_test.dart',
        'packages/bilibili/bpi/test/player_v2_test.dart',
        'packages/bilibili/bpi/test/popular_feed_test.dart',
        'packages/bilibili/bpi/test/ranking_feed_test.dart',
        'packages/bilibili/bpi/test/reply_pagination_test.dart',
        'packages/bilibili/bpi/test/token_manager_test.dart',
        'packages/bilibili/bpi/test/user_articles_test.dart',
        'packages/bilibili/bpi/test/user_card_test.dart',
        'packages/bilibili/bpi/test/video_data_models_test.dart',
        'packages/bilibili/bpi/test/wbi_utils_test.dart',
        'packages/bilibili/test/bili_live_danmaku_remote_data_source_test.dart',
        'packages/bilibili/test/bili_media_stream_test.dart',
        'packages/bilibili/test/bili_popular_feed_test.dart',
        'packages/bilibili/test/bili_search_remote_data_sources_test.dart',
        'packages/bilibili/test/bili_search_suggest_remote_data_source_test.dart',
        'packages/bilibili/test/bili_url_normalization_test.dart',
        'packages/bilibili/test/bili_video_data_sources_test.dart',
        'packages/bilibili/test/l10n_test.dart',
        'packages/bilibili/test/network/model/network_search_result_test.dart',
        'packages/bilibili/test/network/model/network_search_suggest_test.dart',
        'packages/data/test/danmaku_test.dart',
        'packages/data/test/full_playlist_fetcher_test.dart',
        'packages/data/test/remote_data_source_test.dart',
        'packages/youtube/test/youtube_test.dart',
        'packages/youtube/ypi/test/from_json_test.dart',
        'packages/youtube/ypi/test/youtube_service_test.dart',
        'packages/youtube/ypi/test/yt_protobuf_encoder_test.dart',
    ],
    'performance': [],
}

# CI area name -> path prefix it owns. Used by --files --area and by the
# summary mode to group per-area outputs.
AREA_PREFIXES = {
    'app': 'app/test/',
    'bpi': 'packages/bilibili/bpi/',
    'bilibili': 'packages/bilibili/',
    'data': 'packages/data/',
    'youtube': 'packages/youtube/',
    'ypi': 'packages/youtube/ypi/',
}


def discover_test_files(root: Path):
    """Find every *_test.dart under app/test and packages/*/test."""
    files = []
    for base in (root / 'app' / 'test', root / 'packages'):
        if not base.exists():
            continue
        for path in base.rglob('*_test.dart'):
            if any(part in ('build', '.dart_tool') for part in path.parts):
                continue
            files.append(path.relative_to(root).as_posix())
    return sorted(files)


def area_of(path: str) -> str:
    """Area name owning a repo-relative test path."""
    # Longest matching prefix wins (bpi before bilibili, ypi before youtube).
    for area, prefix in sorted(AREA_PREFIXES.items(),
                               key=lambda kv: -len(kv[1])):
        if path.startswith(prefix):
            return area
    return 'unknown'


def check_mapping(root: Path) -> int:
    """Verify the mapping covers exactly the discovered test files."""
    discovered = set(discover_test_files(root))
    mapped = {path for paths in TEST_MATRIX.values() for path in paths}

    problems = []
    for path in sorted(discovered - mapped):
        problems.append(f'  unclassified: {path}')
    for path in sorted(mapped - discovered):
        problems.append(f'  stale entry (file missing): {path}')

    counts = {c: len(TEST_MATRIX[c]) for c in CATEGORIES}
    print('Test matrix check')
    print('=================')
    print(f'  Discovered: {len(discovered)}')
    print(f'  Mapped:     {len(mapped)}')
    for category in CATEGORIES:
        print(f'  {category:<13} {counts[category]}')
    print()

    if problems:
        print('FAIL: mapping does not match the test tree:')
        problems.append('')
        for problem in problems:
            print(problem)
        return 1
    print('PASS: every test file is classified exactly once.')
    return 0


def render_report() -> str:
    """Render the human-readable matrix document."""
    lines = [
        '# 测试分类矩阵',
        '',
        '每个 `*_test.dart` 按其**实际行为**（而非目录）归入六类。',
        '本文件由 `tool/test_matrix.py --report` 生成，勿手改；',
        '改分类请改脚本内的 `TEST_MATRIX` 映射后重新生成。',
        '',
        '| 分类 | 文件数 |',
        '|------|--------|',
    ]
    total = 0
    for category in CATEGORIES:
        files = TEST_MATRIX[category]
        total += len(files)
        lines.append(f'| {category} | {len(files)} |')
    lines.append(f'| **合计** | **{total}** |')
    lines.append('')
    lines.append('## 分类定义')
    lines.append('')
    lines.append('- **unit**：纯 Dart 逻辑，`test()` 驱动，不 pump widget')
    lines.append('- **widget**：`testWidgets` + `WidgetTester`，无 golden 断言')
    lines.append('- **golden**：alchemist `goldenTest()` 场景，断言像素基线')
    lines.append('- **contract**：护栏/契约类——硬编码文案、字体子集、设计令牌、')
    lines.append('  fixture 映射表、路由表结构等跨文件结构约束')
    lines.append('- **integration**：跨层组合（app 启动接线、全壳冒烟）')
    lines.append('- **performance**：帧率/耗时基准（当前无文件）')
    lines.append('')
    for category in CATEGORIES:
        files = TEST_MATRIX[category]
        lines.append(f'## {category}（{len(files)}）')
        lines.append('')
        if not files:
            lines.append('当前无文件。新增性能基准测试后在此登记。')
            lines.append('')
            continue
        for path in files:
            lines.append(f'- `{path}`')
        lines.append('')
    return '\n'.join(lines)


def write_report(root: Path, path: Path) -> int:
    content = render_report()
    if path.read_text() if path.exists() else '' != content:
        path.write_text(content)
    print(f'Wrote {path}')
    return 0


def print_files(category: str, area: str, rel: Path | None) -> int:
    if category not in TEST_MATRIX:
        print(f'ERROR: unknown category: {category}', file=sys.stderr)
        return 2
    paths = [p for p in TEST_MATRIX[category] if area_of(p) == area]
    for path in paths:
        if rel is not None:
            path = Path(path)
            print(path.relative_to(rel).as_posix())
        else:
            print(path)
    return 0


def parse_lcov_totals(path: Path):
    """Parse one lcov file; return accumulated (lf, lh, brf, brh)."""
    total_lf = total_lh = total_brf = total_brh = 0
    lf = lh = brf = brh = 0
    with path.open() as f:
        for raw in f:
            line = raw.strip()
            if line.startswith('SF:'):
                lf = lh = brf = brh = 0
            elif line.startswith('LF:'):
                lf = int(line[3:])
            elif line.startswith('LH:'):
                lh = int(line[3:])
            elif line.startswith('BRF:'):
                brf = int(line[4:])
            elif line.startswith('BRH:'):
                brh = int(line[4:])
            elif line == 'end_of_record':
                total_lf += lf
                total_lh += lh
                total_brf += brf
                total_brh += brh
    return total_lf, total_lh, total_brf, total_brh


def parse_reporter_json(path: Path):
    """Parse a dart test JSON reporter output.

    Returns (files, passed): the number of file-level suites (test files)
    and how many had no failing test. A suite fails if any of its tests
    reports failure/error via testDone, or an ErrorEvent marks it failed.

    Handles both protocol generations for the suite event shape:
    the current one (``suite: {id, platform, path}``) and the legacy one
    (``suite: {id, root, name, platform}``). The testStart -> suiteID map
    and the testDone/error events are identical across both.
    """
    suite_paths: dict[int, str] = {}
    test_suite: dict[int, int] = {}
    failed_suites: set[int] = set()
    files = 0
    with path.open() as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                event = json.loads(raw)
            except json.JSONDecodeError:
                continue
            kind = event.get('type')
            if kind == 'suite':
                suite = event.get('suite') or {}
                sid = suite.get('id')
                if sid is None:
                    continue
                if suite.get('root') is False:
                    # Legacy protocol: non-root suites are loading virtuals.
                    continue
                name = suite.get('path') or suite.get('name')
                if name:
                    suite_paths[sid] = name
                    files += 1
            elif kind == 'testStart':
                test = event.get('test') or {}
                if test.get('id') is not None and test.get('suiteID') is not None:
                    test_suite[test['id']] = test['suiteID']
            elif kind == 'testDone':
                sid = test_suite.get(event.get('testID'))
                if sid is not None and event.get('result') in (
                        'failure', 'error'):
                    failed_suites.add(sid)
            elif kind == 'error':
                sid = test_suite.get(event.get('testID'))
                if sid is not None and event.get('isFailure'):
                    failed_suites.add(sid)
    if files == 0:
        print(f'WARN: no file-level suites parsed from {path}', file=sys.stderr)
    passed = sum(1 for sid in suite_paths if sid not in failed_suites)
    return files, passed


def summary(matrix_dir: Path) -> int:
    """Aggregate per-category lcov + reporter outputs into a summary."""
    lcov_files = sorted(matrix_dir.glob('*.lcov'))
    if not lcov_files:
        print(f'ERROR: no .lcov files in {matrix_dir}', file=sys.stderr)
        return 2
    missing = [
        c for c in CATEGORIES
        if TEST_MATRIX[c] and not any(matrix_dir.glob(f'*-{c}.lcov'))
    ]
    if missing:
        print(f'ERROR: categories with files but no lcov output: '
              f'{", ".join(missing)}', file=sys.stderr)
        return 2
    # category -> [(area, files, passed, lf, lh, brf, brh), ...]
    per_category: dict[str, list] = {c: [] for c in CATEGORIES}
    for lcov_path in lcov_files:
        stem = lcov_path.stem  # e.g. app-widget
        area, _, category = stem.partition('-')
        if category not in per_category:
            print(f'WARN: unknown category in {lcov_path.name}', file=sys.stderr)
            continue
        json_path = matrix_dir / f'{stem}.json'
        files = passed = 0
        if json_path.exists():
            files, passed = parse_reporter_json(json_path)
        lf, lh, brf, brh = parse_lcov_totals(lcov_path)
        per_category[category].append(
            (area, files, passed, lf, lh, brf, brh))

    lines = [
        '# 测试分类报告',
        '',
        '由 CI 的 `test_matrix_report` job 生成（`tool/test_matrix.py --summary`）。',
        '',
        '| 分类 | 文件数 | 通过 | 覆盖率（行） | 覆盖率（分支） |',
        '|------|--------|------|--------------|----------------|',
    ]
    total_files = total_passed = total_lf = total_lh = 0
    total_brf = total_brh = 0
    for category in CATEGORIES:
        rows = per_category[category]
        files = sum(r[1] for r in rows)
        passed = sum(r[2] for r in rows)
        lf = sum(r[3] for r in rows)
        lh = sum(r[4] for r in rows)
        brf = sum(r[5] for r in rows)
        brh = sum(r[6] for r in rows)
        if files or lf or brf:
            line_pct = f'{lh / lf * 100:.1f}%' if lf else 'N/A'
            branch_pct = f'{brh / brf * 100:.1f}%' if brf else 'N/A'
            pass_rate = f'{passed}/{files}' if files else '-'
            lines.append(
                f'| {category} | {files} | {pass_rate} '
                f'| {line_pct} | {branch_pct} |')
        else:
            lines.append(f'| {category} | 0 | - | - | - |')
        total_files += files
        total_passed += passed
        total_lf += lf
        total_lh += lh
        total_brf += brf
        total_brh += brh

    line_pct = f'{total_lh / total_lf * 100:.1f}%' if total_lf else 'N/A'
    branch_pct = (f'{total_brh / total_brf * 100:.1f}%'
                  if total_brf else 'N/A')
    lines.append(
        f'| **合计** | **{total_files}** | **{total_passed}/{total_files}** '
        f'| **{line_pct}** | **{branch_pct}** |')
    lines.append('')

    text = '\n'.join(lines)
    print(text)
    (matrix_dir / 'summary.md').write_text(text)
    print(f'\nWrote {matrix_dir / "summary.md"}')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true',
                        help='verify the mapping covers all test files')
    parser.add_argument('--report', nargs='?', const='__default__',
                        help='write the matrix document '
                             '(default: app/test/TEST_MATRIX.md)')
    parser.add_argument('--files', metavar='CATEGORY',
                        help='print files of one category')
    parser.add_argument('--area', default='app',
                        help='area filter for --files (default: app)')
    parser.add_argument('--rel', metavar='BASE',
                        help='print paths relative to BASE for --files')
    parser.add_argument('--summary', metavar='DIR',
                        help='aggregate CI matrix outputs in DIR')
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent

    if args.check:
        return check_mapping(root)
    if args.report is not None:
        path = (root / 'app/test/TEST_MATRIX.md'
                if args.report == '__default__' else Path(args.report))
        return write_report(root, path)
    if args.files:
        rel = Path(args.rel) if args.rel else None
        return print_files(args.files, args.area, rel)
    if args.summary:
        return summary(Path(args.summary))
    parser.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
