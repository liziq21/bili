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
}
