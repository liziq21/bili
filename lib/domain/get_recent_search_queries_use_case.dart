import 'dart:async';

import '../data/model/recent_search_query.dart';
import '../data/repository/recent_search_query/recent_search_query_repository.dart';

class GetRecentSearchQueriesUseCase {
  GetRecentSearchQueriesUseCase({
    required RecentSearchQueryRepository recentSearchQueryRepository,
  }) : _recentSearchQueryRepository = recentSearchQueryRepository;
  
  late final RecentSearchQueryRepository _recentSearchQueryRepository;
  
  Stream<List<RecentSearchQuery>> invoke([int limit = 10]) =>
    _recentSearchQueryRepository.getRecentSearchQueries(limit);
}
