#!/usr/bin/env python3
"""Unit tests for tool/check_golden_changes.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import contextlib
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_golden_changes as golden  # noqa: E402

GOLDEN = 'app/test/golden/goldens/ci/home_screen.png'
OTHER_GOLDEN = 'app/test/golden/goldens/ci/dark_theme.png'
PNG = golden.PNG_SIGNATURE + b'\x00' * 8
REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / '.github' / 'workflows' / 'rerecord-goldens.yml'


def status(*entries: str) -> str:
    return ''.join(f'{entry}\0' for entry in entries)


def write(root: Path, relative: str, data: bytes = PNG) -> Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return path


class ParseChangesTest(unittest.TestCase):
    def test_clean_tree_has_no_changes(self) -> None:
        self.assertEqual(golden.parse_changes(''), [])

    def test_modified_and_untracked_entries(self) -> None:
        changes = golden.parse_changes(status(f' M {GOLDEN}', f'?? {OTHER_GOLDEN}'))
        self.assertEqual(
            [(change.status, change.path) for change in changes],
            [(' M', GOLDEN), ('??', OTHER_GOLDEN)],
        )

    def test_rename_reports_both_sides(self) -> None:
        changes = golden.parse_changes(status(f'R  {GOLDEN}\0{OTHER_GOLDEN}'))
        self.assertEqual(changes, [golden.Change('R ', GOLDEN, OTHER_GOLDEN)])

    def test_copy_reports_both_sides(self) -> None:
        changes = golden.parse_changes(status(f'C  {GOLDEN}\0{OTHER_GOLDEN}'))
        self.assertEqual(changes, [golden.Change('C ', GOLDEN, OTHER_GOLDEN)])

    def test_path_with_spaces_is_not_split(self) -> None:
        spaced = 'app/test/golden/goldens/ci/a b.png'
        self.assertEqual(
            golden.parse_changes(status(f' M {spaced}')),
            [golden.Change(' M', spaced)],
        )

    def test_trailing_nul_is_optional(self) -> None:
        self.assertEqual(
            golden.parse_changes(f' M {GOLDEN}'), [golden.Change(' M', GOLDEN)]
        )


class GoldenPathTest(unittest.TestCase):
    def test_baseline_pngs_are_allowed(self) -> None:
        self.assertTrue(golden.is_golden_png(GOLDEN))
        self.assertTrue(golden.is_golden_png('app/test/golden/goldens/ci/a b.png'))

    def test_uppercase_extension_is_rejected(self) -> None:
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci/A.PNG'))

    def test_other_directories_are_rejected(self) -> None:
        self.assertFalse(golden.is_golden_png('app/test/golden/failures/home.png'))
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci2/home.png'))
        self.assertFalse(golden.is_golden_png('app/lib/main.dart'))
        self.assertFalse(golden.is_golden_png('.github/workflows/rerecord-goldens.yml'))

    def test_non_png_files_inside_the_directory_are_rejected(self) -> None:
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci/evil.sh'))
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci/README.md'))


class RegularPngTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_png_signature_is_accepted(self) -> None:
        self.assertTrue(golden.is_regular_png(write(self.root, GOLDEN)))

    def test_non_png_bytes_are_rejected(self) -> None:
        path = write(self.root, GOLDEN, b'not a png')
        self.assertFalse(golden.is_regular_png(path))

    def test_directory_is_rejected(self) -> None:
        path = self.root / GOLDEN
        path.mkdir(parents=True)
        self.assertFalse(golden.is_regular_png(path))

    def test_symlink_is_rejected(self) -> None:
        target = write(self.root, 'outside.png')
        link = self.root / GOLDEN
        link.parent.mkdir(parents=True)
        try:
            os.symlink(target, link)
        except OSError as error:
            self.skipTest(f'symlinks unavailable: {error}')
        self.assertFalse(golden.is_regular_png(link))


class UnexpectedChangesTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def check(self, *entries: str) -> list[str]:
        return golden.unexpected_changes(golden.parse_changes(status(*entries)), self.root)

    def test_modified_golden_passes(self) -> None:
        write(self.root, GOLDEN)
        self.assertEqual(self.check(f' M {GOLDEN}'), [])

    def test_added_golden_passes(self) -> None:
        write(self.root, OTHER_GOLDEN)
        self.assertEqual(self.check(f'?? {OTHER_GOLDEN}'), [])

    def test_golden_rename_passes_when_both_sides_are_pngs(self) -> None:
        write(self.root, OTHER_GOLDEN)
        self.assertEqual(self.check(f'R  {OTHER_GOLDEN}\0{GOLDEN}'), [])

    def test_golden_copy_passes_when_both_sides_are_pngs(self) -> None:
        write(self.root, OTHER_GOLDEN)
        self.assertEqual(self.check(f'C  {OTHER_GOLDEN}\0{GOLDEN}'), [])

    def test_non_png_bytes_with_png_suffix_are_rejected(self) -> None:
        write(self.root, GOLDEN, b'#!/bin/sh\nexit 0\n')
        self.assertEqual(self.check(f' M {GOLDEN}'), [GOLDEN])

    def test_symlink_with_png_suffix_is_rejected(self) -> None:
        target = write(self.root, 'outside.png')
        link = self.root / GOLDEN
        link.parent.mkdir(parents=True)
        try:
            os.symlink(target, link)
        except OSError as error:
            self.skipTest(f'symlinks unavailable: {error}')
        self.assertEqual(self.check(f' M {GOLDEN}'), [GOLDEN])

    def test_deleted_golden_is_rejected(self) -> None:
        self.assertEqual(self.check(f' D {GOLDEN}'), [GOLDEN])

    def test_rename_to_outside_path_is_rejected(self) -> None:
        write(self.root, 'app/lib/renamed.dart')
        self.assertEqual(
            self.check(f'R  app/lib/renamed.dart\0{GOLDEN}'),
            ['app/lib/renamed.dart'],
        )

    def test_rename_from_outside_path_is_rejected(self) -> None:
        write(self.root, GOLDEN)
        self.assertEqual(
            self.check(f'R  {GOLDEN}\0app/lib/main.dart'),
            ['app/lib/main.dart'],
        )

    def test_outside_change_is_rejected(self) -> None:
        write(self.root, GOLDEN)
        self.assertEqual(
            self.check(f' M {GOLDEN}', ' M app/lib/main.dart'),
            ['app/lib/main.dart'],
        )

    def test_unexpected_paths_are_sorted_and_deduplicated(self) -> None:
        write(self.root, GOLDEN)
        self.assertEqual(
            self.check(f' M {GOLDEN}', ' M app/lib/b.dart', ' M app/lib/a.dart', ' M app/lib/b.dart'),
            ['app/lib/a.dart', 'app/lib/b.dart'],
        )


class EscapeCommandPropertyTest(unittest.TestCase):
    def test_workflow_command_metacharacters_are_escaped(self) -> None:
        self.assertEqual(
            golden.escape_command_property('a%b\rc\nd:e,f'),
            'a%25b%0Dc%0Ad%3Ae%2Cf',
        )


class WorkflowWiringTest(unittest.TestCase):
    """Keep the workflow on the trusted copy and the PNG-only pathspec."""

    def setUp(self) -> None:
        self.text = WORKFLOW.read_text(encoding='utf-8')

    def test_guard_runs_from_the_workflow_revision(self) -> None:
        self.assertIn('github.workflow_sha', self.text)
        self.assertIn('$RUNNER_TEMP/golden-guard/check_golden_changes.py', self.text)
        self.assertNotIn('python3 tool/check_golden_changes.py', self.text)

    def test_pull_request_stages_only_pngs(self) -> None:
        self.assertRegex(
            self.text,
            r'add-paths: \|\n\s+app/test/golden/goldens/ci/\*\.png\n',
        )


class MainTest(unittest.TestCase):
    def run_main(self, output: str, root: Path) -> tuple[int, str, str]:
        with tempfile.NamedTemporaryFile('wb', delete=False) as handle:
            handle.write(output.encode('utf-8'))
            path = Path(handle.name)
        stdout = io.StringIO()
        stderr = io.StringIO()
        try:
            with (
                contextlib.redirect_stdout(stdout),
                contextlib.redirect_stderr(stderr),
            ):
                code = golden.main(
                    ['--status-file', str(path), '--root', str(root)]
                )
        finally:
            path.unlink()
        return code, stdout.getvalue(), stderr.getvalue()

    def test_clean_tree_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            code, stdout, _ = self.run_main('', Path(directory))
        self.assertEqual(code, 0)
        self.assertIn(golden.GOLDEN_DIR, stdout)

    def test_only_baselines_pass(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, GOLDEN)
            write(root, OTHER_GOLDEN)
            code, _, _ = self.run_main(
                status(f' M {GOLDEN}', f'?? {OTHER_GOLDEN}'), root
            )
        self.assertEqual(code, 0)

    def test_outside_change_fails_with_annotation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, GOLDEN)
            write(root, 'app/lib/main.dart', b'void main() {}\n')
            code, stdout, stderr = self.run_main(
                status(f' M {GOLDEN}', ' M app/lib/main.dart'), root
            )
        self.assertEqual(code, 1)
        self.assertIn('::error file=app/lib/main.dart::', stdout)
        self.assertIn('may only add or modify regular PNGs', stderr)

    def test_deleted_golden_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            code, stdout, _ = self.run_main(status(f' D {GOLDEN}'), Path(directory))
        self.assertEqual(code, 1)
        self.assertIn(GOLDEN, stdout)

    def test_non_png_content_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, GOLDEN, b'not a png')
            code, stdout, _ = self.run_main(status(f' M {GOLDEN}'), root)
        self.assertEqual(code, 1)
        self.assertIn(GOLDEN, stdout)

    def test_newline_in_path_cannot_forge_a_workflow_command(self) -> None:
        malicious = 'app/lib/x\n::error::y.dart'
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, malicious, b'void main() {}\n')
            code, stdout, _ = self.run_main(status(f' M {malicious}'), root)
        self.assertEqual(code, 1)
        self.assertIn(
            '::error file=app/lib/x%0A%3A%3Aerror%3A%3Ay.dart::', stdout
        )
        self.assertNotIn('\n::error::', stdout)

    def test_workflow_edit_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, '.github/workflows/rerecord-goldens.yml', b'name: x\n')
            code, stdout, _ = self.run_main(
                status(' M .github/workflows/rerecord-goldens.yml'), root
            )
        self.assertEqual(code, 1)
        self.assertIn('.github/workflows/rerecord-goldens.yml', stdout)

    def test_unreadable_status_file_reports_error(self) -> None:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with (
            contextlib.redirect_stdout(stdout),
            contextlib.redirect_stderr(stderr),
        ):
            code = golden.main(['--status-file', '/nonexistent/status'])
        self.assertEqual(code, 2)
        self.assertIn('::error::', stderr.getvalue())


if __name__ == '__main__':
    unittest.main()
