import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  const valid = FeedMappingDescriptor(
    itemsPath: r'$.data.list[*]',
    successCodePath: r'$.code',
    successCode: 0,
    fields: {
      'id': FieldMapping(path: r'$.id'),
      'title': FieldMapping(path: r'$.title', fallbackPath: r'$.id'),
      'url': FieldMapping(path: r'$.id', transform: 'httpsUrl'),
    },
  );

  test('accepts a complete descriptor', () {
    expect(
      validateFeedMappingDescriptor(
        valid,
        requiredFields: {'id', 'title', 'url'},
      ),
      isEmpty,
    );
  });

  test('reports missing fields and malformed field mappings', () {
    const broken = FeedMappingDescriptor(
      itemsPath: ' ',
      schemaVersion: 0,
      fields: {
        'id': FieldMapping(),
        'title': FieldMapping(path: r'$.title', template: 'x'),
      },
    );

    final issues = validateFeedMappingDescriptor(
      broken,
      requiredFields: {'id', 'title', 'url'},
    );

    expect(issues, contains('itemsPath must not be empty'));
    expect(issues, contains('schemaVersion must be >= 1'));
    expect(issues, contains('missing required field: url'));
    expect(
      issues,
      contains('field id must set exactly one of path or template'),
    );
    expect(
      issues,
      contains('field title must set exactly one of path or template'),
    );
  });

  test('reports empty field descriptions and examples', () {
    const descriptor = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      fields: {
        'id': FieldMapping(
          path: r'$.id',
          description: ' ',
          examples: ['ok', ''],
        ),
      },
    );

    final issues = validateFeedMappingDescriptor(
      descriptor,
      requiredFields: const {},
    );

    expect(issues, contains('field id has an empty description'));
    expect(issues, contains('field id has an empty example'));
  });

  test('reports contradictory pagination and envelope settings', () {
    const broken = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      hasMorePath: r'$.data.has_more',
      totalCountPath: r'$.data.count',
      pageSize: 0,
      successCodePath: r'$.code',
      fields: {'id': FieldMapping(path: r'$.id')},
    );
    const missingPageSize = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      totalCountPath: r'$.data.count',
      fields: {'id': FieldMapping(path: r'$.id')},
    );

    final issues = validateFeedMappingDescriptor(
      broken,
      requiredFields: const {},
    );
    final pairingIssues = validateFeedMappingDescriptor(
      missingPageSize,
      requiredFields: const {},
    );

    expect(issues, contains('pageSize must be positive'));
    expect(
      issues,
      contains('hasMorePath and totalCountPath are mutually exclusive'),
    );
    expect(
      issues,
      contains('successCode and successCodePath must be set together'),
    );
    expect(
      pairingIssues,
      contains('totalCountPath and pageSize must be set together'),
    );
  });

  test('reports contradictory continuation-token settings', () {
    const broken = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      hasMorePath: r'$.data.has_more',
      continuationTokenPath: ' ',
      fields: {'id': FieldMapping(path: r'$.id')},
    );

    final issues = validateFeedMappingDescriptor(
      broken,
      requiredFields: const {},
    );

    expect(issues, contains('continuationTokenPath must not be empty'));
    expect(
      issues,
      contains('continuationTokenPath and hasMorePath are mutually exclusive'),
    );
  });
}
