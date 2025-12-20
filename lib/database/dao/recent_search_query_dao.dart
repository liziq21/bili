import 'package:drift/drift.dart';

import '../bili_database.dart';
import '../table/recent_search_query.dart';

part 'recent_search_query_dao.g.dart';

@DriftAccessor(tables: [RecentSearchQuery])
class RecentSearchQueryDao extends DatabaseAccessor<BiliDatabase> with _$RecentSearchQueryDaoMixin {
  RecentSearchQueryDao(super.attachedDatabase);

  Stream<List<RecentSearchQueryEntity>> getRecentSearchQueryEntities(int limit) =>
    (select(recentSearchQuery)
      ..orderBy([(it) => OrderingTerm(expression: it.queriedDate)])
      ..limit(limit))
      .watch();
  
  Future<void> insertOrReplaceRecentSearch(String searchQuery) =>
    into(recentSearchQuery).insertOnConflictUpdate(
      RecentSearchQueryCompanion(query: Value(searchQuery)),
    );
  
  Future<void> clearRecentSearchQueries() =>
    delete(recentSearchQuery).go();

}