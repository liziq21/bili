import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  test('canonical JSON ignores map key order', () {
    final first = {
      'b': 2,
      'a': {'y': true, 'x': 1},
    };
    final second = {
      'a': {'x': 1, 'y': true},
      'b': 2,
    };

    expect(canonicalJson(first), canonicalJson(second));
    expect(mappingHash(first), mappingHash(second));
  });

  test('schema shape ignores values but detects key and type changes', () {
    final base = {
      'items': [
        {'id': 'a', 'count': 1},
        {'id': 'b', 'count': 2},
      ],
    };
    final sameShape = {
      'items': [
        {'id': 'c', 'count': 99},
      ],
    };
    final changedKey = {
      'items': [
        {'id': 'a', 'views': 1},
      ],
    };
    final changedType = {
      'items': [
        {'id': 'a', 'count': '1'},
      ],
    };

    expect(schemaShape(base), schemaShape(sameShape));
    expect(mappingSchemaHash(base), mappingSchemaHash(sameShape));
    expect(mappingSchemaHash(base), isNot(mappingSchemaHash(changedKey)));
    expect(mappingSchemaHash(base), isNot(mappingSchemaHash(changedType)));
  });

  test('fingerprints are stable eight-character hex strings', () {
    final first = fingerprintJson({'id': 'a', 'count': 1});
    final second = fingerprintJson({'count': 1, 'id': 'a'});

    expect(first.fixtureHash, matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(first.sourceSchemaHash, matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(first.fixtureHash, second.fixtureHash);
    expect(first.sourceSchemaHash, second.sourceSchemaHash);
  });

  test('provenance validation reports malformed metadata', () {
    const descriptor = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      fields: {'id': FieldMapping(path: r'$.id')},
      provenance: MappingProvenance(
        generatedBy: ' ',
        promptVersion: '',
        generatedAt: '23/11/2026',
        reviewer: '',
        fixtureHash: 'XYZ',
        sourceSchemaHash: '123',
      ),
    );

    final issues = validateFeedMappingDescriptor(
      descriptor,
      requiredFields: const {},
      requireProvenance: true,
      requireFingerprint: true,
    );

    expect(issues, contains('provenance.generatedBy must not be empty'));
    expect(issues, contains('provenance.promptVersion must not be empty'));
    expect(issues, contains('provenance.generatedAt must be YYYY-MM-DD'));
    expect(issues, contains('provenance.reviewer must not be empty'));
    expect(
      issues,
      contains('provenance.fixtureHash must be 8 lowercase hex chars'),
    );
    expect(
      issues,
      contains('provenance.sourceSchemaHash must be 8 lowercase hex chars'),
    );
  });

  test('provenance is optional unless required', () {
    const descriptor = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      fields: {'id': FieldMapping(path: r'$.id')},
    );

    expect(
      validateFeedMappingDescriptor(descriptor, requiredFields: const {}),
      isEmpty,
    );
    expect(
      validateFeedMappingDescriptor(
        descriptor,
        requiredFields: const {},
        requireProvenance: true,
      ),
      contains('provenance is required'),
    );
  });
}
