import 'package:flutter/cupertino.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';

import '../../data/repository/model/creator_profile.dart';
import '../../data/repository/model/video_info_base.dart';
import '../../data/repository/search_contents/search_contents_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class AllSearchResultsViewModel extends ChangeNotifier {
  AllSearchResultsViewModel({
    required SearchContentsRepository searchContentsRepository,
    required this.searchQuery,
  }) : _searchContentsRepository = searchContentsRepository;

  final _log = Logger('SearchResultViewModel');
  final String searchQuery;
  final SearchContentsRepository _searchContentsRepository;
  final PagingController _pagingController = .new<int, VideoSearchResult>(
    getNextPageKey: (state) =>
      state.lastPageIsEmpty && state.nextIntPageKey > _numPages ? null : state.nextIntPageKey,
    fetchPage: _search,
  );

  int _numPages = 1;
  CreatorProfile? _creatorProfile;
  
  PagingController get pagingController => _pagingController;
  UserSearchResult? get creatorProfile => _creatorProfile;

  Future<List<VideoInfoBase>> _search(int pageKey) async {
    final result = await _searchContentsRepository.searchContents(searchQuery, page: pageKey);
    switch (result) {
      case Ok(:value):
        _log.fine('Search video (${value.videos.length}) loaded');
        if (value.page == 1) {
          _creatorProfile = value.creatorProfile;
          _numPages = value.numPages;
          notifyListeners();
        }
        return value.videos;
      case Error(:error):
        _log.warning('Failed to load search contents', error);
        throw error;
    }
  }
  
  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}