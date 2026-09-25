part of '../router.dart';

@TypedGoRoute<HomeRouteData>(path: Routes.home)
@immutable
class const HomeRouteData() extends GoRouteData with $HomeRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        userDataRepository: context.read(),
        mediaSources: context.read<List<MediaSource>>(),
      ),
      child: Builder(
        builder: (context) => _withSearchBloc(
          context,
          HomeScreen(
          onLive: (roomId) {
            final sourceId = context.read<HomeBloc>().activeSource?.id;
            if (sourceId == null) return;
            context.navigateToLive(roomId, source: sourceId);
          },
          navigateToSearchResult: (keyword) {
            final sourceId = context.read<HomeBloc>().activeSource?.id;
            if (sourceId == null) return;
            context.navigateToSearchResult(keyword, source: sourceId);
          },
          onSpace: (mid) {
            final sourceId = context.read<HomeBloc>().activeSource?.id;
            if (sourceId == null) return;
            context.navigateToSpace(mid, source: sourceId);
          },
            onVideo: (id) {
              final sourceId = context.read<HomeBloc>().activeSource?.id;
              if (sourceId == null) return;
              context.navigateToVideo(id, source: sourceId);
            },
          ),
        ),
      ),
    );
  }
}

/// 首页搜索入口复用 [SearchBloc] 提供联想建议；数据源没有建议能力时直接返回
/// 原 child，让 AppBar 隐藏搜索入口，而不是在缺少 bloc 时崩溃。
Widget _withSearchBloc(BuildContext context, Widget child) {
  if (context.read<SearchSuggestRepository?>() == null) return child;

  return BlocProvider<SearchBloc>(
    create: (context) => SearchBloc(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
    ),
    child: child,
  );
}
