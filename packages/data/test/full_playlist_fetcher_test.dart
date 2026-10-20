import 'package:data/data.dart';
import 'package:test/test.dart';

final class _PlaylistItem(final String id);

Page<_PlaylistItem> _page(int number, int totalPages, List<String> ids) => Page(
  number: number,
  totalPages: totalPages,
  data: ids.map(_PlaylistItem.new).toList(),
);

void main() {
  test(
    'fetches every page and keeps the first occurrence of duplicates',
    () async {
      final requestedPages = <int?>[];

      final result = await fetchFullPlaylist<_PlaylistItem>(
        fetchPage: ({int? pageKey}) async {
          requestedPages.add(pageKey);
          return switch (pageKey) {
            null => _page(1, 3, ['video-1', 'video-2']),
            2 => _page(2, 3, ['video-2', 'video-3']),
            3 => _page(3, 3, ['video-3', 'video-4']),
            _ => throw StateError('unexpected page $pageKey'),
          };
        },
        itemKey: (item) => item.id,
      );

      expect(requestedPages, [null, 2, 3]);
      expect(result.items.map((item) => item.id), [
        'video-1',
        'video-2',
        'video-3',
        'video-4',
      ]);
      expect(result.completed, isTrue);
      expect(result.isPartial, isFalse);
      expect(result.nextPage, isNull);
      expect(result.error, isNull);
    },
  );

  test('retries a failed page once before continuing', () async {
    final requestedPages = <int?>[];
    var pageTwoAttempts = 0;

    final result = await fetchFullPlaylist<_PlaylistItem>(
      fetchPage: ({int? pageKey}) async {
        requestedPages.add(pageKey);
        if (pageKey == 2 && pageTwoAttempts++ == 0) {
          throw StateError('transient failure');
        }
        return pageKey == null
            ? _page(1, 2, ['video-1'])
            : _page(2, 2, ['video-2']);
      },
      itemKey: (item) => item.id,
    );

    expect(requestedPages, [null, 2, 2]);
    expect(result.items.map((item) => item.id), ['video-1', 'video-2']);
    expect(result.completed, isTrue);
    expect(result.error, isNull);
  });

  test(
    'returns the fetched prefix when a page fails after the retry',
    () async {
      final requestedPages = <int?>[];
      final failure = StateError('page unavailable');

      final result = await fetchFullPlaylist<_PlaylistItem>(
        fetchPage: ({int? pageKey}) async {
          requestedPages.add(pageKey);
          if (pageKey == 2) throw failure;
          return _page(1, 3, ['video-1', 'video-1']);
        },
        itemKey: (item) => item.id,
      );

      expect(requestedPages, [null, 2, 2]);
      expect(result.items.map((item) => item.id), ['video-1']);
      expect(result.completed, isFalse);
      expect(result.isPartial, isTrue);
      expect(result.nextPage, 2);
      expect(result.error, same(failure));
      expect(result.stackTrace, isNotNull);
    },
  );
}
