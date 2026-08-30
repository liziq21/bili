part of 'search_bloc.dart';

sealed class SearchEvent {}

class MonitorRecentSearches extends SearchEvent {}

class ClearRecentSearchesPressed extends SearchEvent {}

class SearchQueryChanged(final String query) extends SearchEvent;
class FetchSuggests(final String query) extends SearchEvent;
class RecentSearchUpdated(final String query) extends SearchEvent;
