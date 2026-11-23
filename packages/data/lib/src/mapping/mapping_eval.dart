import 'package:meta/meta.dart';

import 'mapping_conformance.dart';

/// Model-agnostic quality report for candidate canonical items.
///
/// This is the scoring surface for a quarterly model/prompt review: any model
/// can produce candidate JSON, but only exact item/field matches count.
@immutable
final class const MappingEvalReport({
  required final int expectedItems,
  required final int actualItems,
  required final int exactItems,
  required final int matchedFields,
  required final int expectedFields,
  required final List<MappingDifference> differences,
}) {
  double get itemExactMatchRate =>
      expectedItems == 0 ? 0 : exactItems / expectedItems;

  double get fieldExactMatchRate =>
      expectedFields == 0 ? 0 : matchedFields / expectedFields;

  bool get passes => differences.isEmpty;

  Map<String, Object?> toJson() => {
    'expectedItems': expectedItems,
    'actualItems': actualItems,
    'exactItems': exactItems,
    'itemExactMatchRate': itemExactMatchRate,
    'matchedFields': matchedFields,
    'expectedFields': expectedFields,
    'fieldExactMatchRate': fieldExactMatchRate,
    'passes': passes,
    'differenceCount': differences.length,
    'differences': [for (final difference in differences) difference.toJson()],
  };
}

/// Compares candidate canonical items against the expected golden.
MappingEvalReport evaluateMappingCandidates({
  required List<Map<String, Object?>> expected,
  required List<Map<String, Object?>> actual,
}) {
  var exactItems = 0;
  var matchedFields = 0;
  var expectedFields = 0;

  for (var index = 0; index < expected.length; index++) {
    final expectedItem = expected[index];
    final actualItem = index < actual.length
        ? actual[index]
        : const <String, Object?>{};
    if (index < actual.length && diffJson(expectedItem, actualItem).isEmpty) {
      exactItems++;
    }
    final keys = <String>{...expectedItem.keys, ...actualItem.keys};
    expectedFields += keys.length;
    for (final key in keys) {
      if (expectedItem.containsKey(key) &&
          actualItem.containsKey(key) &&
          expectedItem[key] == actualItem[key]) {
        matchedFields++;
      }
    }
  }

  return MappingEvalReport(
    expectedItems: expected.length,
    actualItems: actual.length,
    exactItems: exactItems,
    matchedFields: matchedFields,
    expectedFields: expectedFields,
    differences: diffJson(expected, actual),
  );
}
