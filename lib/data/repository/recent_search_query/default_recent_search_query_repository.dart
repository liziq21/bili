import 'dart:async';

import '../../../database/dao/recent_search_query_dao.dart';
import '../../model/recent_search_query.dart';
import 'recent_search_query_repository.dart';

class DefaultRecentSearchQueryRepository implements RecentSearchQueryRepository {
  DefaultRecentSearchQueryRepository({
    required RecentSearchQueryDao recentSearchQueryDao,
  }) : _recentSearchQueryDao = recentSearchQueryDao;
  
  late final RecentSearchQueryDao _recentSearchQueryDao;
  
  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
    _recentSearchQueryDao.getRecentSearchQueryEntities(limit)
      .map((entities) => 
        entities
          .map((it) => it.asExternalModel())
          .toList(),
      );

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async =>
    _recentSearchQueryDao.insertOrReplaceRecentSearch(searchQuery);

  @override
  Future<void> clearRecentSearchQueries() async =>
    _recentSearchQueryDao.clearRecentSearchQueries();
  
}