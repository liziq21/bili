#!/usr/bin/env python3
"""Unit tests for tool/check_golden_changes.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_golden_changes as golden  # noqa: E402

GOLDEN = 'app/test/golden/goldens/ci/home_screen.png'
OTHER_GOLDEN = 'app/test/golden/goldens/ci/dark_theme.png'
REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / '.github' / 'workflows' / 'rerecord-goldens.yml'


def status(*entries: str) -> str:
    return ''.join(f'{entry}\0' for entry in entries)


class ChangedPathsTest(unittest.TestCase):
    def test_clean_tree_has_no_paths(self) -> None:
        self.assertEqual(golden.changed_paths(''), [])

    def test_modified_and_untracked_entries(self) -> None:
        output = status(f' M {GOLDEN}', f'?? {OTHER_GOLDEN}')
        self.assertEqual(golden.changed_paths(output), [GOLDEN, OTHER_GOLDEN])

    def test_rename_reports_both_sides(self) -> None:
        output = status(f'R  {GOLDEN}\0{OTHER_GOLDEN}')
        self.assertEqual(
            golden.changed_paths(output), [GOLDEN, OTHER_GOLDEN]
        )

    def test_copy_reports_both_sides(self) -> None:
        output = status(f'C  {GOLDEN}\0{OTHER_GOLDEN}')
        self.assertEqual(
            golden.changed_paths(output), [GOLDEN, OTHER_GOLDEN]
        )

    def test_path_with_spaces_is_not_split(self) -> None:
        spaced = 'app/test/golden/goldens/ci/a b.png'
        self.assertEqual(golden.changed_paths(status(f' M {spaced}')), [spaced])

    def test_trailing_nul_is_optional(self) -> None:
        self.assertEqual(golden.changed_paths(f' M {GOLDEN}'), [GOLDEN])


class GoldenPngTest(unittest.TestCase):
    def test_baseline_pngs_are_allowed(self) -> None:
        self.assertTrue(golden.is_golden_png(GOLDEN))
        self.assertTrue(golden.is_golden_png('app/test/golden/goldens/ci/UPPER.PNG'))

    def test_other_directories_are_rejected(self) -> None:
        self.assertFalse(golden.is_golden_png('app/test/golden/failures/home.png'))
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci2/home.png'))
        self.assertFalse(golden.is_golden_png('app/lib/main.dart'))
        self.assertFalse(golden.is_golden_png('.github/workflows/rerecord-goldens.yml'))

    def test_non_png_files_inside_the_directory_are_rejected(self) -> None:
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci/evil.sh'))
        self.assertFalse(golden.is_golden_png('app/test/golden/goldens/ci/README.md'))


class UnexpectedPathsTest(unittest.TestCase):
    def test_only_baselines_leave_nothing_unexpected(self) -> None:
        self.assertEqual(golden.unexpected_paths([GOLDEN, OTHER_GOLDEN]), [])

    def test_outside_changes_are_sorted_and_deduplicated(self) -> None:
        paths = ['app/lib/b.dart', GOLDEN, 'app/lib/a.dart', 'app/lib/b.dart']
        self.assertEqual(
            golden.unexpected_paths(paths), ['app/lib/a.dart', 'app/lib/b.dart']
        )

    def test_rename_with_one_outside_side_is_unexpected(self) -> None:
        paths = [GOLDEN, 'app/lib/renamed.dart']
        self.assertEqual(golden.unexpected_paths(paths), ['app/lib/renamed.dart'])


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
    def run_main(self, output: str) -> tuple[int, str, str]:
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
                code = golden.main(['--status-file', str(path)])
        finally:
            path.unlink()
        return code, stdout.getvalue(), stderr.getvalue()

    def test_clean_tree_passes(self) -> None:
        code, stdout, _ = self.run_main('')
        self.assertEqual(code, 0)
        self.assertIn(golden.GOLDEN_DIR, stdout)

    def test_only_baselines_pass(self) -> None:
        code, _, _ = self.run_main(status(f' M {GOLDEN}', f'?? {OTHER_GOLDEN}'))
        self.assertEqual(code, 0)

    def test_outside_change_fails_with_annotation(self) -> None:
        code, stdout, stderr = self.run_main(status(f' M {GOLDEN}', ' M app/lib/main.dart'))
        self.assertEqual(code, 1)
        self.assertIn('::error file=app/lib/main.dart::', stdout)
        self.assertIn('may only commit baseline PNGs', stderr)

    def test_workflow_edit_fails(self) -> None:
        code, stdout, _ = self.run_main(
            status(' M .github/workflows/rerecord-goldens.yml')
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
