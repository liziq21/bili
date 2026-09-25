part of '../router.dart';

extension BuildContextSearch on BuildContext {
  void navigateToSearchResult(String keyword, {String? source}) {
    SearchRouteData(keyword: keyword, source: source).push(this);
  }
}

@TypedGoRoute<SearchRouteData>(path: Routes.search)
@immutable
class const SearchRouteData({
  required final String keyword,
  final String? source,
}) extends GoRouteData with $SearchRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = source ?? _resolveSource(context);

    return ServiceSourceProviders(
      source: effectiveSource,
      child: Builder(
        builder: (context) => MultiBlocProvider(
          providers: [
            if (context.read<SearchSuggestRepository?>() != null)
              BlocProvider<SearchBloc>(
                create: (context) => SearchBloc(
                  searchSuggestRepository: context.read(),
                  recentSearchQueryRepository: context.read(),
                  getRentSearchQueriesUseCase: context.read(),
                  initQuery: keyword,
                ),
              ),
            if (context.read<VideoSearchRepository?>()
                case final searchContentsRepo?)
              BlocProvider<SearchResultBloc<VideoModel>>(
                create: (context) => SearchResultBloc<VideoModel>(
                  searchContentsRepository: searchContentsRepo,
                ),
              ),
            if (context.read<CreatorProfileSearchRepository?>()
                case final searchContentsRepo?)
              BlocProvider<SearchResultBloc<CreatorProfile>>(
                create: (context) => SearchResultBloc<CreatorProfile>(
                  searchContentsRepository: searchContentsRepo,
                ),
              ),
          ],
          child: SearchResultScreen(
            query: keyword,
            onBackClick: () => context.pop(),
          ),
        ),
      ),
    );
  }
}
