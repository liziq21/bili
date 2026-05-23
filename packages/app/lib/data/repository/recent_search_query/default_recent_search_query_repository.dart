import 'dart:async';

import 'package:data/data.dart';
import 'package:database/database.dart';

class DefaultRecentSearchQueryRepository
    implements RecentSearchQueryRepository {
  DefaultRecentSearchQueryRepository({
    required RecentSearchQueryDao recentSearchQueryDao,
  }) : _recentSearchQueryDao = recentSearchQueryDao;

  late final RecentSearchQueryDao _recentSearchQueryDao;

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
}
