import 'package:flutter/material.dart' hide Page;
import 'package:data/data.dart';
import 'package:model/model.dart';
import 'paging_mixin.dart';

typedef SearchApi<T> = Future<Result<Page<T>>> Function(SearchQuery query);

enum SearchType { all, video, creatorProfile, liveRoom }

class SearchResultViewModel<T>({
  required this._query,
  required final SearchContentsRepository<T> searchContentsRepository,
}) extends ChangeNotifier with PagingMixin<T> {
  this : _sortOptions = searchContentsRepository.sortOptions,
         _filters = searchContentsRepository.filters;
  
  final List<SortOption> _sortOptions;
  final List<FilterGroup> _filters;

  String _query;
  SortOption? _currentSort;

  List<SortOption> get sortOptions => _sortOptions;
  SortOption? get currentSort => _currentSort;
  List<FilterGroup> get filters => _filters;

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void onSortChanged(SortOption sortOption) {
    _currentSort = sortOption;
    notifyListeners();
  }

  void onFilterChanged(int index, FilterGroup newFilter) {
    _filters[index] = newFilter;
    notifyListeners();
  }

  @override
  Future<Result<Page<T>>> fetchPage(int pageKey) {
    final query = SearchQuery(
      _query,
      page: pageKey,
      sortOption: _currentSort,
      filters: _filters,
    );
    return searchContentsRepository.search(query);
  }
}

class SearchConfig({
  required final List<SortOption> sortOptions,
  required final List<FilterGroup> filters,
  required final SearchType type,
});

class AllSearchResultViewModel extends SearchResultViewModel<VideoInfoBase> {
  AllSearchResultViewModel({
    required super.query,
    required super.searchContentsRepository,
  });

  CreatorProfile? creatorProfile;
  List<VideoInfoBase>? creatorProfileVideos;

  @override
  Future<Result<Page<VideoInfoBase>>> fetchPage(int pageKey) async {
    final query = SearchQuery(
      _query,
      page: pageKey,
      sortOption: _currentSort,
      filters: _filters,
    );
    final result = await searchContentsRepository.search(query);

    if (result case Ok(
      value: final AggregateSearchPage aggregatePage,
    ) when aggregatePage.number == 1) {
      creatorProfile = aggregatePage.creatorProfile;
      creatorProfileVideos = aggregatePage.creatorProfileVideos;
      notifyListeners();
    }

    return result;
  }
}
