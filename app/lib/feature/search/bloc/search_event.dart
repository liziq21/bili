part of 'search_bloc.dart';

sealed class SearchEvent();

class MonitorRecentSearches() extends SearchEvent;

class ClearRecentSearchesPressed() extends SearchEvent;

/// 删除单条搜索历史。
class DeleteRecentSearchPressed(final String query) extends SearchEvent;

class SearchQueryChanged(final String query) extends SearchEvent;
class FetchSuggests(final String query) extends SearchEvent;
class RecentSearchUpdated(final String query) extends SearchEvent;
class CleanupOldSearchQueries() extends SearchEvent;
