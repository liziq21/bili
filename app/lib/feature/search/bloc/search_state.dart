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
    // 只在收到新列表时复制并冻结，沿用时直接复用已有列表。BlocSelector 用 !=
    // 比较所选值，而 Dart 列表按实例比较——若每次 copyWith 都对沿用的列表再造
    // 一个 unmodifiable 副本，更新 currentQuery 或 suggests 时选择值也会「变」，
    // 最近搜索子树照样重建，等于抵消了 BlocSelector 的隔离作用。
    // 沿用是安全的：类头默认值是 const []，此后每次进入 copyWith 的列表都已冻结。
    return SearchState(
      recentSearchQueries: recentSearchQueries == null
          ? this.recentSearchQueries
          : List.unmodifiable(recentSearchQueries),
      suggests: suggests == null ? this.suggests : List.unmodifiable(suggests),
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}
