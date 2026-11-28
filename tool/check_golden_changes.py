#!/usr/bin/env python3
"""Fail when a re-record run changed files outside the golden baseline directory.

`.github/workflows/rerecord-goldens.yml` checks out a caller-supplied branch and
runs its tests with `--update-goldens` inside a job that holds `contents: write`
and opens pull requests. The branch's own code therefore runs with write access,
and any change it makes could ride along in a pull request whose body says it
only contains re-rendered PNGs (Issue #720).

This guard inspects the working tree after the re-record step and fails unless
every change is an added or modified regular PNG under
`app/test/golden/goldens/ci/`.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

GOLDEN_DIR = 'app/test/golden/goldens/ci/'
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
STATUS_ARGS = (
    'git',
    'status',
    '--porcelain=v1',
    '-z',
    '--untracked-files=all',
)


@dataclass(frozen=True)
class Change:
    status: str
    path: str
    old_path: str | None = None


def is_allowed_status(status: str) -> bool:
    """Only additions and modifications are re-records.

    Deletions, renames, copies, type changes and conflicts belong in the code
    pull request, where a reviewer sees the code change that caused them.
    """
    code = status.strip()
    return bool(code) and all(char in {'A', 'M', '?'} for char in code)


def parse_changes(status: str) -> list[Change]:
    """Parse ``git status --porcelain -z`` output into changes.

    Rename and copy entries carry the original path as an extra NUL-terminated
    field, so both sides are kept.
    """
    fields = status.split('\0')
    changes: list[Change] = []
    index = 0
    while index < len(fields):
        entry = fields[index]
        index += 1
        if not entry:
            continue
        status_code = entry[:2]
        path = entry[3:]
        old_path = None
        if 'R' in status_code or 'C' in status_code:
            old_path = fields[index]
            index += 1
        changes.append(Change(status_code, path, old_path))
    return changes


def is_golden_png(path: str) -> bool:
    return path.startswith(GOLDEN_DIR) and path.endswith('.png')


def is_regular_png(path: Path) -> bool:
    """True when ``path`` is a regular, non-symlink file with a PNG signature."""
    if path.is_symlink() or not path.is_file():
        return False
    try:
        with path.open('rb') as handle:
            return handle.read(len(PNG_SIGNATURE)) == PNG_SIGNATURE
    except OSError:
        return False


def escape_command_property(value: str) -> str:
    """Escape a GitHub workflow-command property value.

    A caller-supplied branch can create a file whose name contains a newline
    followed by workflow-command syntax; the path is printed inside an
    ``::error file=…::`` annotation, so it must not be able to start a new
    command.
    """
    return (
        value.replace('%', '%25')
        .replace('\r', '%0D')
        .replace('\n', '%0A')
        .replace(':', '%3A')
        .replace(',', '%2C')
    )


def unexpected_changes(changes: list[Change], root: Path) -> list[str]:
    """Return paths whose change the re-record workflow must not commit."""
    unexpected: set[str] = set()
    for change in changes:
        for path in (change.path, change.old_path):
            if path is not None and not is_golden_png(path):
                unexpected.add(path)
        if not is_allowed_status(change.status):
            unexpected.add(change.path)
            if change.old_path is not None:
                unexpected.add(change.old_path)
            continue
        if not is_regular_png(root / change.path):
            unexpected.add(change.path)
    return sorted(unexpected)


def read_status() -> str:
    # STATUS_ARGS is a constant tuple; there is no shell and no interpolation.
    completed = subprocess.run(  # nosemgrep: python.lang.security.audit.dangerous-subprocess-use-audit
        STATUS_ARGS,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.decode('utf-8', 'replace').strip())
    return completed.stdout.decode('utf-8', 'surrogateescape')


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        '--status-file',
        type=Path,
        help='read `git status --porcelain -z` output from this file instead of git',
    )
    parser.add_argument(
        '--root',
        type=Path,
        default=Path('.'),
        help='repository root used to validate changed files (default: cwd)',
    )
    args = parser.parse_args(argv)

    try:
        if args.status_file is None:
            status = read_status()
        else:
            status = args.status_file.read_bytes().decode('utf-8', 'surrogateescape')
    except (OSError, RuntimeError) as error:
        print(f'::error::could not read git status: {error}', file=sys.stderr)
        return 2

    unexpected = unexpected_changes(parse_changes(status), args.root)
    if not unexpected:
        print(f'Only golden baselines under {GOLDEN_DIR} changed.')
        return 0

    for path in unexpected:
        print(
            f'::error file={escape_command_property(path)}::not an allowed '
            'golden baseline change'
        )
    print(
        'The re-record workflow may only add or modify regular PNGs under '
        f'{GOLDEN_DIR}. Revert the other changes on the target branch and '
        're-run the workflow.',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
