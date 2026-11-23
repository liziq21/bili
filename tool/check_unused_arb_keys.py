#!/usr/bin/env python3
"""Report ARB message keys that no Dart source references.

An unused key is not harmless: `flutter gen-l10n` emits one getter per key into
`AppLocalizations` and one value per locale into the generated delegates, so a
dead key costs generated code forever and makes the translation backlog
unreadable — a translator cannot tell "waiting for translation" from "no longer
used". This repository inherited roughly 980 such keys from an unrelated
upstream app, which is why the report exists as a script instead of a one-off
grep.

A key counts as referenced when its exact name appears as an identifier in a
Dart file under the scanned roots. Matching whole identifiers (not substrings)
means `clear` is not considered used by `queue.clear()`; matching is
deliberately conservative — a key whose name happens to collide with unrelated
code is reported as used, never as unused, so the tool can never recommend
deleting a key that something still reads.

Usage:
  python3 tool/check_unused_arb_keys.py            # report unused keys
  python3 tool/check_unused_arb_keys.py --check    # exit 1 if any are unused
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
APP_DIR = REPO_ROOT / 'app'
# The app's source ARBs. Package ARBs have their own code roots, so they are not
# in the default set; pass them with --arb/--root if they ever need the check.
DEFAULT_ARB_FILES = tuple(sorted((APP_DIR / 'lib' / 'l10n').glob('*.arb')))
DEFAULT_ROOTS = (APP_DIR / 'lib', APP_DIR / 'test')
# gen-l10n output: it declares every key as a getter, so scanning it would make
# every key look used.
GENERATED_DIR = 'localization_file'
IDENTIFIER = re.compile(r'[A-Za-z_$][A-Za-z0-9_$]*')


@dataclass(frozen=True)
class ArbReport:
    """Unused keys of a single ARB file."""

    path: Path
    message_keys: tuple[str, ...]
    unused: tuple[str, ...]


def message_keys(path: Path) -> list[str]:
    """Return the translatable keys of *path*, in file order.

    ARB metadata (`@@locale`, `@@last_modified`, `@key` descriptions) is not a
    message, so it never appears in the result.
    """
    data = json.loads(path.read_text(encoding='utf-8'))
    return [key for key in data if not key.startswith('@')]


def collect_identifiers(roots: tuple[Path, ...]) -> set[str]:
    """Return every identifier that appears in the Dart files under *roots*."""
    identifiers: set[str] = set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.rglob('*.dart'):
            if GENERATED_DIR in path.parts:
                continue
            identifiers.update(
                IDENTIFIER.findall(path.read_text(encoding='utf-8', errors='replace'))
            )
    return identifiers


def load_allowlist(path: Path) -> set[str]:
    """Return keys from *path* that a maintainer chose to keep.

    One key per line; `#` starts a comment, so the reason travels with the key.
    A missing file means an empty allowlist.
    """
    if not path.is_file():
        return set()
    allowed: set[str] = set()
    for line in path.read_text(encoding='utf-8').splitlines():
        entry = line.split('#', 1)[0].strip()
        if entry:
            allowed.add(entry)
    return allowed


def analyze(arb_files: tuple[Path, ...], roots: tuple[Path, ...]) -> list[ArbReport]:
    """Return one report per ARB file, each listing its unreferenced keys."""
    identifiers = collect_identifiers(roots)
    reports: list[ArbReport] = []
    for path in arb_files:
        keys = message_keys(path)
        reports.append(
            ArbReport(
                path=path,
                message_keys=tuple(keys),
                unused=tuple(key for key in keys if key not in identifiers),
            )
        )
    return reports


def unused_keys(reports: list[ArbReport]) -> list[str]:
    """Return the sorted union of unused keys across *reports*."""
    return sorted({key for report in reports for key in report.unused})


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        '--arb',
        nargs='+',
        type=Path,
        default=list(DEFAULT_ARB_FILES),
        help='ARB files to inspect (default: app/lib/l10n/*.arb)',
    )
    parser.add_argument(
        '--root',
        nargs='+',
        type=Path,
        default=list(DEFAULT_ROOTS),
        help='Dart source roots to scan (default: app/lib app/test)',
    )
    parser.add_argument(
        '--allowlist',
        type=Path,
        default=REPO_ROOT / 'tool' / 'unused_arb_keys_allowlist.txt',
        help='keys deliberately kept although unreferenced, one per line',
    )
    parser.add_argument(
        '--check',
        action='store_true',
        help='exit 1 when an unreferenced key is not allowlisted',
    )
    args = parser.parse_args(argv)

    missing = [path for path in args.arb if not path.is_file()]
    if missing:
        for path in missing:
            print(f'{path}: file not found', file=sys.stderr)
        return 1

    reports = analyze(tuple(args.arb), tuple(args.root))
    allowed = load_allowlist(args.allowlist)
    for report in reports:
        offenders = [key for key in report.unused if key not in allowed]
        print(
            f'{report.path}: {len(report.unused)} of {len(report.message_keys)} '
            f'message keys unreferenced ({len(offenders)} without an allowlist entry)'
        )

    keys = unused_keys(reports)
    if not keys:
        print('Every message key is referenced.')
        return 0

    for key in keys:
        marker = ' (allowlisted)' if key in allowed else ''
        print(f'  unused: {key}{marker}')

    offenders = [key for key in keys if key not in allowed]
    if args.check and offenders:
        print(
            f'{len(offenders)} unreferenced key(s); delete them or record the '
            f'retention reason in {args.allowlist}',
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
