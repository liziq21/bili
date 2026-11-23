#!/usr/bin/env python3
"""Fail when an ARB file defines the same key twice.

`json.load` and `flutter gen-l10n` both keep the last duplicate silently, so a
repeated key looks like a working translation while the earlier value and its
`@key` description are dropped. Translation platforms disagree on which copy
wins, which makes the duplicate a latent source of bad round-trips.

The check walks the whole document, not just the top level: JSON allows
duplicate members in any object, and nested placeholders are no different.

Usage:
  python3 tool/check_arb_duplicate_keys.py            # check the app ARB files
  python3 tool/check_arb_duplicate_keys.py path.arb   # check specific files
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Iterator
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ARB_FILES = (
    REPO_ROOT / 'app/lib/l10n/app_.arb',
    REPO_ROOT / 'app/lib/l10n/app_zh.arb',
)


class _Members(list):
    """Ordered key/value pairs, so duplicate members survive parsing."""


def _parse_pairs(text: str) -> object:
    return json.loads(text, object_pairs_hook=_Members)


def find_duplicates(data: object, path: tuple[str, ...] = ()) -> Iterator[tuple[tuple[str, ...], str]]:
    """Yield ``(path, key)`` for every repeated key in ``data``."""
    if not isinstance(data, _Members):
        return
    seen: set[str] = set()
    for key, value in data:
        if key in seen:
            yield path, key
        else:
            seen.add(key)
        yield from find_duplicates(value, (*path, key))


def check_file(path: Path) -> list[str]:
    duplicates = list(find_duplicates(_parse_pairs(path.read_text(encoding='utf-8'))))
    return [
        f'{path}: duplicate key {key!r} at {_format_path(where)}'
        for where, key in duplicates
    ]


def _format_path(where: tuple[str, ...]) -> str:
    return '.'.join(where) if where else '<top level>'


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'files',
        nargs='*',
        type=Path,
        help='ARB files to check (default: the app English and Chinese files)',
    )
    args = parser.parse_args(argv)
    files = args.files or list(DEFAULT_ARB_FILES)

    problems: list[str] = []
    for path in files:
        if not path.is_file():
            problems.append(f'{path}: file not found')
            continue
        problems.extend(check_file(path))

    if problems:
        for problem in problems:
            print(problem, file=sys.stderr)
        return 1
    print(f'No duplicate keys in {len(files)} ARB file(s).')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
