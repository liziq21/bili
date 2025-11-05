part of '../router.dart';

extension BuildContextHome on BuildContext {
  void pushToHome() => HomeRouteData().push(this);
}

@TypedGoRoute<HomeRouteData>(path: Routes.home)
@immutable
class HomeRouteData extends GoRouteData with $HomeRouteData {
  const HomeRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(
      onLive: (roomId) => context.pushToLive(roomId),
      onSearch: (query) => context.pushToSearch(query),
      onSpace: (mid) => context.pushToSpace(mid),
      onVideo: (id) => context.pushToVideo(id),
    );
  }
}
