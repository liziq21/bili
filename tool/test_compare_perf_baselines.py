#!/usr/bin/env python3
"""Unit tests for tool/compare_perf_baselines.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import contextlib
import io
import json
import math
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import compare_perf_baselines as perf  # noqa: E402


def run(**overrides: float) -> dict[str, float]:
    metrics = {
        'ui_frame_ms_median': 8.0,
        'ui_frame_ms_p90': 12.0,
        'raster_frame_ms_median': 4.0,
        'raster_frame_ms_p90': 7.0,
        'missed_frames': 2,
    }
    metrics.update(overrides)
    return metrics


def baseline(scenarios: dict[str, list[dict[str, float]]] | None = None,
             target: dict | None = None,
             build: dict | None = None) -> dict:
    return {
        'schema_version': 1,
        'target': target or {
            'device': 'linux-desktop',
            'os': 'Debian GNU/Linux 13',
            'display_refresh_hz': 60,
            'viewport': '1280x900',
            'text_scale': 1.0,
        },
        'build': build or {
            'mode': 'profile',
            'flutter': '3.50.0',
            'dart': '3.14.0',
            'revision': 'aaaaaaa',
        },
        'scenarios': {
            name: {'duration_seconds': 20, 'warmup_seconds': 5, 'runs': runs}
            for name, runs in (scenarios or {'home_feed_scroll': [run()]}).items()
        },
    }


def write_json(data: dict) -> str:
    handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
    with handle:
        json.dump(data, handle)
    return handle.name


class ParseBaselineTest(unittest.TestCase):
    def test_valid_baseline(self) -> None:
        parsed = perf.parse_baseline(baseline())
        self.assertEqual(parsed.build['mode'], 'profile')
        self.assertIn('home_feed_scroll', parsed.scenarios)
        self.assertEqual(parsed.scenarios['home_feed_scroll'].median('missed_frames'), 2)

    def test_schema_version_must_match(self) -> None:
        data = baseline()
        data['schema_version'] = 2
        with self.assertRaises(perf.BaselineError):
            perf.parse_baseline(data)

    def test_non_profile_build_rejected(self) -> None:
        data = baseline()
        data['build']['mode'] = 'debug'
        with self.assertRaises(perf.BaselineError) as ctx:
            perf.parse_baseline(data)
        self.assertIn('profile', str(ctx.exception))

    def test_missing_metric_rejected(self) -> None:
        bad = run()
        del bad['ui_frame_ms_p90']
        data = baseline({'home_feed_scroll': [bad]})
        with self.assertRaises(perf.BaselineError) as ctx:
            perf.parse_baseline(data)
        self.assertIn('ui_frame_ms_p90', str(ctx.exception))

    def test_negative_metric_rejected(self) -> None:
        data = baseline({'home_feed_scroll': [run(missed_frames=-1)]})
        with self.assertRaises(perf.BaselineError):
            perf.parse_baseline(data)

    def test_empty_scenarios_rejected(self) -> None:
        data = baseline()
        data['scenarios'] = {}
        with self.assertRaises(perf.BaselineError):
            perf.parse_baseline(data)

    def test_few_runs_warns_but_parses(self) -> None:
        parsed = perf.parse_baseline(baseline({'home_feed_scroll': [run()]}))
        self.assertTrue(any('at least 3' in w for w in parsed.warnings))

    def test_median_across_runs(self) -> None:
        runs = [run(ui_frame_ms_median=10.0),
                run(ui_frame_ms_median=20.0),
                run(ui_frame_ms_median=30.0)]
        parsed = perf.parse_baseline(baseline({'home_feed_scroll': runs}))
        self.assertEqual(parsed.scenarios['home_feed_scroll'].median('ui_frame_ms_median'), 20.0)
        self.assertEqual(parsed.scenarios['home_feed_scroll'].spread('ui_frame_ms_median'), 20.0)


class CompareTest(unittest.TestCase):
    def compare(self, before: dict, after: dict, **kwargs):
        return perf.build_report(
            perf.parse_baseline(before), perf.parse_baseline(after), **kwargs)

    def test_regression_above_threshold(self) -> None:
        after = baseline({'home_feed_scroll': [run(ui_frame_ms_median=9.0)]})
        report = self.compare(baseline(), after, threshold=5.0)
        row = next(r for r in report.rows if r.metric == 'ui_frame_ms_median')
        self.assertAlmostEqual(row.delta_percent, 12.5)
        self.assertTrue(row.regression)
        self.assertTrue(report.has_regression)

    def test_within_threshold_passes(self) -> None:
        after = baseline({'home_feed_scroll': [run(ui_frame_ms_median=8.2)]})
        report = self.compare(baseline(), after, threshold=5.0)
        self.assertFalse(report.has_regression)

    def test_improvement_passes(self) -> None:
        after = baseline({'home_feed_scroll': [run(ui_frame_ms_median=6.0)]})
        report = self.compare(baseline(), after, threshold=5.0)
        row = next(r for r in report.rows if r.metric == 'ui_frame_ms_median')
        self.assertAlmostEqual(row.delta_percent, -25.0)
        self.assertFalse(report.has_regression)

    def test_zero_before_zero_after_is_not_regression(self) -> None:
        before = baseline({'home_feed_scroll': [run(missed_frames=0)]})
        after = baseline({'home_feed_scroll': [run(missed_frames=0)]})
        report = self.compare(before, after, threshold=5.0)
        row = next(r for r in report.rows if r.metric == 'missed_frames')
        self.assertEqual(row.delta_percent, 0.0)
        self.assertFalse(row.regression)

    def test_zero_before_positive_after_is_infinite_regression(self) -> None:
        before = baseline({'home_feed_scroll': [run(missed_frames=0)]})
        after = baseline({'home_feed_scroll': [run(missed_frames=1)]})
        report = self.compare(before, after, threshold=5.0)
        row = next(r for r in report.rows if r.metric == 'missed_frames')
        self.assertTrue(math.isinf(row.delta_percent))
        self.assertTrue(row.regression)

    def test_target_mismatch_rejected(self) -> None:
        after = baseline(target={
            'device': 'pixel-7',
            'os': 'Android 15',
            'display_refresh_hz': 120,
            'viewport': '1080x2400',
            'text_scale': 1.0,
        })
        with self.assertRaises(perf.BaselineError) as ctx:
            self.compare(baseline(), after, threshold=5.0)
        self.assertIn('same target', str(ctx.exception))

    def test_toolchain_drift_rejected_by_default(self) -> None:
        after = baseline(build={
            'mode': 'profile',
            'flutter': '3.50.1',
            'dart': '3.14.1',
            'revision': 'bbbbbbb',
        })
        with self.assertRaises(perf.BaselineError):
            self.compare(baseline(), after, threshold=5.0)

    def test_toolchain_drift_allowed_with_flag(self) -> None:
        after = baseline(build={
            'mode': 'profile',
            'flutter': '3.50.1',
            'dart': '3.14.1',
            'revision': 'bbbbbbb',
        })
        report = self.compare(
            baseline(), after, threshold=5.0, allow_toolchain_drift=True)
        self.assertFalse(report.has_regression)

    def test_scenario_filter(self) -> None:
        before = baseline({
            'home_feed_scroll': [run()],
            'live_danmaku': [run(ui_frame_ms_median=10.0)],
        })
        after = baseline({
            'home_feed_scroll': [run(ui_frame_ms_median=20.0)],
            'live_danmaku': [run(ui_frame_ms_median=10.0)],
        })
        report = self.compare(
            before, after, threshold=5.0, scenarios=['live_danmaku'])
        self.assertEqual({row.scenario for row in report.rows}, {'live_danmaku'})
        self.assertFalse(report.has_regression)

    def test_unknown_scenario_filter_rejected(self) -> None:
        with self.assertRaises(perf.BaselineError):
            self.compare(baseline(), baseline(), threshold=5.0,
                         scenarios=['does_not_exist'])

    def test_scenario_only_in_before_warns(self) -> None:
        before = baseline({'home_feed_scroll': [run()], 'video_danmaku': [run()]})
        after = baseline({'home_feed_scroll': [run()]})
        report = self.compare(before, after, threshold=5.0)
        self.assertTrue(any('video_danmaku' in w for w in report.warnings))

    def test_scenario_only_in_after_with_filter_warns_not_errors(self) -> None:
        before = baseline({'home_feed_scroll': [run()]})
        after = baseline({'home_feed_scroll': [run()], 'video_danmaku': [run()]})
        report = self.compare(
            before, after, threshold=5.0, scenarios=['video_danmaku'])
        self.assertEqual(report.rows, ())
        self.assertTrue(any('video_danmaku' in w for w in report.warnings))

    def test_negative_threshold_rejected(self) -> None:
        with self.assertRaises(perf.BaselineError):
            self.compare(baseline(), baseline(), threshold=-1.0)


class RenderTest(unittest.TestCase):
    def report(self):
        before = baseline()
        after = baseline({'home_feed_scroll': [run(ui_frame_ms_median=9.0)]})
        return perf.build_report(
            perf.parse_baseline(before), perf.parse_baseline(after), threshold=5.0)

    def test_table_marks_regression(self) -> None:
        table = perf.format_table(self.report())
        self.assertIn('REGRESSION', table)
        self.assertIn('FAIL', table)

    def test_json_has_no_infinity(self) -> None:
        before = baseline({'home_feed_scroll': [run(missed_frames=0)]})
        after = baseline({'home_feed_scroll': [run(missed_frames=1)]})
        report = perf.build_report(
            perf.parse_baseline(before), perf.parse_baseline(after), threshold=5.0)
        encoded = json.dumps(perf.report_to_dict(report))
        self.assertNotIn('Infinity', encoded)
        decoded = json.loads(encoded)
        row = next(r for r in decoded['rows'] if r['metric'] == 'missed_frames')
        self.assertIsNone(row['delta_percent'])


class CliTest(unittest.TestCase):
    def invoke(self, argv: list[str]) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = perf.main(argv)
        return code, out.getvalue(), err.getvalue()

    def test_exit_zero_when_stable(self) -> None:
        before = write_json(baseline())
        after = write_json(baseline())
        code, out, _ = self.invoke([before, after])
        self.assertEqual(code, 0)
        self.assertIn('PASS', out)

    def test_exit_one_on_regression(self) -> None:
        before = write_json(baseline())
        after = write_json(baseline({'home_feed_scroll': [run(ui_frame_ms_median=9.0)]}))
        code, out, _ = self.invoke([before, after])
        self.assertEqual(code, 1)
        self.assertIn('FAIL', out)

    def test_exit_two_on_invalid_json(self) -> None:
        handle = tempfile.NamedTemporaryFile('w', suffix='.json', delete=False)
        with handle:
            handle.write('not json')
        code, _, err = self.invoke([handle.name, handle.name])
        self.assertEqual(code, 2)
        self.assertIn('is not valid JSON', err)

    def test_json_flag(self) -> None:
        before = write_json(baseline())
        after = write_json(baseline())
        code, out, _ = self.invoke(['--json', before, after])
        self.assertEqual(code, 0)
        payload = json.loads(out)
        self.assertFalse(payload['has_regression'])


if __name__ == '__main__':
    unittest.main()
