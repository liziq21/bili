part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void pushToSearch(String? keyword) {
    final viewModel = SearchViewModel(
      // searchRepository: context.read(),
      initialQuery: keyword,
    );
    SearchRouteData(viewModel).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  final SearchViewModel viewModel;

  const SearchRouteData(this.viewModel);

  @override
  Widget build(context, state) {
    return SearchScreen(
      viewModel: viewModel,
      onBackClick: () => context.pop(),
    );
  }
}

