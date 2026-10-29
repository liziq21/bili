#!/usr/bin/env python3
"""Check coverage thresholds against lcov.info.

Parses lcov.info, computes line and branch coverage percentages,
and exits with non-zero if below thresholds.

Generated files (*.g.dart, *.freezed.dart, l10n output) are excluded
from the denominator — they are not hand-written testable code.

Usage:
    python3 tool/check_coverage.py <lcov.info> [--min-lines 60] [--min-branches 50]
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Files that are not hand-written testable code.
_EXCLUDE_SUFFIXES = ('.g.dart', '.freezed.dart')
_EXCLUDE_DIRS = ('lib/l10n/localization_file/', '.dart_tool/', 'build/')


def _should_exclude(source: str) -> bool:
    if any(source.endswith(s) for s in _EXCLUDE_SUFFIXES):
        return True
    if any(source.startswith(d) for d in _EXCLUDE_DIRS):
        return True
    return False


def _parse_lcov(path: Path):
    """Parse lcov.info; return (lf, lh, brf, brh, file_count, has_branch)."""
    lf_total = lh_total = brf_total = brh_total = 0
    file_count = 0
    has_branch = False

    sf = None
    lf = lh = brf = brh = 0

    with path.open() as f:
        for raw in f:
            line = raw.strip()
            if line.startswith('SF:'):
                sf = line[3:]
                lf = lh = brf = brh = 0
            elif line.startswith('LF:'):
                lf = int(line[3:])
            elif line.startswith('LH:'):
                lh = int(line[3:])
            elif line.startswith('BRF:'):
                brf = int(line[4:])
                has_branch = True
            elif line.startswith('BRH:'):
                brh = int(line[4:])
            elif line == 'end_of_record':
                if sf and not _should_exclude(sf):
                    lf_total += lf
                    lh_total += lh
                    brf_total += brf
                    brh_total += brh
                    file_count += 1
                sf = None

    return lf_total, lh_total, brf_total, brh_total, file_count, has_branch


def main() -> int:
    parser = argparse.ArgumentParser(description='Check coverage thresholds.')
    parser.add_argument('lcov_file', type=Path, help='Path to lcov.info')
    parser.add_argument('--min-lines', type=float,
                        default=float(os.environ.get('MIN_LINES', 60.0)),
                        help='Min line coverage %% (default: 60 or $MIN_LINES)')
    parser.add_argument('--min-branches', type=float,
                        default=float(os.environ.get('MIN_BRANCHES', 50.0)),
                        help='Min branch coverage %% (default: 50 or $MIN_BRANCHES)')
    args = parser.parse_args()

    if not args.lcov_file.exists():
        print(f'ERROR: lcov file not found: {args.lcov_file}', file=sys.stderr)
        return 2

    lf, lh, brf, brh, files, has_branch = _parse_lcov(args.lcov_file)

    if lf == 0:
        print('ERROR: No line coverage data (all files excluded or empty).',
              file=sys.stderr)
        return 2

    line_pct = (lh / lf) * 100
    branch_pct = (brh / brf) * 100 if (has_branch and brf > 0) else 100.0

    print('Coverage Report')
    print('===============')
    print(f'  Files:    {files}')
    print(f'  Lines:    {lh}/{lf} ({line_pct:.1f}%)')
    if has_branch:
        print(f'  Branches: {brh}/{brf} ({branch_pct:.1f}%)')
    else:
        print('  Branches: N/A (--branch-coverage not used)')
    print()
    print(f'Thresholds: lines >= {args.min_lines:.1f}%, '
          f'branches >= {args.min_branches:.1f}%')

    line_ok = line_pct >= args.min_lines
    branch_ok = (not has_branch) or branch_pct >= args.min_branches

    print(f'  Line:     {"PASS" if line_ok else "FAIL"} ({line_pct:.1f}%)')
    if has_branch:
        print(f'  Branch:   {"PASS" if branch_ok else "FAIL"} ({branch_pct:.1f}%)')

    if not line_ok or not branch_ok:
        print()
        print('FAIL: Coverage below threshold.')
        return 1
    print()
    print('PASS: All thresholds met.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
