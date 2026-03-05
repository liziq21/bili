import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import '../../data/models/paged_result.dart';
import '../../data/models/search_result.dart';
import '../../data/repository/search_contents_repository.dart';
import '../../utils/result.dart';

abstract class PagingViewModel<T extends PagedResult<T>> extends ChangeNotifier {
  final PagingController pagingController = .new<int, T>(
    getNextPageKey: (state) => state.nextIntPageKey > _totalPages ? null : state.nextIntPageKey,
    fetchPage: _fetchPage,
  );
  
  int _totalPages = 1;
  
  Future<PagedResult<T>> fetchPage(int pageKey);

  Future<List<T>> _fetchPage(int pageKey) async {
    final pagedResult = await fetchPage(pageKey);
    _totalPages = pagedResult.totalPages;
    return pagedResult.data;
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

abstract class SearchTypeConfig {
  SearchType get type;
  List<SortOption> get supportedSorts;
  List<FilterOption> get supportedFilters;
  int get initialSortBy => 0;
}

class BiliVideoSearchTypeConfig implements SearchTypeConfig {
  @override SearchType get type => .video;
  @override List<SortOption> get supportedSorts => [
    
  ];
  @override List<FilterOption> get supportedFilters => [
    
  ];
}

abstract class PlatformConfig {
  String get platformId;
  String get platformName;
  bool get supportsSearch;
  List<SearchTypeConfig> get supportedSearchTypes;
}

class BiliPlatformConfig implements PlatformConfig {
  @override String get platformId => 'bilibili';
  @override String get platformName => 'Bilibili';
  @override bool get supportsSearch => true;
  @override List<SearchTypeConfig> get supportedSearchTypes => [
    BiliVideoSearchTypeConfig(),
  ];
}

// 每个搜索类型一个独立的ViewModel
class SearchTypeViewModel implements PagingViewModel {
  SearchTypeViewModel({
    required SearchContentsRepository searchContentsRepository,
    required this.platformConfig,
    required this.typeConfig,
  }) : _searchContentsRepository = searchContentsRepository {
    if (typeConfig.supportedSorts.isNotEmpty) {
      _currentSort = typeConfig.supportedSorts.first;
    }
  }
  
  final SearchContentsRepository _searchContentsRepository;
  final PlatformConfig platformConfig;
  final SearchTypeConfig typeConfig;

  String _currentQuery = '';
  SortOption? _currentSort;
  Map<String, dynamic> _currentFilters = {}; // filterId -> value

  bool _isLoading = false;
  List<SearchResult> _results = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<SearchResult> get results => _results;
  String? get errorMessage => _errorMessage;
  SortOption? get currentSort => _currentSort;
  Map<String, dynamic> get currentFilters => _currentFilters;

  void setQuery(String query) {
    if (_currentQuery != query) {
      _currentQuery = query;
      fetchResults();
    }
  }

  void setSort(SortOption? sortOption) {
    if (_currentSort != sortOption) {
      _currentSort = sortOption;
      fetchResults();
    }
  }

  void setFilter(String filterId, dynamic value) {
    if (_currentFilters[filterId] != value) {
      _currentFilters[filterId] = value;
      fetchResults();
    }
  }

  Future<void> fetchResults() async {
    if (_currentQuery.isEmpty) {
      _results = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> params = {};
      if (_currentSort != null) {
        params.addAll(_currentSort!.toQueryParams());
      }
      _currentFilters.forEach((filterId, value) {
        final filterOption = typeConfig.supportedFilters.firstWhere((f) => f.id == filterId);
        params.addAll(filterOption.toQueryParams(value));
      });

      _results = await _repository.search(
        platformId: platformConfig.platformId,
        typeId: typeConfig.typeId,
        query: _currentQuery,
        params: params,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

abstract class BaseSearchViewModel<T, S extends SortOption> {
  BaseSearchViewModel({
    required this.searchQuery,
    required SearchContentsRepository searchContentsRepository,
    S? initialSortBy,
    this.availableSortOptions = [],
    this.filters,
  }) : _searchContentsRepository = searchContentsRepository,
       _currentSortBy = initialSortBy;

  final _log = Logger('BaseSearchViewModel');
  final String searchQuery;
  final SearchContentsRepository _searchContentsRepository;
  final List<S> availableSortOptions
  final SearchFilter? filter;
  
  S? _currentSortBy; // 当前排序选项
  S? get currentSortBy => _currentSortBy;

  // 暴露给 UI 的方法，用于修改排序
  void updateSortBy(S newSortOption) {
    if (_currentSortBy != newSortOption) {
      _currentSortBy = newSortOption;
      refreshResults();
    }
  }

  // 暴露给 UI 的方法，用于修改过滤器
  void updateFilters(SearchFilter newFilter) {
    if (_filters != newFilter) {
      _filters = newFilter;
      refreshResults();
    }
  }
}

class AllSearchResultsViewModel extends BaseSearchViewModel<AggregateSearchResults, AllSortOptions> {
  AllSearchResultsViewModel({
    required String searchQuery,
    required SearchContentsRepository searchContentsRepository,
  }) : super(
    searchQuery: searchQuery,
    searchContentsRepository: searchContentsRepository,
    initialSortBy: AllSortOptions.relevance, // 默认排序
    initialFilters: allResultFilters, // 初始过滤器
  );

  @override
  get availableSortOptions => [];

  @override
  get initialFilters => [];

  @override
  Future<PaginatedResult<AllSearchItem>> performSearch({
    required String query,
    required int page,
    required String sortBy,
    required List<SearchFilter> filters,
  }) {
    return searchContentsRepository.search(
      query: query,
      page: page,
      sortBy: sortBy,
      filters: filters,
    );
  }
}
