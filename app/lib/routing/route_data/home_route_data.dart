part of '../router.dart';

@TypedGoRoute<HomeRouteData>(path: Routes.home)
@immutable
class HomeRouteData extends GoRouteData with $HomeRouteData {
  const HomeRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        userDataRepository: context.read(),
        mediaSources: context.read<List<MediaSource>>(),
      ),
      child: Builder(
        builder: (context) => HomeScreen(
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
    );
  }
}
