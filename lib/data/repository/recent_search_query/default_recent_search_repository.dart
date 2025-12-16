import 'dart:async';

import '../../model/recent_search_query.dart';
import '../../../database/dao/recent_search_query_dao.dart';

class DefaultRecentSearchRepository {
  DefaultRecentSearchRepository({
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