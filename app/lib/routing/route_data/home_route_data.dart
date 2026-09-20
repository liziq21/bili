part of '../router.dart';

@TypedGoRoute<HomeRouteData>(path: Routes.home)
@immutable
class HomeRouteData extends GoRouteData with $HomeRouteData {
  const HomeRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(userDataRepository: context.read()),
      child: Builder(
        builder: (context) => HomeScreen(
          onLive: (roomId) {
            final source = context.read<HomeBloc>().state.sourceId;
            context.navigateToLive(roomId, source: source);
          },
          navigateToSearchResult: (keyword) {
            final source = context.read<HomeBloc>().state.sourceId;
            context.navigateToSearchResult(keyword, source: source);
          },
          onSpace: (mid) {
            final source = context.read<HomeBloc>().state.sourceId;
            context.navigateToSpace(mid, source: source);
          },
          onVideo: (id) {
            final source = context.read<HomeBloc>().state.sourceId;
            context.navigateToVideo(id, source: source);
          },
        ),
      ),
    );
  }
}
