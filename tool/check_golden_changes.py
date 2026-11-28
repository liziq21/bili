#!/usr/bin/env python3
"""Fail when a re-record run changed files outside the golden baseline directory.

`.github/workflows/rerecord-goldens.yml` checks out a caller-supplied branch and
runs its tests with `--update-goldens` inside a job that holds `contents: write`
and opens pull requests. The branch's own code therefore runs with write access,
and any change it makes could ride along in a pull request whose body says it
only contains re-rendered PNGs (Issue #720).

This guard inspects the working tree after the re-record step and fails unless
every change is a PNG under `app/test/golden/goldens/ci/`.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

GOLDEN_DIR = 'app/test/golden/goldens/ci/'
STATUS_ARGS = (
    'git',
    'status',
    '--porcelain=v1',
    '-z',
    '--untracked-files=all',
)


def changed_paths(status: str) -> list[str]:
    """Return every path named by ``git status --porcelain -z`` output.

    Rename and copy entries carry the original path as an extra NUL-terminated
    field; both sides count, because either one may sit outside the allowed
    directory.
    """
    fields = status.split('\0')
    paths: list[str] = []
    index = 0
    while index < len(fields):
        entry = fields[index]
        index += 1
        if not entry:
            continue
        status_code = entry[:2]
        paths.append(entry[3:])
        if 'R' in status_code or 'C' in status_code:
            paths.append(fields[index])
            index += 1
    return paths


def is_golden_png(path: str) -> bool:
    return path.startswith(GOLDEN_DIR) and path.lower().endswith('.png')


def unexpected_paths(paths: list[str]) -> list[str]:
    return sorted({path for path in paths if not is_golden_png(path)})


def read_status() -> str:
    completed = subprocess.run(STATUS_ARGS, capture_output=True, check=False)
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
    args = parser.parse_args(argv)

    try:
        if args.status_file is None:
            status = read_status()
        else:
            status = args.status_file.read_bytes().decode('utf-8', 'surrogateescape')
    except (OSError, RuntimeError) as error:
        print(f'::error::could not read git status: {error}', file=sys.stderr)
        return 2

    unexpected = unexpected_paths(changed_paths(status))
    if not unexpected:
        print(f'Only golden baselines under {GOLDEN_DIR} changed.')
        return 0

    for path in unexpected:
        print(
            f'::error file={path}::the re-record job changed a file outside '
            f'{GOLDEN_DIR}'
        )
    print(
        'The re-record workflow may only commit baseline PNGs under '
        f'{GOLDEN_DIR}. Revert the other changes on the target branch and '
        're-run the workflow.',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
