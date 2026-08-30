part of 'search_bloc.dart';

// 💡 类头括号里写了 final，类体内就不再需要写成员变量声明了

class SearchState({
  final List<RecentSearchQuery> recentSearchQueries = const [],
  final List<String> suggests = const [],
  final String currentQuery = '',
}) {
  // 依然可以通过常规方法对自动生成的 final 属性进行 copyWith 复制
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
