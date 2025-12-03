part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void pushToSearch(String? keyword) {
    SearchRouteData(keyword).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  const SearchRouteData(this.keyword);
  
  final String? keyword;

  @override
  Widget build(context, state) {
    final viewModel = SearchViewModel(
      searchRepository: context.read(),
      searchSuggestRepository: context.read(),
      initialQuery: keyword,
    );
    return SearchScreen(
      viewModel: viewModel,
      onBackClick: () => context.pop(),
    );
  }
}

