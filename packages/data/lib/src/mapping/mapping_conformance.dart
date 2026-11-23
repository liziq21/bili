import 'package:meta/meta.dart';

/// One mismatch found while comparing two JSON-like values.
@immutable
final class const MappingDifference({
  required final String path,
  required final Object? expected,
  required final Object? actual,
  final bool expectedMissing = false,
  final bool actualMissing = false,
}) {
  Map<String, Object?> toJson() => {
    'path': path,
    'expected': expectedMissing ? null : _jsonSafe(expected),
    'actual': actualMissing ? null : _jsonSafe(actual),
    'expectedMissing': expectedMissing,
    'actualMissing': actualMissing,
  };
}

/// Returns every difference between [expected] and [actual], in traversal order.
///
/// The comparison is structural: maps compare by key, lists by index, and
/// scalars by `==`. It is intentionally independent of a source package so the
/// same check can be used by tests and command-line conformance tools.
List<MappingDifference> diffJson(Object? expected, Object? actual) {
  final differences = <MappingDifference>[];
  _diff(expected, actual, r'$', differences);
  return differences;
}

void _diff(
  Object? expected,
  Object? actual,
  String path,
  List<MappingDifference> differences,
) {
  if (expected is Map && actual is Map) {
    final keys = <Object?>{...expected.keys, ...actual.keys};
    for (final key in keys) {
      final childPath = key is String ? '$path.$key' : '$path[$key]';
      _diff(
        expected.containsKey(key) ? expected[key] : _missing,
        actual.containsKey(key) ? actual[key] : _missing,
        childPath,
        differences,
      );
    }
    return;
  }

  if (expected is List && actual is List) {
    final length = expected.length > actual.length
        ? expected.length
        : actual.length;
    for (var index = 0; index < length; index++) {
      _diff(
        index < expected.length ? expected[index] : _missing,
        index < actual.length ? actual[index] : _missing,
        '$path[$index]',
        differences,
      );
    }
    return;
  }

  if (expected != actual) {
    differences.add(
      MappingDifference(
        path: path,
        expected: expected,
        actual: actual,
        expectedMissing: identical(expected, _missing),
        actualMissing: identical(actual, _missing),
      ),
    );
  }
}

const Object _missing = Object();

Object? _jsonSafe(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is List) return [for (final item in value) _jsonSafe(item)];
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _jsonSafe(entry.value),
    };
  }
  return value.toString();
}
