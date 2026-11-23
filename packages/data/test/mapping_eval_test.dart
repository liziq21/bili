import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  test('reports exact item and field matches', () {
    final report = evaluateMappingCandidates(
      expected: [
        {'id': 'a', 'title': 'A'},
      ],
      actual: [
        {'id': 'a', 'title': 'A'},
      ],
    );

    expect(report.passes, isTrue);
    expect(report.exactItems, 1);
    expect(report.itemExactMatchRate, 1);
    expect(report.matchedFields, 2);
    expect(report.expectedFields, 2);
    expect(report.fieldExactMatchRate, 1);
  });

  test('reports field and item differences', () {
    final report = evaluateMappingCandidates(
      expected: [
        {'id': 'a', 'title': 'A'},
        {'id': 'b', 'title': 'B'},
      ],
      actual: [
        {'id': 'a', 'title': 'wrong'},
        {'id': 'c', 'title': 'B'},
        {'id': 'd', 'title': 'D'},
      ],
    );

    expect(report.passes, isFalse);
    expect(report.expectedItems, 2);
    expect(report.actualItems, 3);
    expect(report.exactItems, 0);
    expect(report.matchedFields, 2);
    expect(report.expectedFields, 4);
    expect(
      report.differences.map((difference) => difference.path),
      containsAll([r'$[0].title', r'$[1].id', r'$[2]']),
    );
  });

  test('scores missing items as failures', () {
    final report = evaluateMappingCandidates(
      expected: [
        {'id': 'a'},
        {'id': 'b'},
      ],
      actual: [
        {'id': 'a'},
      ],
    );

    expect(report.passes, isFalse);
    expect(report.exactItems, 1);
    expect(report.itemExactMatchRate, 0.5);
    expect(report.differences.single.path, r'$[1]');
  });

  test('serializes a repair request with missing-value flags', () {
    final differences = diffJson({'id': 'a'}, const <String, Object?>{});
    final request = buildMappingRepairRequest(
      feedId: 'popular',
      fixturePath: 'fixture.json',
      goldenPath: 'golden.json',
      descriptorFile: 'descriptor.dart',
      differences: differences,
      requiredFields: const {'id', 'title'},
      schemaVersion: 1,
    );

    final json = request.toJson();

    expect(json['feedId'], 'popular');
    expect(json['requiredFields'], ['id', 'title']);
    expect(json['differenceCount'], 1);
    final difference =
        (json['differences'] as List).single as Map<String, Object?>;
    expect(difference['path'], r'$.id');
    expect(difference['actual'], isNull);
    expect(difference['actualMissing'], isTrue);
    expect(difference['expected'], 'a');
  });
}
