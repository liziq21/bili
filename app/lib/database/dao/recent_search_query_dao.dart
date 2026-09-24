import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/recent_search_query.dart';

part 'recent_search_query_dao.g.dart';

@DriftAccessor(tables: [RecentSearchQuery])
class RecentSearchQueryDao(super.attachedDatabase) extends DatabaseAccessor<AppDatabase>
    with _$RecentSearchQueryDaoMixin {
  Stream<List<RecentSearchQueryEntity>> getRecentSearchQueryEntities(
    int limit,
  ) {
    return (select(recentSearchQuery)
          ..orderBy([(it) => OrderingTerm.desc(it.queriedDate)])
          ..limit(limit))
        .watch();
  }

  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    await into(recentSearchQuery).insertOnConflictUpdate(
      RecentSearchQueryCompanion(
        query: Value(trimmedQuery),
        queriedDate: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearRecentSearchQueries() => delete(recentSearchQuery).go();
}
