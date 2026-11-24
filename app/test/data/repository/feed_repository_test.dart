import 'package:app/data/repository/feed_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/table/local_library.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/data.dart' as data show Page;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// 按频道返回固定分页的 fake 数据源，记录每次请求的页号。
final class _FakeUserVideosDataSource({
  required final Map<String, List<List<String>>> pagesByChannel,
  final Set<String> failingChannels = const {},
}) implements UserVideosRemoteDataSource {
  final requestedPages = <String, List<int>>{};

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<data.Page<VideoModel>, Exception>> fetchUserVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedPages.putIfAbsent(channelId, () => []).add(page);
    if (failingChannels.contains(channelId)) {
      return Result.error(Exception('channel $channelId failed'));
    }
    final pages = pagesByChannel[channelId] ?? const [];
    if (page < 1 || page > pages.length) {
      return Result.error(Exception('page $page out of range'));
    }
    return Result.success(
      data.Page<VideoModel>(
        number: page,
        totalPages: pages.length,
        data: [
          for (final id in pages[page - 1])
            VideoModel(
              id: id,
              title: 'Video $id',
              url: 'https://www.bilibili.com/video/$id',
              uploadDate: DateTime.utc(2026, 11, 1),
            ),
        ],
      ),
    );
  }
}

/// 按频道返回固定分页的 fake 专栏数据源，记录每次请求的页号。
final class _FakeUserArticlesDataSource({
  required final Map<String, List<List<String>>> pagesByChannel,
  final Set<String> failingChannels = const {},
}) implements UserArticlesRemoteDataSource {
  final requestedPages = <String, List<int>>{};

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<data.Page<ArticleModel>, Exception>> fetchUserArticles({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedPages.putIfAbsent(channelId, () => []).add(page);
    if (failingChannels.contains(channelId)) {
      return Result.error(Exception('channel $channelId failed'));
    }
    final pages = pagesByChannel[channelId] ?? const [];
    if (page < 1 || page > pages.length) {
      return Result.error(Exception('page $page out of range'));
    }
    return Result.success(
      data.Page<ArticleModel>(
        number: page,
        totalPages: pages.length,
        data: [
          for (final id in pages[page - 1])
            ArticleModel(
              id: id,
              title: 'Article $id',
              url: 'https://www.bilibili.com/read/$id',
              publishedAt: DateTime.utc(2026, 11, 1),
            ),
        ],
      ),
    );
  }
}

void main() {
  late AppDatabase db;
  late FeedRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> subscribe(String channelId, {String name = 'Creator'}) =>
      db.localLibraryDao.saveSubscription(
        LocalSubscriptionCompanion.insert(
          sourceId: 'bilibili',
          originalId: channelId,
          name: name,
        ),
      );

  FeedRepository buildRepository(
    UserVideosRemoteDataSource remote, {
    UserArticlesRemoteDataSource? articles,
  }) => FeedRepository(
    feedDao: db.feedDao,
    libraryDao: db.localLibraryDao,
    videoDataSource: remote,
    articleDataSource: articles,
  );

  test('appends only unseen entries and stops at the known boundary', () async {
    // Given one subscription whose second page overlaps the first.
    await subscribe('creator-1');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v3', 'v2'],
            ['v2', 'v1'],
          ],
        },
      ),
    );

    // When the channel is loaded for the first time.
    final first = await repository.loadIncremental(sourceId: 'bilibili');

    // Then every unseen entry lands and the overlapping page ends the walk.
    expect(first.newEntryCount, 3);
    expect(first.unreadCount, 3);
    expect(
      (await db.feedDao.getEntries(sourceId: 'bilibili'))
          .map((entry) => entry.entryId)
          .toSet(),
      {'v1', 'v2', 'v3'},
    );

    // When the same feed is loaded again with a new entry on top.
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v4', 'v3', 'v2'],
          ],
        },
      ),
    );
    final second = await repository.loadIncremental(sourceId: 'bilibili');

    // Then only the unseen entry is appended; nothing is duplicated.
    expect(second.newEntryCount, 1);
    final entries = await db.feedDao.getEntries(sourceId: 'bilibili');
    expect(entries.map((entry) => entry.entryId).toSet(), {
      'v1',
      'v2',
      'v3',
      'v4',
    });
    expect(entries, hasLength(4));
  });

  test('a repeated load with unchanged remote adds nothing', () async {
    // Given a channel that is already fully synced.
    await subscribe('creator-1');
    final remote = _FakeUserVideosDataSource(
      pagesByChannel: {
        'creator-1': [
          ['v1', 'v2'],
        ],
      },
    );
    repository = buildRepository(remote);
    await repository.loadIncremental(sourceId: 'bilibili');

    // When the same load runs again.
    final again = await repository.loadIncremental(sourceId: 'bilibili');

    // Then no entry is added and the remote was asked exactly once more.
    expect(again.newEntryCount, 0);
    expect(await db.feedDao.getEntries(sourceId: 'bilibili'), hasLength(2));
    expect(remote.requestedPages['creator-1'], [1, 1]);
  });

  test('keeps entries read state when an entry is seen again', () async {
    // Given a synced entry the user already read.
    await subscribe('creator-1');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
        },
      ),
    );
    await repository.loadIncremental(sourceId: 'bilibili');
    await db.feedDao.markAllRead('bilibili', 'creator-1');

    // When the channel is reloaded with the same entry plus a new one.
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v2', 'v1'],
          ],
        },
      ),
    );
    await repository.loadIncremental(sourceId: 'bilibili');

    // Then only the new entry is unread.
    expect(await db.feedDao.getUnreadCount('bilibili', 'creator-1'), 1);
    expect(await db.feedDao.getUnreadCountForSource('bilibili'), 1);
  });

  test('reports failing channels and still loads the healthy ones', () async {
    // Given two subscriptions, one of which the remote rejects.
    await subscribe('creator-1');
    await subscribe('creator-2');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
          'creator-2': [
            ['w1'],
          ],
        },
        failingChannels: {'creator-2'},
      ),
    );

    // When the feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then the healthy channel is stored and the failure is reported.
    expect(result.newEntryCount, 1);
    expect(result.failedChannelIds, ['creator-2']);
    expect(result.isComplete, isFalse);
    expect(
      (await db.feedDao.getEntries(sourceId: 'bilibili'))
          .map((entry) => entry.entryId),
      ['v1'],
    );
  });

  test('ignores subscriptions belonging to another source', () async {
    // Given a subscription recorded under a different source.
    await db.localLibraryDao.saveSubscription(
      LocalSubscriptionCompanion.insert(
        sourceId: 'youtube',
        originalId: 'channel-yt',
        name: 'YT',
      ),
    );
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'channel-yt': [
            ['x1'],
          ],
        },
      ),
    );

    // When the bilibili feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then nothing is fetched or stored for it.
    expect(result.newEntryCount, 0);
    expect(await db.feedDao.getEntries(sourceId: 'youtube'), isEmpty);
  });

  test(
    'returns an empty result when the source has no channel support',
    () async {
      // Given a source without the optional user-videos capability.
      await subscribe('creator-1');
      repository = FeedRepository(
        feedDao: db.feedDao,
        libraryDao: db.localLibraryDao,
      );

      // When the feed is loaded.
      final result = await repository.loadIncremental(sourceId: 'bilibili');

      // Then it reports no work instead of failing.
      expect(result.newEntryCount, 0);
      expect(result.failedChannelIds, isEmpty);
    },
  );

  test('stops paging at the per-channel page budget', () async {
    // Given a channel whose pages never repeat an entry.
    await subscribe('creator-1');
    final remote = _FakeUserVideosDataSource(
      pagesByChannel: {
        'creator-1': [
          ['v1'],
          ['v2'],
          ['v3'],
          ['v4'],
        ],
      },
    );
    repository = buildRepository(remote);

    // When the page budget is two.
    final result = await repository.loadIncremental(
      sourceId: 'bilibili',
      maxPagesPerChannel: 2,
    );

    // Then only two pages are requested.
    expect(result.newEntryCount, 2);
    expect(remote.requestedPages['creator-1'], [1, 2]);
  });

  test('stores channel identity and upload date on each entry', () async {
    // Given a subscribed channel with a display name.
    await subscribe('creator-1', name: 'Channel One');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
        },
      ),
    );

    // When the entry is stored.
    await repository.loadIncremental(sourceId: 'bilibili');

    // Then it carries the feed metadata the UI groups by.
    final entry = (await db.feedDao.getEntries(sourceId: 'bilibili')).single;
    expect(entry.channelId, 'creator-1');
    expect(entry.creatorProfileName, 'Channel One');
    expect(entry.entryType, FeedEntry.typeVideo);
    expect(entry.publishedAt, DateTime.utc(2026, 11, 1));
  });

  test('stores articles alongside videos for the same channel', () async {
    // Given a channel that publishes both videos and articles.
    await subscribe('creator-1', name: 'Channel One');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
        },
      ),
      articles: _FakeUserArticlesDataSource(
        pagesByChannel: {
          'creator-1': [
            ['cv1', 'cv2'],
          ],
        },
      ),
    );

    // When the feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then both kinds are stored and counted, each with its own type and url.
    expect(result.newEntryCount, 3);
    expect(result.unreadCount, 3);
    final entries = {
      for (final entry in await db.feedDao.getEntries(sourceId: 'bilibili'))
        entry.entryId: entry,
    };
    expect(entries.keys.toSet(), {'v1', 'cv1', 'cv2'});
    expect(entries['v1']!.entryType, FeedEntry.typeVideo);
    expect(entries['cv1']!.entryType, FeedEntry.typeArticle);
    expect(entries['cv1']!.url, 'https://www.bilibili.com/read/cv1');
    expect(entries['cv1']!.title, 'Article cv1');
    expect(entries['cv1']!.creatorProfileName, 'Channel One');
    expect(entries['cv1']!.publishedAt, DateTime.utc(2026, 11, 1));
  });

  test('an article failure still stores the videos of that channel', () async {
    // Given a channel whose article endpoint fails.
    await subscribe('creator-1');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
        },
      ),
      articles: _FakeUserArticlesDataSource(
        pagesByChannel: const {},
        failingChannels: const {'creator-1'},
      ),
    );

    // When the feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then the videos land and the channel is reported as partially failed.
    expect(result.newEntryCount, 1);
    expect(result.failedChannelIds, ['creator-1']);
    expect(result.isComplete, isFalse);
    expect(
      (await db.feedDao.getEntries(sourceId: 'bilibili')).map((e) => e.entryId),
      ['v1'],
    );
  });

  test('a video failure still stores the articles of that channel', () async {
    // Given a channel whose video endpoint fails.
    await subscribe('creator-1');
    repository = buildRepository(
      _FakeUserVideosDataSource(
        pagesByChannel: const {},
        failingChannels: const {'creator-1'},
      ),
      articles: _FakeUserArticlesDataSource(
        pagesByChannel: {
          'creator-1': [
            ['cv1'],
          ],
        },
      ),
    );

    // When the feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then the articles land and the channel is reported as partially failed.
    expect(result.newEntryCount, 1);
    expect(result.failedChannelIds, ['creator-1']);
    expect(
      (await db.feedDao.getEntries(sourceId: 'bilibili')).map((e) => e.entryId),
      ['cv1'],
    );
  });

  test('loads articles when the source has no video capability', () async {
    // Given a source that only exposes the article endpoint.
    await subscribe('creator-1');
    repository = FeedRepository(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      articleDataSource: _FakeUserArticlesDataSource(
        pagesByChannel: {
          'creator-1': [
            ['cv1'],
          ],
        },
      ),
    );

    // When the feed is loaded.
    final result = await repository.loadIncremental(sourceId: 'bilibili');

    // Then the article is stored and no video request is attempted.
    expect(result.newEntryCount, 1);
    expect(
      (await db.feedDao.getEntries(sourceId: 'bilibili')).single.entryType,
      FeedEntry.typeArticle,
    );
  });
}
