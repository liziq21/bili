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
      onLive: context.pushToLive,
      onSearch: context.pushToSearch,
      onSpace: context.pushToSpace,
      onVideo: context.pushToVideo,
    );
  }
}
