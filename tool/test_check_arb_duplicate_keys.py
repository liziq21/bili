#!/usr/bin/env python3
"""Unit tests for tool/check_arb_duplicate_keys.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_arb_duplicate_keys as arb  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent


def _write_arb(text: str) -> Path:
    handle = tempfile.NamedTemporaryFile('w', suffix='.arb', delete=False, encoding='utf-8')
    handle.write(text)
    handle.close()
    return Path(handle.name)


class FindDuplicatesTest(unittest.TestCase):
    def test_unique_keys_yield_nothing(self):
        data = arb._parse_pairs('{"a": "1", "b": "2"}')
        self.assertEqual(list(arb.find_duplicates(data)), [])

    def test_top_level_duplicate_is_reported(self):
        data = arb._parse_pairs('{"a": "1", "a": "2"}')
        self.assertEqual(list(arb.find_duplicates(data)), [((), 'a')])

    def test_nested_duplicate_reports_path(self):
        data = arb._parse_pairs('{"a": {"b": 1, "b": 2}}')
        self.assertEqual(list(arb.find_duplicates(data)), [(('a',), 'b')])

    def test_same_key_in_different_objects_is_not_a_duplicate(self):
        data = arb._parse_pairs('{"a": {"x": 1}, "b": {"x": 2}}')
        self.assertEqual(list(arb.find_duplicates(data)), [])

    def test_duplicate_inside_array_element_is_reported(self):
        data = arb._parse_pairs('{"a": [{"b": 1, "b": 2}]}')
        self.assertEqual(list(arb.find_duplicates(data)), [(('a', '0'), 'b')])


class CheckFileTest(unittest.TestCase):
    def test_clean_file_has_no_problems(self):
        path = _write_arb('{"a": "1", "@a": {"description": "d"}}')
        self.assertEqual(arb.check_file(path), [])
        path.unlink()

    def test_duplicate_file_reports_line(self):
        path = _write_arb('{"a": "1", "a": "2"}')
        problems = arb.check_file(path)
        self.assertEqual(len(problems), 1)
        self.assertIn("duplicate key 'a'", problems[0])
        self.assertIn('<top level>', problems[0])
        path.unlink()


class MainTest(unittest.TestCase):
    def test_main_fails_on_duplicate(self):
        path = _write_arb('{"a": "1", "a": "2"}')
        stderr = io.StringIO()
        with redirect_stdout(io.StringIO()), redirect_stderr(stderr):
            code = arb.main([str(path)])
        self.assertEqual(code, 1)
        self.assertIn("duplicate key 'a'", stderr.getvalue())
        path.unlink()

    def test_main_passes_on_clean_file(self):
        path = _write_arb('{"a": "1"}')
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            code = arb.main([str(path)])
        self.assertEqual(code, 0)
        path.unlink()

    def test_main_fails_on_missing_file(self):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            code = arb.main([str(REPO_ROOT / 'tool/does-not-exist.arb')])
        self.assertEqual(code, 1)


class RealArbFilesTest(unittest.TestCase):
    def test_default_set_covers_app_and_package_arbs(self):
        paths = {path.relative_to(REPO_ROOT).as_posix() for path in arb.DEFAULT_ARB_FILES}
        self.assertIn('app/lib/l10n/app_.arb', paths)
        self.assertIn('packages/bilibili/lib/l10n/bilibili_en.arb', paths)
        self.assertIn('packages/youtube/lib/l10n/youtube_en.arb', paths)

    def test_committed_arb_files_have_no_duplicate_keys(self):
        with redirect_stdout(io.StringIO()) as stdout, redirect_stderr(io.StringIO()):
            code = arb.main([str(path) for path in arb.DEFAULT_ARB_FILES])
        self.assertEqual(code, 0, stdout.getvalue())
