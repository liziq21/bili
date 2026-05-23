import 'dart:async';

import 'package:data/data.dart';

class GetRecentSearchQueriesUseCase {
  GetRecentSearchQueriesUseCase({
    required RecentSearchQueryRepository recentSearchQueryRepository,
  }) : _recentSearchQueryRepository = recentSearchQueryRepository;

  late final RecentSearchQueryRepository _recentSearchQueryRepository;

  Stream<List<RecentSearchQuery>> invoke([int limit = 10]) =>
      _recentSearchQueryRepository.getRecentSearchQueries(limit);
}
