part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void navigateToSearchReault(String keyword) {
    SearchRouteData(keyword: keyword).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  const SearchRouteData({
    /*@TypedQueryParameter(name: 's') */ required this.keyword,
  });

  final String keyword;

  @override
  Widget build(context, _) {
    return SearchResultScreen(
      viewModel: .new(
        searchSuggestRepository: context.read<SearchSuggestRepository>(),
        recentSearchQueryRepository: context.read(),
        getRentSearchQueriesUseCase: context
            .read<GetRecentSearchQueriesUseCase>(),
      ),
      searchQuery: keyword,
      onBackClick: () => context.pop(),
    );
  }
}
