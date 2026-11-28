#!/usr/bin/env python3
"""Compare two profile-mode performance baselines.

Each baseline is a JSON document described in ``docs/performance-baseline.md``.
The tool validates both files, checks that they were captured on a compatible
target, aggregates repeated runs per scenario, and reports the percentage
change of every "lower is better" metric. It exits non-zero when a metric
regresses beyond a tolerance.

Usage:
    python3 tool/compare_perf_baselines.py BEFORE.json AFTER.json
    python3 tool/compare_perf_baselines.py BEFORE.json AFTER.json --threshold 3
    python3 tool/compare_perf_baselines.py BEFORE.json AFTER.json --json
    python3 tool/compare_perf_baselines.py BEFORE.json AFTER.json \
        --scenario home_feed_scroll --scenario live_danmaku

Exit codes:
    0  no regression beyond the threshold
    1  at least one metric regressed beyond the threshold
    2  invalid input or incompatible baselines

The tool only compares numbers; it never collects measurements. See
``docs/performance-baseline.md`` for how to capture a baseline.
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

SCHEMA_VERSION = 1

# All metrics are "lower is better".
METRICS: tuple[str, ...] = (
    'ui_frame_ms_median',
    'ui_frame_ms_p90',
    'raster_frame_ms_median',
    'raster_frame_ms_p90',
    'missed_frames',
)

_TARGET_FIELDS = ('device', 'os', 'display_refresh_hz', 'viewport', 'text_scale')
_RUN_FIELDS = METRICS
_MIN_RUNS = 3
# Absorbs binary floating-point error so a change that is exactly at the
# threshold (e.g. 8.0 -> 8.4 ms = 5.000000000000004%) is not a regression.
_THRESHOLD_EPSILON = 1e-9


class BaselineError(ValueError):
    """Raised when a baseline document does not satisfy the schema."""


@dataclass(frozen=True)
class Run:
    metrics: Mapping[str, float]


@dataclass(frozen=True)
class Scenario:
    runs: tuple[Run, ...]
    duration_seconds: float | None = None
    warmup_seconds: float | None = None

    def median(self, metric: str) -> float:
        return float(statistics.median(run.metrics[metric] for run in self.runs))

    def spread(self, metric: str) -> float:
        values = [run.metrics[metric] for run in self.runs]
        return float(max(values) - min(values))


@dataclass(frozen=True)
class Baseline:
    target: Mapping[str, Any]
    build: Mapping[str, Any]
    scenarios: Mapping[str, Scenario]
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class Row:
    scenario: str
    metric: str
    before: float
    after: float
    delta_percent: float
    before_spread: float
    after_spread: float
    regression: bool


@dataclass(frozen=True)
class Report:
    rows: tuple[Row, ...]
    warnings: tuple[str, ...]
    threshold: float

    @property
    def has_regression(self) -> bool:
        return any(row.regression for row in self.rows)


def _require_mapping(value: Any, where: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise BaselineError(f'{where} must be a JSON object')
    return value


def _require_str(mapping: Mapping[str, Any], key: str, where: str) -> str:
    value = mapping.get(key)
    if not isinstance(value, str) or not value.strip():
        raise BaselineError(f'{where}.{key} must be a non-empty string')
    return value


def _require_number(value: Any, where: str, *, positive: bool) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise BaselineError(f'{where} must be a number')
    number = float(value)
    if not math.isfinite(number):
        raise BaselineError(f'{where} must be finite')
    if number < 0 or (positive and number == 0):
        comparator = '> 0' if positive else '>= 0'
        raise BaselineError(f'{where} must be {comparator}')
    return number


def _optional_number(value: Any, where: str, *, positive: bool) -> float | None:
    if value is None:
        return None
    return _require_number(value, where, positive=positive)


def _parse_target(raw: Any) -> Mapping[str, Any]:
    target = _require_mapping(raw, 'target')
    parsed: dict[str, Any] = {
        'device': _require_str(target, 'device', 'target'),
        'os': _require_str(target, 'os', 'target'),
        'viewport': _require_str(target, 'viewport', 'target'),
        'display_refresh_hz': _require_number(
            target.get('display_refresh_hz'), 'target.display_refresh_hz', positive=True),
        'text_scale': _require_number(
            target.get('text_scale'), 'target.text_scale', positive=True),
    }
    return parsed


def _parse_build(raw: Any) -> Mapping[str, Any]:
    build = _require_mapping(raw, 'build')
    mode = _require_str(build, 'mode', 'build')
    if mode != 'profile':
        raise BaselineError(
            f"build.mode must be 'profile' (debug/widget-test timings cannot "
            f'substantiate performance claims); got {mode!r}')
    parsed: dict[str, Any] = {
        'mode': mode,
        'flutter': _require_str(build, 'flutter', 'build'),
        'dart': _require_str(build, 'dart', 'build'),
        'revision': _require_str(build, 'revision', 'build'),
    }
    return parsed


def _parse_scenarios(raw: Any, warnings: list[str]) -> dict[str, Scenario]:
    scenarios = _require_mapping(raw, 'scenarios')
    if not scenarios:
        raise BaselineError('scenarios must contain at least one scenario')

    parsed: dict[str, Scenario] = {}
    for name, body in scenarios.items():
        if not isinstance(name, str) or not name:
            raise BaselineError('scenario names must be non-empty strings')
        scenario = _require_mapping(body, f'scenarios.{name}')
        runs_raw = scenario.get('runs')
        if not isinstance(runs_raw, list) or not runs_raw:
            raise BaselineError(f'scenarios.{name}.runs must be a non-empty list')
        if len(runs_raw) < _MIN_RUNS:
            warnings.append(
                f'scenarios.{name} has {len(runs_raw)} run(s); the protocol '
                f'asks for at least {_MIN_RUNS} to show variability')

        runs: list[Run] = []
        for index, run_raw in enumerate(runs_raw):
            run = _require_mapping(run_raw, f'scenarios.{name}.runs[{index}]')
            metrics: dict[str, float] = {}
            for metric in _RUN_FIELDS:
                if metric not in run:
                    raise BaselineError(
                        f'scenarios.{name}.runs[{index}] is missing {metric}')
                metrics[metric] = _require_number(
                    run[metric], f'scenarios.{name}.runs[{index}].{metric}',
                    positive=False)
            runs.append(Run(metrics=metrics))

        parsed[name] = Scenario(
            runs=tuple(runs),
            duration_seconds=_optional_number(
                scenario.get('duration_seconds'),
                f'scenarios.{name}.duration_seconds', positive=True),
            warmup_seconds=_optional_number(
                scenario.get('warmup_seconds'),
                f'scenarios.{name}.warmup_seconds', positive=False),
        )

    return parsed


def parse_baseline(data: Any) -> Baseline:
    """Validate a parsed JSON document and return a :class:`Baseline`."""
    root = _require_mapping(data, 'baseline')
    version = root.get('schema_version')
    if isinstance(version, bool) or version != SCHEMA_VERSION:
        raise BaselineError(
            f'schema_version must be {SCHEMA_VERSION}; got {version!r}')

    warnings: list[str] = []
    target = _parse_target(root.get('target'))
    build = _parse_build(root.get('build'))
    scenarios = _parse_scenarios(root.get('scenarios'), warnings)
    return Baseline(
        target=target, build=build, scenarios=scenarios,
        warnings=tuple(warnings))


def load_baseline(path: str | Path) -> Baseline:
    """Read and validate a baseline file."""
    try:
        text = Path(path).read_text(encoding='utf-8')
    except OSError as error:
        raise BaselineError(f'cannot read {path}: {error}') from error
    try:
        data = json.loads(text)
    except json.JSONDecodeError as error:
        raise BaselineError(f'{path} is not valid JSON: {error}') from error
    return parse_baseline(data)


def _check_compatible(before: Baseline, after: Baseline,
                      allow_toolchain_drift: bool) -> None:
    for field in _TARGET_FIELDS:
        if before.target[field] != after.target[field]:
            raise BaselineError(
                f'target.{field} differs ({before.target[field]!r} vs '
                f'{after.target[field]!r}); capture both sides on the same target')
    if not allow_toolchain_drift:
        for field in ('flutter', 'dart'):
            if before.build[field] != after.build[field]:
                raise BaselineError(
                    f'build.{field} differs ({before.build[field]!r} vs '
                    f'{after.build[field]!r}); re-capture or pass '
                    f'--allow-toolchain-drift and explain it in the PR')


def _delta_percent(before: float, after: float) -> float:
    if before == 0:
        return 0.0 if after == 0 else math.inf
    return (after - before) / before * 100.0


def _check_sample_length(name: str, before: Scenario, after: Scenario,
                         warnings: list[str]) -> None:
    """Reject known sample-length mismatches so raw counts stay comparable."""
    before_duration, after_duration = before.duration_seconds, after.duration_seconds
    if before_duration is not None and after_duration is not None:
        if abs(before_duration - after_duration) > _THRESHOLD_EPSILON:
            raise BaselineError(
                f'scenario {name!r} duration_seconds differs '
                f'({before_duration:g}s vs {after_duration:g}s); sample the same '
                f'duration on both sides or frame counts are not comparable')
    elif before_duration is None and after_duration is None:
        warnings.append(
            f'scenario {name!r} does not record duration_seconds; '
            f'cannot verify both sides sampled the same length')
    else:
        warnings.append(
            f'scenario {name!r} records duration_seconds on only one side; '
            f'cannot verify both sides sampled the same length')


def build_report(before: Baseline, after: Baseline, *,
                 threshold: float,
                 allow_toolchain_drift: bool = False,
                 scenarios: Iterable[str] | None = None) -> Report:
    """Compare two baselines, raising :class:`BaselineError` if incompatible."""
    _check_compatible(before, after, allow_toolchain_drift)
    if not math.isfinite(threshold) or threshold < 0:
        raise BaselineError('threshold must be finite and >= 0')

    selected = set(scenarios) if scenarios else None
    warnings: list[str] = list(before.warnings)
    warnings.extend(w for w in after.warnings if w not in warnings)
    rows: list[Row] = []

    for name in before.scenarios:
        if selected is not None and name not in selected:
            continue
        if name not in after.scenarios:
            warnings.append(f'scenario {name!r} is only in the before baseline; skipped')
            continue
        before_scenario = before.scenarios[name]
        after_scenario = after.scenarios[name]
        _check_sample_length(name, before_scenario, after_scenario, warnings)
        for metric in METRICS:
            before_value = before_scenario.median(metric)
            after_value = after_scenario.median(metric)
            delta = _delta_percent(before_value, after_value)
            rows.append(Row(
                scenario=name,
                metric=metric,
                before=before_value,
                after=after_value,
                delta_percent=delta,
                before_spread=before_scenario.spread(metric),
                after_spread=after_scenario.spread(metric),
                regression=_is_regression(delta, threshold),
            ))

    for name in after.scenarios:
        if selected is not None and name not in selected:
            continue
        if name not in before.scenarios:
            warnings.append(f'scenario {name!r} is only in the after baseline; skipped')

    if selected is not None:
        known = set(before.scenarios) | set(after.scenarios)
        missing = selected - known
        if missing:
            raise BaselineError(
                f'unknown scenario(s) for --scenario: {", ".join(sorted(missing))}')

    return Report(rows=tuple(rows), warnings=tuple(warnings), threshold=threshold)


def _is_regression(delta_percent: float, threshold: float) -> bool:
    if math.isinf(delta_percent):
        return True
    return delta_percent - threshold > _THRESHOLD_EPSILON


def _format_delta(row: Row) -> str:
    if math.isinf(row.delta_percent):
        return '+inf%'
    return f'{row.delta_percent:+.1f}%'


def format_table(report: Report) -> str:
    """Render a human-readable comparison table."""
    if not report.rows:
        return 'No overlapping scenarios to compare.\n'

    header = (
        f'{"scenario":<20} {"metric":<24} {"before":>9} {"after":>9} '
        f'{"delta":>9} {"before±":>9} {"after±":>9}  status')
    lines = [header, '-' * len(header)]
    for row in report.rows:
        status = 'REGRESSION' if row.regression else 'ok'
        lines.append(
            f'{row.scenario:<20} {row.metric:<24} '
            f'{row.before:>9.2f} {row.after:>9.2f} {_format_delta(row):>9} '
            f'{row.before_spread:>9.2f} {row.after_spread:>9.2f}  {status}')
    lines.append('')
    lines.append(
        f'threshold: +{report.threshold:g}% regression => '
        f'{"FAIL" if report.has_regression else "PASS"}')
    for warning in report.warnings:
        lines.append(f'warning: {warning}')
    return '\n'.join(lines) + '\n'


def report_to_dict(report: Report) -> dict[str, Any]:
    """Render a machine-readable comparison report."""
    return {
        'threshold_percent': report.threshold,
        'has_regression': report.has_regression,
        'rows': [
            {
                'scenario': row.scenario,
                'metric': row.metric,
                'before': row.before,
                'after': row.after,
                'delta_percent': (
                    None if math.isinf(row.delta_percent) else round(row.delta_percent, 4)
                ),
                'before_spread': row.before_spread,
                'after_spread': row.after_spread,
                'regression': row.regression,
            }
            for row in report.rows
        ],
        'warnings': list(report.warnings),
    }


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='Compare two profile-mode performance baselines.')
    parser.add_argument('before', help='baseline captured before the change')
    parser.add_argument('after', help='baseline captured after the change')
    parser.add_argument(
        '--threshold', type=float, default=5.0,
        help='regression tolerance in percent of the before median (default: 5.0)')
    parser.add_argument(
        '--scenario', action='append', dest='scenarios', metavar='NAME',
        help='only compare this scenario (repeatable)')
    parser.add_argument(
        '--allow-toolchain-drift', action='store_true',
        help='allow Flutter/Dart version differences; explain it in the PR')
    parser.add_argument(
        '--json', action='store_true', help='print a JSON report instead of a table')
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        before = load_baseline(args.before)
        after = load_baseline(args.after)
        report = build_report(
            before, after,
            threshold=args.threshold,
            allow_toolchain_drift=args.allow_toolchain_drift,
            scenarios=args.scenarios)
    except BaselineError as error:
        print(f'error: {error}', file=sys.stderr)
        return 2

    if not report.rows:
        print(
            'error: no scenarios were compared; before and after baselines '
            'share no scenario',
            file=sys.stderr)
        for warning in report.warnings:
            print(f'warning: {warning}', file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(report_to_dict(report), indent=2, sort_keys=True))
    else:
        sys.stdout.write(format_table(report))
    return 1 if report.has_regression else 0


if __name__ == '__main__':
    sys.exit(main())
