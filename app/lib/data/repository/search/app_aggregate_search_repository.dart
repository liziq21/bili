/// Aggregate search returns a combined page with video results plus
/// optional creator and creator-videos data. Currently commented out until
/// the UI consumes the aggregate form.
// import 'package:bilibili/bilibili.dart';
// import 'package:data/data.dart';
// import 'package:model/model.dart';
//
// import '../search_contents_repository.dart';
//
// class const AppAggregateSearchRepository(
//   final BilibiliSearchRemoteDataSource _remoteDataSource,
// ) implements AggregateSearchRepository {
//   @override
//   List<FilterGroup> get filters => const [];
//
//   @override
//   List<SortOption> get sortOptions => const [];
//
//   @override
//   Future<Result<Page<AggregateSearchPage>>> search(SearchQuery query) {
//     return _remoteDataSource.searchAll(query.query, pageKey: query.pageKey);
//   }
// }
