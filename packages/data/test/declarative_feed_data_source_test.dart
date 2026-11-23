import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> feedJson({bool noMore = false}) => {
    'code': 0,
    'message': 'OK',
    'data': {
      'no_more': noMore,
      'list': [
        {
          'id': 'v1',
          'title': 'Hello <em>World</em>',
          'cover': '//img.example/1.jpg',
          'count': '1.2K',
          'published': 1700000000,
          'length': '01:02',
          'owner': {'name': 'Alice', 'id': 42},
        },
        {
          'id': 'v2',
          'title': 'Second',
          'cover': 'http://img.example/2.jpg',
          'count': '3万',
          'published': '1700000100',
          'length': 75,
          'owner': {'name': 'Bob', 'id': '43'},
        },
      ],
    },
  };

  const descriptor = FeedMappingDescriptor(
    itemsPath: r'$.data.list[*]',
    successCodePath: r'$.code',
    successCode: 0,
    messagePath: r'$.message',
    hasMorePath: r'$.data.no_more',
    hasMoreWhen: false,
    fields: {
      'id': FieldMapping(path: r'$.id'),
      'title': FieldMapping(
        path: r'$.title',
        fallbackPath: r'$.id',
        transform: 'htmlText',
      ),
      'thumbnailUrl': FieldMapping(path: r'$.cover', transform: 'httpsUrl'),
      'viewCount': FieldMapping(path: r'$.count', transform: 'parseCount'),
      'uploadDate': FieldMapping(
        path: r'$.published',
        transform: 'epochSeconds',
      ),
      'duration': FieldMapping(path: r'$.length', transform: 'parseDuration'),
      'creatorName': FieldMapping(path: r'$.owner.name'),
      'creatorId': FieldMapping(path: r'$.owner.id', transform: 'string'),
    },
  );

  VideoModel? build(Map<String, Object?> item) {
    final id = item['id'] as String?;
    if (id == null) return null;
    return VideoModel(
      id: id,
      title: item['title']! as String,
      url: 'https://example.com/$id',
      thumbnailUrl: item['thumbnailUrl'] as String?,
      viewCount: item['viewCount'] as int?,
      uploadDate: item['uploadDate'] as DateTime?,
      duration: item['duration'] as int?,
      creatorProfileName: item['creatorName'] as String?,
      creatorProfileId: item['creatorId'] as String?,
    );
  }

  DeclarativeFeedDataSource<VideoModel> source(
    Map<String, dynamic> json, {
    FeedMappingDescriptor mapping = descriptor,
    MappingTransformRegistry? transforms,
  }) => DeclarativeFeedDataSource<VideoModel>(
    sourceId: 'test',
    id: 'feed',
    title: 'Feed',
    descriptor: mapping,
    fetchJson: ({int? pageKey}) async => json,
    buildItem: build,
    transforms: transforms,
  );

  test('maps a feed page with deterministic transforms', () async {
    final result = await source(feedJson()).fetchFeed();
    final page = switch (result) {
      Success(:final success) => success,
      Error(:final error) => fail('expected success: $error'),
    };

    expect(page.number, 1);
    expect(page.totalPages, 2);
    expect(page.data, hasLength(2));

    final first = page.data.first;
    expect(first.id, 'v1');
    expect(first.title, 'Hello World');
    expect(first.thumbnailUrl, 'https://img.example/1.jpg');
    expect(first.viewCount, 1200);
    expect(
      first.uploadDate,
      DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    expect(first.duration, 62);
    expect(first.creatorProfileName, 'Alice');
    expect(first.creatorProfileId, '42');

    final second = page.data[1];
    expect(second.thumbnailUrl, 'https://img.example/2.jpg');
    expect(second.viewCount, 30000);
    expect(
      second.uploadDate,
      DateTime.fromMillisecondsSinceEpoch(1700000100000),
    );
    expect(second.duration, 75);
  });

  test('marks the last page when no_more is true', () async {
    final result = await source(feedJson(noMore: true)).fetchFeed(pageKey: 3);
    final page = switch (result) {
      Success(:final success) => success,
      Error(:final error) => fail('expected success: $error'),
    };

    expect(page.number, 3);
    expect(page.totalPages, 3);
  });

  test('returns Result.error when the envelope fails', () async {
    final result = await source({
      'code': 7,
      'message': 'blocked',
      'data': {'list': <Object?>[]},
    }).fetchFeed();

    expect(result.isError(), isTrue);
    final error = switch (result) {
      Error(:final error) => error,
      Success() => fail('expected an error'),
    };
    expect(error.toString(), contains('blocked'));
  });

  test('drops items the builder rejects', () async {
    final result = await source({
      'code': 0,
      'message': 'OK',
      'data': {
        'no_more': true,
        'list': [
          {'id': 'ok', 'title': 'ok'},
          {'title': 'missing id'},
        ],
      },
    }).fetchFeed();
    final page = switch (result) {
      Success(:final success) => success,
      Error(:final error) => fail('expected success: $error'),
    };

    expect(page.data.map((video) => video.id), ['ok']);
  });

  test('returns Result.error for an unknown transform', () async {
    const bad = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      fields: {'id': FieldMapping(path: r'$.id', transform: 'missing')},
    );

    final result = await source(feedJson(), mapping: bad).fetchFeed();

    expect(result.isError(), isTrue);
  });

  test('exposes the canonical schema version', () {
    expect(descriptor.schemaVersion, VideoModel.schemaVersion);
    expect(source(feedJson()).schemaVersion, VideoModel.schemaVersion);

    const next = FeedMappingDescriptor(
      itemsPath: r'$.data.list[*]',
      schemaVersion: 2,
      fields: {},
    );
    expect(next.schemaVersion, 2);
  });

  test('reads JSON paths', () {
    final json = {
      'data': {
        'list': [
          {'id': 1},
          {'id': 2},
        ],
      },
      'flag': false,
    };

    expect(readJsonPath(json, r'$.data.list[1].id'), 2);
    expect(readJsonPathAll(json, r'$.data.list[*]'), hasLength(2));
    expect(readJsonPath(json, r'$.missing.path'), isNull);
    expect(readJsonPathAll(json, r'$.missing[*]'), isEmpty);
  });
}
