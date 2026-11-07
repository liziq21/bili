import 'dart:async';

import '../../../database/dao/recent_search_query_dao.dart';
import '../../model/recent_search_query.dart';
import 'recent_search_query_repository.dart';

class DefaultRecentSearchQueryRepository({
  required final RecentSearchQueryDao _recentSearchQueryDao,
}) implements RecentSearchQueryRepository {
  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
      _recentSearchQueryDao
          .getRecentSearchQueryEntities(limit)
          .map(
            (entities) => entities.map((it) => it.asExternalModel()).toList(),
          );

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async =>
      _recentSearchQueryDao.insertOrReplaceRecentSearch(searchQuery);

  @override
  Future<void> clearRecentSearchQueries() async =>
      _recentSearchQueryDao.clearRecentSearchQueries();

  @override
  Future<void> deleteOldSearchQueries(int retentionDays) async {
    if (retentionDays <= 0) return; // -1 means forever, 0 means no retention
    await _recentSearchQueryDao.deleteOldSearchQueries(retentionDays);
  }

  @override
  Future<void> deleteRecentSearchQuery(String query) async =>
      _recentSearchQueryDao.deleteRecentSearchQuery(query);
}
