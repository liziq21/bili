import 'dart:async';

import 'package:app/data/repository/creator_profile_repository.dart';
import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class _FakeCreatorProfileSearchRepository(
  final Result<Page<CreatorProfile>, Exception> result,
) implements CreatorProfileSearchRepository {
  int searchCallCount = 0;
  SearchQuery? lastQuery;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<CreatorProfile>, Exception>> search(
    SearchQuery searchQuery,
  ) async {
    searchCallCount++;
    lastQuery = searchQuery;
    return result;
  }
}

class _FakeCreatorProfileRemoteDataSource(
  final Result<CreatorProfile, Exception> result,
) implements CreatorProfileRemoteDataSource {
  int callCount = 0;
  String? lastId;

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<CreatorProfile, Exception>> getProfile(String id) async {
    callCount++;
    lastId = id;
    return result;
  }
}

/// 手动控制何时返回的远端源，用来制造「两个请求同时在路上」。
class _ControlledCreatorProfileRemoteDataSource()
    implements CreatorProfileRemoteDataSource {
  final _completer = Completer<Result<CreatorProfile, Exception>>();
  int callCount = 0;

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<CreatorProfile, Exception>> getProfile(String id) {
    callCount++;
    return _completer.future;
  }

  void complete(Result<CreatorProfile, Exception> result) =>
      _completer.complete(result);
}

class const _RateLimited() implements RateLimitedFailure;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('returns the cached profile without searching', () async {
    const profile = CreatorProfile(
      id: 'creator-1',
      name: 'Cached creator',
      description: 'Cached description',
      subscribers: 12000,
      videos: 24,
    );
    await database.creatorProfileDao.cacheCreatorProfile('bilibili', profile);
    final search = _FakeCreatorProfileSearchRepository(
      Result.error(Exception('search should not run')),
    );
    final repository = AppCreatorProfileRepository(
      'bilibili',
      database.creatorProfileDao,
      search,
      null,
    );

    final result = await repository.getProfile('creator-1');

    expect(result, isA<Success<CreatorProfile, Exception>>());
    expect(search.searchCallCount, 0);
    if (result case Success(:final success)) {
      expect(success.name, 'Cached creator');
      expect(success.description, 'Cached description');
      expect(success.subscribers, 12000);
      expect(success.videos, 24);
    }
  });

  test('searches, caches, and returns an uncached profile', () async {
    const profile = CreatorProfile(
      id: 'creator-2',
      name: 'Remote creator',
      description: 'Remote description',
      subscribers: 3456,
      videos: 12,
    );
    final search = _FakeCreatorProfileSearchRepository(
      Result.success(
        Page<CreatorProfile>(data: [profile], number: 1, totalPages: 1),
      ),
    );
    final repository = AppCreatorProfileRepository(
      'bilibili',
      database.creatorProfileDao,
      search,
      null,
    );

    final result = await repository.getProfile('creator-2');

    expect(result, isA<Success<CreatorProfile, Exception>>());
    expect(search.searchCallCount, 1);
    expect(search.lastQuery?.query, 'creator-2');
    final cached = await database.creatorProfileDao.getCreatorProfile(
      'bilibili',
      'creator-2',
    );
    expect(cached?.description, 'Remote description');
    expect(cached?.subscribers, 3456);
    expect(cached?.videos, 12);
  });

  test('prefers the profile source over the search endpoint', () async {
    const profile = CreatorProfile(id: 'creator-3', name: 'Direct creator');
    final search = _FakeCreatorProfileSearchRepository(
      Result.error(Exception('search should not run')),
    );
    final profileSource = _FakeCreatorProfileRemoteDataSource(
      Result.success(profile),
    );
    final repository = AppCreatorProfileRepository(
      'bilibili',
      database.creatorProfileDao,
      search,
      profileSource,
    );

    final result = await repository.getProfile('creator-3');

    expect(result.isSuccess(), isTrue);
    expect(profileSource.callCount, 1);
    expect(profileSource.lastId, 'creator-3');
    expect(search.searchCallCount, 0);
    final cached = await database.creatorProfileDao.getCreatorProfile(
      'bilibili',
      'creator-3',
    );
    expect(cached?.name, 'Direct creator');
  });

  test('does not fall back to search after a rate limit', () async {
    // 搜索端点与搜索页共用更紧的额度，被限流后再打一次只会让冷却更久。
    final search = _FakeCreatorProfileSearchRepository(
      Result.error(Exception('search should not run')),
    );
    final profileSource = _FakeCreatorProfileRemoteDataSource(
      Result.error(const _RateLimited()),
    );
    final repository = AppCreatorProfileRepository(
      'bilibili',
      database.creatorProfileDao,
      search,
      profileSource,
    );

    final result = await repository.getProfile('creator-4');

    expect(result.tryGetError(), isA<RateLimitedFailure>());
    expect(profileSource.callCount, 1);
    expect(search.searchCallCount, 0);
  });

  test(
    'falls back to search when the profile source fails otherwise',
    () async {
      const profile = CreatorProfile(id: 'creator-5', name: 'Searched creator');
      final search = _FakeCreatorProfileSearchRepository(
        Result.success(
          Page<CreatorProfile>(data: [profile], number: 1, totalPages: 1),
        ),
      );
      final profileSource = _FakeCreatorProfileRemoteDataSource(
        Result.error(Exception('card endpoint unavailable')),
      );
      final repository = AppCreatorProfileRepository(
        'bilibili',
        database.creatorProfileDao,
        search,
        profileSource,
      );

      final result = await repository.getProfile('creator-5');

      expect(result.isSuccess(), isTrue);
      expect(profileSource.callCount, 1);
      expect(search.searchCallCount, 1);
    },
  );

  test('coalesces concurrent requests for the same creator', () async {
    // 两个请求同时在路上时，慢的那个会把旧资料写回缓存；合并成一次既避免
    // 乱序覆盖，也少打一次网络。
    const profile = CreatorProfile(id: 'creator-6', name: 'Creator');
    final profileSource = _ControlledCreatorProfileRemoteDataSource();
    final repository = AppCreatorProfileRepository(
      'bilibili',
      database.creatorProfileDao,
      null,
      profileSource,
    );

    final first = repository.getProfile('creator-6');
    final second = repository.getProfile('creator-6');
    profileSource.complete(Result.success(profile));

    expect((await first).isSuccess(), isTrue);
    expect((await second).isSuccess(), isTrue);
    expect(profileSource.callCount, 1);

    // 请求结束后不再复用，下一次调用重新走缓存 / 远端。
    final cached = await repository.getProfile('creator-6');
    expect(cached.isSuccess(), isTrue);
    expect(profileSource.callCount, 1);
  });
}
