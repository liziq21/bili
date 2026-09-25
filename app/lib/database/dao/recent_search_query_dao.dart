import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/recent_search_query.dart';

part 'recent_search_query_dao.g.dart';

@DriftAccessor(tables: [RecentSearchQuery])
class RecentSearchQueryDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$RecentSearchQueryDaoMixin {
  Stream<List<RecentSearchQueryEntity>> getRecentSearchQueryEntities(
    int limit,
  ) {
    return (select(recentSearchQuery)
          ..orderBy([(it) => OrderingTerm.desc(it.queriedDate)])
          ..limit(limit))
        .watch();
  }

  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static const int maxQueryLength = 200;

  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {
    var sanitizedQuery = searchQuery.replaceAll(_controlChars, '').trim();
    if (sanitizedQuery.length > maxQueryLength) {
      sanitizedQuery = sanitizedQuery.substring(0, maxQueryLength);
    }
    if (sanitizedQuery.isEmpty) {
      return;
    }

    await into(recentSearchQuery).insertOnConflictUpdate(
      RecentSearchQueryCompanion(
        query: Value(sanitizedQuery),
        queriedDate: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearRecentSearchQueries() => delete(recentSearchQuery).go();
}
