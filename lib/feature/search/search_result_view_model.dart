import 'package:flutter/material.dart' hide Page;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import '../../data/model/creator_profile.dart';
import '../../data/model/paged_result.dart';
import '../../data/model/search_results.dart';
import '../../data/model/video_info_base.dart';
import '../../data/repository/search_contents/search_contents_repository.dart';
import '../../model/data/filter_group.dart';
import '../../model/data/sort_option.dart';
import '../../utils/result.dart';

mixin PagingMixin<T> on ChangeNotifier {
  final _log = Logger('PagingMixin');
  late final pagingController = _initController();
  int _totalPages = 1;

  Future<Result<Page<T>>> fetchPage(int pageKey);

  PagingController<int, T> _initController() {
    return PagingController<int, T>(
      getNextPageKey: (state) =>
          state.nextIntPageKey > _totalPages ? null : state.nextIntPageKey,
      fetchPage: (key) async {
        final result = await fetchPage(key);
        switch (result) {
          case Ok(:final value):
            _totalPages = value.totalPages;
            return value.data;
          case Error(:final error):
            _log.warning('$error');
            throw error;
        }
      },
    );
  }

  void refreshResults() {
    pagingController.refresh();
    notifyListeners();
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }
}
typedef SearchApi<T> = Future<Result<Page<T>>> Function(SearchQuery query);

enum SearchType { all, video, creatorProfile, liveRoom }

class SearchResultViewModel<T> extends ChangeNotifier with PagingMixin<T> {
  SearchResultViewModel({
    required String query,
    required this.searchContentsRepository,
    required SearchConfig config,
  }) : _query = query,
       _sortOptions = config.sortOptions,
       _currentSort = config.sortOptions.firstOrNull,
       _filters = config.filters;
  final SearchContentsRepository<T> searchContentsRepository;
  final List<SortOption>? _sortOptions;

  String _query;
  SortOption? _currentSort;
  final List<FilterGroup> _filters;

  List<SortOption>? get sortOptions => _sortOptions;
  SortOption? get currentSort => _currentSort;
  List<FilterGroup>? get filters => _filters;

  void setQuery(String query) {
    _query = query;
    refreshResults();
  }

  void onSortChanged(SortOption sortOption) {
    _currentSort = sortOption;
    refreshResults();
  }

  void onFilterChanged(int index, FilterGroup newFilter) {
    _filters[index] = newFilter;
    refreshResults();
  }

  @override
  Future<Result<Page<T>>> fetchPage(int pageKey) {
    return search(
      .new(_query, page: pageKey, sortOption: _currentSort, filters: _filters),
    );
  }

  Future<Result<Page<T>>> search(SearchQuery query) =>
      searchContentsRepository.search(query);
}

class SearchConfig {
  const SearchConfig({
    required this.type,
    required this.sortOptions,
    required this.filters,
  });

  final List<SortOption> sortOptions;
  final List<FilterGroup> filters;
  final SearchType type;
}

class AllSearchResultViewModel extends SearchResultViewModel<VideoInfoBase> {
  AllSearchResultViewModel({
    required super.query,
    required super.searchContentsRepository,
    required super.config,
  });

  CreatorProfile? creatorProfile;
  List<VideoInfoBase>? creatorProfileVideos;

  @override
  Future<Result<Page<VideoInfoBase>>> search(SearchQuery query) async {
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
