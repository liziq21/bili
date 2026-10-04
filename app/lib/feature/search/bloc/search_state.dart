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
    // 复制并冻结两个列表。BlocSelector 依赖所选值不可变来跳过重建；若状态持有
    // 的是调用方那个可变列表，状态发出后再被原地修改，选择器会误判为「值没变」
    // 而跳过重建。类头默认参数只原样持有引用，冻结只能在此入口做。
    return SearchState(
      recentSearchQueries: List.unmodifiable(
        recentSearchQueries ?? this.recentSearchQueries,
      ),
      suggests: List.unmodifiable(suggests ?? this.suggests),
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}
