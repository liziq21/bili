import 'package:drift/drift.dart';

import '../bili_database.dart';
import '../model/recent_search_query_entity.dart';

part 'recent_search_query_dao.g.dart';

@DriftAccessor(tables: [RecentSearchQueryEntity])
class RecentSearchQueryDao extends DatabaseAccessor<BiliDatabase> with _$RecentSearchQueryDaoMixin {
  RecentSearchQueryDao(super.attachedDatabase);

  Stream<List<RecentSearchQueryEntityData>> getRecentSearchQueryEntities(int limit) {
    return (
      select(recentSearchQueryEntity)
        ..orderBy([(it) => OrderingTerm(expression: it.queriedDate)])
        ..limit(limit)
    ).watch();
  }
  
  Future<void> insertOrReplaceRecentSearch(String searchQuery) {
    return into(recentSearchQueryEntity).insertOnConflictUpdate(
      RecentSearchQueryEntityCompanion(query: Value(searchQuery)),
    );
  }
  
  Future<void> clearRecentSearchQueries() {
    return delete(recentSearchQueryEntity).go();
  }
}