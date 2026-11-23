import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  const mapping = FeedMappingDescriptor(
    itemsPath: r'$.data.list[*]',
    fields: {'id': FieldMapping(path: r'$.id')},
  );

  test('accepts a page-number source with a mapping', () {
    const source = SourceDescriptor(
      id: 'example',
      displayName: 'Example',
      endpoint: 'https://api.example.com/feed',
      pagination: SourcePaginationDescriptor(
        kind: SourcePaginationKind.pageNumber,
        pageParameter: 'page',
        pageSizeParameter: 'page_size',
        defaultPageSize: 20,
      ),
      rateLimit: SourceRateLimitDescriptor(requestsPerMinute: 60, burst: 5),
      mapping: mapping,
    );

    expect(validateSourceDescriptor(source, requiredFields: {'id'}), isEmpty);
  });

  test('reports transport and auth issues', () {
    const source = SourceDescriptor(
      id: ' ',
      displayName: '',
      endpoint: 'http://api.example.com/feed',
      auth: SourceAuthDescriptor(
        kind: SourceAuthKind.customSignature,
        tokenEnvironmentVariable: 'lowercase',
      ),
    );

    final issues = validateSourceDescriptor(source, requiredFields: const {});

    expect(issues, contains('source.id must not be empty'));
    expect(issues, contains('source.displayName must not be empty'));
    expect(issues, contains('source.endpoint must use https'));
    expect(
      issues,
      contains('auth.customSignature requires requiresDartAdapter'),
    );
    expect(
      issues,
      contains('auth.tokenEnvironmentVariable must be an env var name'),
    );
  });

  test('requires the auth-specific field', () {
    const header = SourceDescriptor(
      id: 'header',
      displayName: 'Header',
      endpoint: 'https://api.example.com/feed',
      auth: SourceAuthDescriptor(kind: SourceAuthKind.apiKeyHeader),
    );
    const bearer = SourceDescriptor(
      id: 'bearer',
      displayName: 'Bearer',
      endpoint: 'https://api.example.com/feed',
      auth: SourceAuthDescriptor(kind: SourceAuthKind.bearerToken),
    );

    expect(
      validateSourceDescriptor(header, requiredFields: const {}),
      contains('auth.apiKeyHeader requires headerName'),
    );
    expect(
      validateSourceDescriptor(bearer, requiredFields: const {}),
      contains('auth.bearerToken requires tokenEnvironmentVariable'),
    );
  });

  test('validates continuation-token pagination against the mapping', () {
    const valid = SourceDescriptor(
      id: 'cursor',
      displayName: 'Cursor',
      endpoint: 'https://api.example.com/feed',
      pagination: SourcePaginationDescriptor(
        kind: SourcePaginationKind.continuationToken,
        cursorParameter: 'cursor',
      ),
      mapping: FeedMappingDescriptor(
        itemsPath: r'$.data.list[*]',
        continuationTokenPath: r'$.data.next',
        fields: {'id': FieldMapping(path: r'$.id')},
      ),
    );
    const missing = SourceDescriptor(
      id: 'cursor',
      displayName: 'Cursor',
      endpoint: 'https://api.example.com/feed',
      pagination: SourcePaginationDescriptor(
        kind: SourcePaginationKind.continuationToken,
      ),
      mapping: mapping,
    );

    expect(validateSourceDescriptor(valid, requiredFields: {'id'}), isEmpty);
    expect(
      validateSourceDescriptor(missing, requiredFields: const {}),
      containsAll([
        'pagination.continuationToken requires cursorParameter',
        'pagination.continuationToken requires mapping.continuationTokenPath',
      ]),
    );
  });

  test('validates total-count pagination and rate limits', () {
    const source = SourceDescriptor(
      id: 'counted',
      displayName: 'Counted',
      endpoint: 'https://api.example.com/feed',
      pagination: SourcePaginationDescriptor(
        kind: SourcePaginationKind.totalCount,
        defaultPageSize: 0,
      ),
      rateLimit: SourceRateLimitDescriptor(requestsPerMinute: 0, burst: 0),
      mapping: mapping,
    );

    final issues = validateSourceDescriptor(source, requiredFields: const {});

    expect(
      issues,
      contains(
        'pagination.totalCount requires mapping.totalCountPath and pageSize',
      ),
    );
    expect(issues, contains('pagination.defaultPageSize must be positive'));
    expect(issues, contains('rateLimit.requestsPerMinute must be positive'));
    expect(issues, contains('rateLimit.burst must be positive'));
  });

  test('propagates nested mapping issues', () {
    const source = SourceDescriptor(
      id: 'broken',
      displayName: 'Broken',
      endpoint: 'https://api.example.com/feed',
      mapping: FeedMappingDescriptor(
        itemsPath: ' ',
        fields: {'id': FieldMapping()},
      ),
    );

    expect(
      validateSourceDescriptor(source, requiredFields: {'id'}),
      containsAll([
        'itemsPath must not be empty',
        'field id must set exactly one of path or template',
      ]),
    );
  });
}
