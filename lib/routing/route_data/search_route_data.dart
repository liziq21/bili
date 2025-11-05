part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void pushToSearch(String? query) => SearchRouteData(keyword: query).push(this);
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  final String? keyword;
  
  const SearchRouteData({this.keyword});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SearchScreen(
      initialQuery: keyword,
      onBackClick: () => context.pop(),
    );
  }
}

