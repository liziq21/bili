part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void navigateToSearch([String? keyword]) {
    SearchRouteData(keyword).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  const SearchRouteData([this.keyword]);
  
  final String? keyword;

  @override
  Widget build(context, state) {
    return SearchScreen(
      viewModel: .new(
        getRecentSearchQueriesUseCase: context.read(),
        recentSearchQueryRepository: context.read(),
        searchSuggestRepository: context.read(),
        initialQuery: keyword,
      ),
      onBackClick: () => context.pop(),
    );
  }
}

