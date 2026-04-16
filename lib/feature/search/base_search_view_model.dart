import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import '../../data/models/paged_result.dart';
import '../../data/models/search_result.dart';
import '../../data/repository/search_contents_repository.dart';
import '../../data/repositordy/search_contents_repository.dart';
import '../../model/data/filter_group.dart';
import '../../model/data/sort_option.dart';
import '../../utils/result.dart';

mixin PagingMixin<T> on ChangeNotifier {
  final _log = Logger('PagingMixin');
  late final pagingController = _initController();
  int _totalPages = 1;
  
  Future<PagedResult<T>> fetchPage(int pageKey);

  PagingController<int, T> _initController() {
    return PagingController<int, T>(
      getNextPageKey: (state) => state.nextIntPageKey > _totalPages ? null : state.nextIntPageKey,
      fetchPage: (key) async {
        final result = await fetchPage(key);
        switch (result) {
          case .ok(value: final page) :
            _totalPages = page.totalPages;
            return page.data;
          case .error(final error) :
            _log.find('$error');
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

abstract class BaseSearchViewModel<T> extends ChangeNotifier with PagingMixin<T> {  BaseSearchViewModel({
    required String query,
    required SearchContentsRepository searchContentsRepository,
    required SearchConfig config,
  }) : _query = query,
       _searchContentsRepository = searchContentsRepository,
       _currentSort = config.sortOptions,
       _currentSort = config.sortOptions?.firstOrNull,
       _filters = config.filters;
  
  final SearchContentsRepository _searchContentsRepository;
  final List<SortOption>? _sortOptions;

  String _query;
  SortOption? _currentSort;
  List<FilterGroup>? _filters;

  List<SortOption>? get sortOptions => _sortOptions;
  SortOption? get currentSort => _currentSort;
  List<FilterGroup>? get filters => _filters;
  
  void setQuery(String query) {
    _currentQuery = query;
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
  Future<PagedResult<T>> fetchPage(int pageKey) {
    return search(.new(
      query: query,
      page: page,
      sortOption: sortOption,
      filters: filters,
    ));
  }
  
  Future<PagedResult<T>> search(Query: query);
}

class SearchConfig {
  const SearchConfig({
    this.sortOptions,
    this.filters,
  });
  
  final List<SortOption>? sortOptions;
  final List<FilterGroup>? filters;
}

Search(
  repositoryFactory: (context) => BiliVideoRepository(),
  config: {
    .video: SearchConfig(
      sortOptions: BiliVideoSortOptions.values,
      filters: [DateRangeFilter(label: '时间范围')],
    ),
    .user: SearchConfig(
      sortOptions: BiliUserSortOptions.values,
      filters: [],
    ),
  },
});
  
class AllSearchResultsViewModel<AllSearchItem> extends BaseSearchViewModel<AggregateSearchResults, AllSortOptions> {
  AllSearchResultsViewModel({
    super.query,
    super.searchContentsRepository,
    super.config,
  });
  
  CreatorProfile? creatorProfile;
  List<VideoInfoBase>? creatorProfileVideos;
  
  @override
  Future<PagedResult<AllSearchItem>> search(Query: query) async {
    final result = searchContentsRepository.search(query);
    
    if (result case .ok(value: final AggregateSearchPage page)
      with page.number == 1 
    ) {
      creatorProfile = page.creatorProfile;
      creatorProfileVideos = page.creatorProfileVideos;
      notifyListeners();
    }
    
    return result;
  }
}

class AllSearchResultsViewModel<AllSearchItem> extends BaseSearchViewModel<AggregateSearchResults, AllSortOptions> {
  AllSearchResultsViewModel({
    super.query,
    super.searchContentsRepository,
    super.config,
  });
  
  @override
  Future<PagedResult<AllSearchItem>> search = searchContentsRepository.
  search;
  }
}
