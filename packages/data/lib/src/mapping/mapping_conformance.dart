import 'package:meta/meta.dart';

/// One mismatch found while comparing two JSON-like values.
@immutable
final class const MappingDifference({
  required final String path,
  required final Object? expected,
  required final Object? actual,
});

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
      _diff(expected[key], actual[key], childPath, differences);
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
      MappingDifference(path: path, expected: expected, actual: actual),
    );
  }
}

const Object _missing = Object();
