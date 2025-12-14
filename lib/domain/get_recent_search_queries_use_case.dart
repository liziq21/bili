import 'dart:async';

import '../data/model/recent_search_query.dart';
import '../data/repository/recent_search_repository.dart';

class GetRecentSearchQueriesUseCase {
  const GetRecentSearchQueriesUseCase(
    RecentSearchRepository: recentSearchRepository,
  ) : _recentSearchRepository = recentSearchRepository;
  
  late final RecentSearchRepository _recentSearchRepository
  
  Stream<List<RecentSearchQuery>> invoke([int limit = 10]) =>
    _recentSearchRepository.getRecentSearchQueries(limit);
}
