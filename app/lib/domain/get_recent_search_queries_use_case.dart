import 'dart:async';

import '../data/model/recent_search_query.dart';
import '../data/repository/recent_search_query/recent_search_query_repository.dart';

/// 获取最近搜索历史记录用例 (Domain Use Case)
///
/// 从 [RecentSearchQueryRepository] 监听最新的搜索历史数据流。
class GetRecentSearchQueriesUseCase({
  required final RecentSearchQueryRepository _recentSearchQueryRepository,
}) {
  /// 获取最近搜索历史列表流，可选指定限制条数 [limit]
  Stream<List<RecentSearchQuery>> invoke([int limit = 10]) =>
      _recentSearchQueryRepository.getRecentSearchQueries(limit);
}
