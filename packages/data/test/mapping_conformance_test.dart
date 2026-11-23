import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  test('reports no differences for equal JSON', () {
    final value = {
      'items': [
        {'id': 'a', 'count': 1},
      ],
    };

    expect(diffJson(value, value), isEmpty);
  });

  test('reports nested value, missing key and list length differences', () {
    final expected = {
      'items': [
        {'id': 'a', 'count': 1},
        {'id': 'b', 'count': 2},
      ],
    };
    final actual = {
      'items': [
        {'id': 'a', 'count': 9},
      ],
    };

    final differences = diffJson(expected, actual);

    expect(
      differences.map((difference) => difference.path),
      containsAll([r'$.items[0].count', r'$.items[1]']),
    );
  });

  test('reports type mismatches', () {
    final differences = diffJson({'value': '1'}, {'value': 1});

    expect(differences, hasLength(1));
    expect(differences.single.path, r'$.value');
    expect(differences.single.expected, '1');
    expect(differences.single.actual, 1);
  });
}
