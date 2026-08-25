part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void navigateToSearchReault(String keyword) {
    SearchRouteData(keyword: keyword).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class const SearchRouteData({
  /*@TypedQueryParameter(name: 's') */ required final String keyword,
}) extends GoRouteData with $SearchRouteData {
  @override
  Widget build(context, _) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SearchBloc>(
          create: (context) => .new(
            searchSuggestRepository: context.read(),
            recentSearchQueryRepository: context.read(),
            getRentSearchQueriesUseCase: context.read(),
            initQuery: keyword,
          ),
        ),
        if (context.read<VideoSearchRepository?>()
            case final searchContentsRepo?)
          BlocProvider<SearchResultBloc<VideoInfoBase>>(
            create: (context) =>
                .new(searchContentsRepository: searchContentsRepo),
          ),
        if (context.read<CreatorProfileSearchRepository?>()
            case final searchContentsRepo?)
          BlocProvider<SearchResultBloc<CreatorProfile>>(
            create: (context) =>
                .new(searchContentsRepository: searchContentsRepo),
          ),
      ],
      child: SearchResultScreen(
        query: keyword,
        onBackClick: () => context.pop(),
      ),
    );
  }
}
