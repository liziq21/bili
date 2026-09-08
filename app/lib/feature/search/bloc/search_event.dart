part of 'search_bloc.dart';

sealed class SearchEvent {
  const SearchEvent();
}

class MonitorRecentSearches extends SearchEvent {
  const MonitorRecentSearches();
}

class ClearRecentSearchesPressed extends SearchEvent {
  const ClearRecentSearchesPressed();
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;
}

class FetchSuggests extends SearchEvent {
  const FetchSuggests(this.query);
  final String query;
}

class RecentSearchUpdated extends SearchEvent {
  const RecentSearchUpdated(this.query);
  final String query;
}
