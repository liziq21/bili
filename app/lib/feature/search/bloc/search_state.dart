part of 'search_bloc.dart';

class SearchState {
  const SearchState({
    this.recentSearchQueries = const [],
    this.suggests = const [],
    this.currentQuery = '',
  });

  final List<RecentSearchQuery> recentSearchQueries;
  final List<String> suggests;
  final String currentQuery;

  SearchState copyWith({
    List<RecentSearchQuery>? recentSearchQueries,
    List<String>? suggests,
    String? currentQuery,
  }) {
    return SearchState(
      recentSearchQueries: recentSearchQueries ?? this.recentSearchQueries,
      suggests: suggests ?? this.suggests,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}
