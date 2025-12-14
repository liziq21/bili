import 'dart:async';

import '../../model/recent_search_query.dart'
import '../../../database/dao/recent_search_query_dao.dart'

class DefaultRecentSearchRepository {
  const DefaultRecentSearchRepository({
    required RecentSearchQueryDao recentSearchQueryDao,
  }) : _recentSearchQueryDao = recentSearchQueryDao;
  
  late final RecentSearchQueryDao _recentSearchQueryDao;
  
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) async =>
    _recentSearchQueryDao.getRecentSearchQueryEntities(limit)
      .map((it) => it.asExternalModel());

  Future<void> insertOrReplaceRecentSearch(String searchQuery) async =>
    _recentSearchQueryDao.insertOrReplaceRecentSearch(searchQuery);

  Future<void> clearRecentSearches() async =>
    _recentSearchQueryDao.clearRecentSearches();
  
}