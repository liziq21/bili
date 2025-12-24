import 'package:flutter/cupertino.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';

import '../../data/repository/model/concrete_results/bili_user_search_result.dart';
import '../../data/repository/model/concrete_results/video_search_result.dart';
import '../../data/repository/search_contents/search_contents_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class SearchResultViewModel extends ChangeNotifier {
  SearchResultViewModel({
    required SearchContentsRepository searchContentsRepository,
    required this.searchQuery,
  }) : _searchContentsRepository = searchContentsRepository;

  final _log = Logger('SearchResultViewModel');
  final String searchQuery;
  final SearchContentsRepository _searchContentsRepository;
  final PagingController _pagingController = .new<int, VideoSearchResult>(
    getNextPageKey: (state) =>
      state.lastPageIsEmpty && state.nextIntPageKey > _numPages ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => _search(pageKey),
  );

  int _numPages = 1;
  UserSearchResult? _userSearchResult;
  
  PagingController get pagingController => _pagingController;
  UserSearchResult? get userSearchResult => _userSearchResult;

  Future<List<VideoSearchResult>> _search(int pageKey) async {
    final result = await _searchContentsRepository.searchContents(searchQuery, page: pageKey);
    switch (result) {
      case Ok(:value):
        _log.fine('Search video (${value.videoResults.length}) loaded');
        _biliUserSearchResult = value.biliUserResults.firstOrNull;
        _numPages = value.numPages;
        notifyListeners();
        return value.videoResults;
      case Error(:error):
        _log.warning('Failed to load search contents', error);
        throw error;
    }
  }
}