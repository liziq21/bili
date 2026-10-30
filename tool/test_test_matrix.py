#!/usr/bin/env python3
"""Unit tests for tool/test_matrix.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import test_matrix  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def _json_events(events: list[dict]) -> str:
    return '\n'.join(json.dumps(e) for e in events)


class AreaOfTest(unittest.TestCase):
    def test_longest_prefix_wins(self):
        # bpi before bilibili, ypi before youtube.
        self.assertEqual(test_matrix.area_of('packages/bilibili/bpi/test/x.dart'),
                         'bpi')
        self.assertEqual(test_matrix.area_of('packages/bilibili/test/x.dart'),
                         'bilibili')
        self.assertEqual(test_matrix.area_of('packages/youtube/ypi/test/x.dart'),
                         'ypi')
        self.assertEqual(test_matrix.area_of('packages/youtube/test/x.dart'),
                         'youtube')
        self.assertEqual(test_matrix.area_of('app/test/x.dart'), 'app')
        self.assertEqual(test_matrix.area_of('packages/data/test/x.dart'),
                         'data')


class MappingCheckTest(unittest.TestCase):
    def test_mapping_covers_all_discovered_files(self):
        """The real mapping must match the real test tree exactly."""
        with redirect_stdout(io.StringIO()):
            code = test_matrix.check_mapping(REPO_ROOT)
        self.assertEqual(code, 0, 'mapping does not match the test tree')

    def test_report_lists_every_mapped_file(self):
        report = test_matrix.render_report()
        for category, files in test_matrix.TEST_MATRIX.items():
            for path in files:
                self.assertIn(f'- `{path}`', report,
                              f'{path} missing from report')
        # Category totals sum to the discovered count.
        discovered = len(test_matrix.discover_test_files(REPO_ROOT))
        mapped = sum(len(f) for f in test_matrix.TEST_MATRIX.values())
        self.assertEqual(mapped, discovered)


class LcovParseTest(unittest.TestCase):
    def test_parse_totals(self):
        with tempfile.TemporaryDirectory() as tmp:
            lcov = Path(tmp) / 'x.lcov'
            _write(lcov, '\n'.join([
                'TN:',
                'SF:lib/a.dart',
                'LF:10', 'LH:8', 'BRF:4', 'BRH:2',
                'end_of_record',
                'SF:lib/b.dart',
                'LF:20', 'LH:20',
                'end_of_record',
            ]))
            lf, lh, brf, brh = test_matrix.parse_lcov_totals(lcov)
            self.assertEqual((lf, lh, brf, brh), (30, 28, 4, 2))


def _events(suites, tests, dones):
    return _json_events([
        {'type': 'start', 'time': 0, 'protocolVersion': '0.1.0'},
        *suites,
        *tests,
        *dones,
        {'type': 'done', 'time': 1, 'success': True},
    ])


class ReporterJsonTest(unittest.TestCase):

    def test_current_protocol_pass(self):
        suites = [{'type': 'suite', 'time': 0,
                   'suite': {'id': 1, 'platform': 'vm',
                             'path': 'test/a_test.dart'}}]
        tests = [{'type': 'testStart', 'time': 1,
                  'test': {'id': 10, 'name': 't1', 'suiteID': 1,
                           'groupIDs': []}}]
        dones = [{'type': 'testDone', 'time': 2, 'testID': 10,
                  'result': 'success', 'hidden': False, 'skipped': False}]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'out.json'
            _write(path, _events(suites, tests, dones))
            files, passed = test_matrix.parse_reporter_json(path)
        self.assertEqual((files, passed), (1, 1))

    def test_current_protocol_failure_marks_file(self):
        suites = [
            {'type': 'suite', 'time': 0,
             'suite': {'id': 1, 'platform': 'vm', 'path': 'test/a.dart'}},
            {'type': 'suite', 'time': 0,
             'suite': {'id': 2, 'platform': 'vm', 'path': 'test/b.dart'}},
        ]
        tests = [
            {'type': 'testStart', 'time': 1,
             'test': {'id': 10, 'name': 't1', 'suiteID': 1, 'groupIDs': []}},
            {'type': 'testStart', 'time': 1,
             'test': {'id': 11, 'name': 't2', 'suiteID': 2, 'groupIDs': []}},
        ]
        dones = [
            {'type': 'testDone', 'time': 2, 'testID': 10,
             'result': 'failure', 'hidden': False, 'skipped': False},
            {'type': 'testDone', 'time': 2, 'testID': 11,
             'result': 'success', 'hidden': False, 'skipped': False},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'out.json'
            _write(path, _events(suites, tests, dones))
            files, passed = test_matrix.parse_reporter_json(path)
        self.assertEqual((files, passed), (2, 1))

    def test_legacy_protocol_root_and_name(self):
        suites = [
            {'type': 'suite', 'time': 0,
             'suite': {'id': 1, 'root': True, 'name': 'test/a.dart',
                       'platform': 'vm'}},
            {'type': 'suite', 'time': 0,
             'suite': {'id': 2, 'root': False, 'name': 'virtual',
                       'platform': 'vm'}},
        ]
        tests = [{'type': 'testStart', 'time': 1,
                  'test': {'id': 10, 'name': 't1', 'suiteID': 1,
                           'groupIDs': []}}]
        dones = [{'type': 'testDone', 'time': 2, 'testID': 10,
                  'result': 'success', 'hidden': False, 'skipped': False}]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'out.json'
            _write(path, _events(suites, tests, dones))
            files, passed = test_matrix.parse_reporter_json(path)
        # Non-root legacy suites are loading virtuals: not counted.
        self.assertEqual((files, passed), (1, 1))

    def test_error_event_after_completion_marks_failed(self):
        suites = [{'type': 'suite', 'time': 0,
                   'suite': {'id': 1, 'platform': 'vm',
                             'path': 'test/a.dart'}}]
        tests = [{'type': 'testStart', 'time': 1,
                  'test': {'id': 10, 'name': 't1', 'suiteID': 1,
                           'groupIDs': []}}]
        dones = [
            {'type': 'testDone', 'time': 2, 'testID': 10,
             'result': 'success', 'hidden': False, 'skipped': False},
            {'type': 'error', 'time': 3, 'testID': 10,
             'error': 'boom', 'stackTrace': '', 'isFailure': True},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'out.json'
            _write(path, _events(suites, tests, dones))
            files, passed = test_matrix.parse_reporter_json(path)
        self.assertEqual((files, passed), (1, 0))

    def test_empty_file_warns_and_returns_zero(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'out.json'
            _write(path, '')
            err = io.StringIO()
            with redirect_stdout(err):
                files, passed = test_matrix.parse_reporter_json(path)
        self.assertEqual((files, passed), (0, 0))


class SummaryTest(unittest.TestCase):
    def test_summary_aggregates_categories(self):
        with tempfile.TemporaryDirectory() as tmp:
            matrix_dir = Path(tmp)
            for cat in ('unit', 'widget', 'golden', 'contract',
                        'integration'):
                lh = {'unit': 9, 'widget': 5}.get(cat, 10)
                _write(matrix_dir / f'app-{cat}.lcov',
                       f'SF:app/lib/{cat}.dart\nLF:10\nLH:{lh}\nend_of_record\n')
            _write(matrix_dir / 'app-unit.json', _events(
                [{'type': 'suite', 'time': 0,
                  'suite': {'id': 1, 'platform': 'vm',
                            'path': 'test/a.dart'}}],
                [{'type': 'testStart', 'time': 1,
                  'test': {'id': 10, 'name': 't1', 'suiteID': 1,
                           'groupIDs': []}}],
                [{'type': 'testDone', 'time': 2, 'testID': 10,
                  'result': 'success', 'hidden': False, 'skipped': False}],
            ))
            _write(matrix_dir / 'app-widget.json', _events(
                [{'type': 'suite', 'time': 0,
                  'suite': {'id': 2, 'platform': 'vm',
                            'path': 'test/b.dart'}}],
                [{'type': 'testStart', 'time': 1,
                  'test': {'id': 11, 'name': 't2', 'suiteID': 2,
                           'groupIDs': []}}],
                [{'type': 'testDone', 'time': 2, 'testID': 11,
                  'result': 'failure', 'hidden': False, 'skipped': False}],
            ))
            out = io.StringIO()
            with redirect_stdout(out):
                code = test_matrix.summary(matrix_dir)
            self.assertEqual(code, 0)
            summary_md = (matrix_dir / 'summary.md').read_text()
            self.assertIn('| unit | 1 | 1/1 | 90.0% | N/A |', summary_md)
            self.assertIn('| widget | 1 | 0/1 | 50.0% | N/A |', summary_md)


if __name__ == '__main__':
    unittest.main()
