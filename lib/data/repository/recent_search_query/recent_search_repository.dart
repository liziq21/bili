import 'dart:async';

import '../../model/recent_search_query.dart'

abstract class RecentSearchRepository {
  
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit);

  Future<void> insertOrReplaceRecentSearch(String searchQuery);

  Future<void> clearRecentSearches();
  
}