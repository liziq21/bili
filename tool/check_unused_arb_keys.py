#!/usr/bin/env python3
"""Report ARB message keys that no Dart source references.

An unused key is not harmless: `flutter gen-l10n` emits one getter per key into
`AppLocalizations` and one value per locale into the generated delegates, so a
dead key costs generated code forever and makes the translation backlog
unreadable — a translator cannot tell "waiting for translation" from "no longer
used". This repository inherited roughly 980 such keys from an unrelated
upstream app, which is why the report exists as a script instead of a one-off
grep.

A key counts as referenced when its name appears as an identifier in the Dart
*code* under the scanned roots. Comments and string literal text are blanked
before matching, because a key is read by naming it (`l10n.key`) and a name
written down in prose or in a literal reads nothing. Matching whole identifiers
(not substrings) means `queue.clearAll()` does not keep the key `clear` alive.
What remains is deliberately conservative — a key whose name collides with
unrelated code is reported as referenced, never as unused — so the tool can
never recommend deleting a key that something still reads.

The default selection is every source ARB in the workspace (app plus packages)
and the scan roots are `app/lib`, `app/test` and `packages`, so a reference from
any layer keeps a key alive. `--check` also fails when the allowlist carries an
entry that is no longer unreferenced, because such an entry would silently
accept the key if it went unused again.

Usage:
  python3 tool/check_unused_arb_keys.py            # report unused keys
  python3 tool/check_unused_arb_keys.py --all      # every key with its status
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
# Every source ARB in the workspace: the app's plus each package's. A key that
# is unused in a package burns generated code just the same, and the scan roots
# are unified, so a reference anywhere in app/ or packages/ keeps a key alive.
DEFAULT_ARB_FILES = tuple(
    sorted(
        (
            *(APP_DIR / 'lib' / 'l10n').glob('*.arb'),
            *(REPO_ROOT / 'packages').glob('**/lib/l10n/*.arb'),
        )
    )
)
DEFAULT_ROOTS = (APP_DIR / 'lib', APP_DIR / 'test', REPO_ROOT / 'packages')
# gen-l10n output: it declares every key as a getter, so scanning it would make
# every key look used.
GENERATED_DIR = 'localization_file'
IDENTIFIER = re.compile(r'[A-Za-z_$][A-Za-z0-9_$]*')
_QUOTES = ('"', "'")


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


def _interpolation_end(source: str, start: int) -> int:
    """Return the index just past the `}` that closes `${` at *start*."""
    depth = 1
    i, n = start, len(source)
    while i < n:
        char = source[i]
        if char in _QUOTES:
            i += 1
            while i < n and source[i] != char:
                i += 2 if source[i] == '\\' else 1
            i += 1
            continue
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def _blank_literal(source: str, start: int, raw: bool) -> tuple[str, int]:
    """Blank the literal at *start*, keeping `$name` / `${...}` holes as code.

    Returns the replacement text and the index just past the literal. The
    replacement keeps the literal's width so the result lines up with the
    original source.
    """
    i = start + 1 if raw else start
    quote = source[i]
    closing = quote * 3 if source.startswith(quote * 3, i) else quote
    i += len(closing)
    pieces: list[str] = [' ' * (i - start)]
    text: list[str] = []

    def flush() -> None:
        pieces.append(' ' * len(text))
        text.clear()

    while i < len(source):
        if not raw and source[i] == '\\':
            text.append(source[i : i + 2])
            i += 2
            continue
        if source.startswith(closing, i):
            break
        if not raw and source[i] == '$':
            following = source[i + 1 : i + 2]
            if following == '{':
                flush()
                end = _interpolation_end(source, i + 2)
                pieces.append(source[i:end])
                i = end
                continue
            if following and (following.isalpha() or following in '_$'):
                flush()
                match = IDENTIFIER.match(source, i + 1)
                end = match.end() if match else i + 1
                pieces.append(source[i:end])
                i = end
                continue
        text.append(source[i])
        i += 1
    flush()
    end = min(i + len(closing), len(source))
    pieces.append(' ' * (end - i))
    return ''.join(pieces), end


def _code_only(source: str) -> str:
    """Return *source* with comments and string literal text blanked out.

    A message key is referenced by naming it as an identifier (`l10n.key`), so a
    mention inside a comment or inside literal text is not a reference. Blanking
    both keeps a stale mention from masking a dead key, which is the difference
    between "this key is still read" and "somebody once wrote its name down".

    Interpolation holes are kept because they are code: a key read inside
    `${...}` or after `$` must still count. Blanking is length-preserving so the
    result lines up with the original source.
    """
    out: list[str] = []
    i, n = 0, len(source)
    while i < n:
        char = source[i]
        if source.startswith('//', i):
            end = source.find('\n', i)
            end = n if end < 0 else end
            out.append(' ' * (end - i))
            i = end
            continue
        if source.startswith('/*', i):
            # Dart block comments nest: the inner `*/` only closes the inner
            # comment. Stopping at the first `*/` would leave the rest of the
            # outer comment looking like code and count a key named there as
            # referenced.
            depth, j = 1, i + 2
            while j < n and depth:
                if source.startswith('/*', j):
                    depth += 1
                    j += 2
                elif source.startswith('*/', j):
                    depth -= 1
                    j += 2
                else:
                    j += 1
            out.append(' ' * (j - i))
            i = j
            continue
        raw = char in 'rR' and i + 1 < n and source[i + 1] in _QUOTES
        if char in _QUOTES or raw:
            blanked, i = _blank_literal(source, i, raw)
            out.append(blanked)
            continue
        out.append(char)
        i += 1
    return ''.join(out)


def collect_identifiers(roots: tuple[Path, ...]) -> set[str]:
    """Return every identifier the Dart code under *roots* actually names."""
    identifiers: set[str] = set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.rglob('*.dart'):
            if GENERATED_DIR in path.parts:
                continue
            source = path.read_text(encoding='utf-8', errors='replace')
            identifiers.update(IDENTIFIER.findall(_code_only(source)))
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
    parser.add_argument(
        '--all',
        action='store_true',
        help='print every key with its reference status, not just the unused ones',
    )
    args = parser.parse_args(argv)

    if not args.arb:
        # An empty selection would report success without auditing anything, so
        # a moved or renamed ARB must fail loudly instead.
        print('No ARB files selected; nothing to audit.', file=sys.stderr)
        return 1

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
        if args.all:
            unused = set(report.unused)
            for key in report.message_keys:
                status = 'unused' if key in unused else 'referenced'
                print(f'  {status}: {key}')

    keys = unused_keys(reports)
    stale = sorted(allowed - set(keys))
    if not keys:
        print('Every message key is referenced.')
        return _report_stale(stale, args)

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
    return _report_stale(stale, args)


def _report_stale(stale: list[str], args: argparse.Namespace) -> int:
    """Fail `--check` when an allowlist entry no longer suppresses anything.

    A stale entry outlives the reason it was added: if the key is read again and
    later goes unused, the old line silently accepts it. Reported in plain mode
    so the cleanup is visible there too.
    """
    if not stale:
        return 0
    for key in stale:
        print(f'  allowlisted but referenced: {key}', file=sys.stderr)
    if args.check:
        print(
            f'{len(stale)} allowlist entr(y/ies) no longer needed; remove them '
            f'from {args.allowlist}',
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
