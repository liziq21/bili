import 'package:app/data/repository/playlist_content_repository.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// 按页返回固定内容的 fake 数据源，记录每次请求的页号。
final class _FakePlaylistContentDataSource({
  final List<Page<PlaylistDetail>>? pages,
  final List<int> failingPages = const [],
}) implements PlaylistContentRemoteDataSource {
  int requestCount = 0;
  final requestedPages = <int>[];

  @override
  String get sourceId => 'fake';

  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestCount++;
    requestedPages.add(page);
    if (failingPages.contains(page)) {
      return Result.error(Exception('page $page failed'));
    }
    final allPages = pages ?? const <Page<PlaylistDetail>>[];
    if (page < 1 || page > allPages.length) {
      return Result.error(Exception('page $page out of range'));
    }
    return Result.success(allPages[page - 1]);
  }
}

Page<PlaylistDetail> _page({
  required int number,
  required int totalPages,
  required List<String> videoIds,
  String title = 'Playlist',
}) => Page<PlaylistDetail>(
  number: number,
  totalPages: totalPages,
  data: [
    PlaylistDetail(
      id: '2:12345',
      title: title,
      items: [
        for (final id in videoIds)
          VideoModel(
            id: id,
            title: 'Video $id',
            url: 'https://www.bilibili.com/video/$id',
          ),
      ],
    ),
  ],
);

void main() {
  group('AppPlaylistContentRepository', () {
    test('fetches a single page through the capability', () async {
      final dataSource = _FakePlaylistContentDataSource(
        pages: [
          _page(number: 1, totalPages: 1, videoIds: const ['BV1']),
        ],
      );
      final repository = AppPlaylistContentRepository(dataSource);

      final result = await repository.fetchPlaylistContent(
        playlistId: '2:12345',
        page: 1,
        pageSize: 10,
      );

      expect(result.isSuccess(), isTrue);
      expect(dataSource.requestedPages, [1]);
      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      expect(page.data.single.title, 'Playlist');
    });

    test('reports an error when the capability is missing', () async {
      final repository = AppPlaylistContentRepository();

      final pageResult = await repository.fetchPlaylistContent(
        playlistId: '2:12345',
      );
      final fullResult = await repository.fetchAll(playlistId: '2:12345');

      expect(pageResult.isError(), isTrue);
      expect(fullResult.completed, isFalse);
      expect(fullResult.items, isEmpty);
      expect(fullResult.error, isNotNull);
    });

    test('fetches every page and reports the final item count', () async {
      final dataSource = _FakePlaylistContentDataSource(
        pages: [
          _page(number: 1, totalPages: 2, videoIds: const ['BV1', 'BV2']),
          _page(number: 2, totalPages: 2, videoIds: const ['BV3']),
        ],
      );
      final repository = AppPlaylistContentRepository(dataSource);
      final progress = <int>[];

      final result = await repository.fetchAll(
        playlistId: '2:12345',
        onProgress: progress.add,
      );

      expect(result.completed, isTrue);
      expect(result.items.map((item) => item.id), ['BV1', 'BV2', 'BV3']);
      expect(result.nextPage, isNull);
      expect(progress, [3]);
      expect(dataSource.requestedPages, [1, 2]);
    });

    test('keeps the fetched prefix when a page fails twice', () async {
      final dataSource = _FakePlaylistContentDataSource(
        pages: [
          _page(number: 1, totalPages: 2, videoIds: const ['BV1']),
          _page(number: 2, totalPages: 2, videoIds: const ['BV2']),
        ],
        failingPages: const [2],
      );
      final repository = AppPlaylistContentRepository(dataSource);

      final result = await repository.fetchAll(playlistId: '2:12345');

      expect(result.completed, isFalse);
      expect(result.items.map((item) => item.id), ['BV1']);
      expect(result.nextPage, 2);
      expect(result.error, isNotNull);
      // 失败页被重试一次后放弃。
      expect(dataSource.requestedPages, [1, 2, 2]);
    });
  });
}
