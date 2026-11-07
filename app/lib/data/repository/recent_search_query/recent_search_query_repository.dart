import 'dart:async';

import '../../model/recent_search_query.dart';

abstract class RecentSearchQueryRepository() {
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit);

  Future<void> insertOrReplaceRecentSearch(String searchQuery);

  Future<void> clearRecentSearchQueries();

  Future<void> deleteOldSearchQueries(int retentionDays);

  Future<void> deleteRecentSearchQuery(String query);
}
