part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void navigateToSearchReault(String keyword) {
    SearchRouteData(keyword: keyword).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class SearchRouteData extends GoRouteData with $SearchRouteData {
  /*@TypedQueryParameter(name: 's') */ const SearchRouteData({required this.keyword});

  final String keyword;
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
          BlocProvider<SearchResultBloc<VideoModel>>(
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
