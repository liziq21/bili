part of '../router.dart';

@TypedGoRoute<HomeRouteData>(path: Routes.home)
@immutable
class HomeRouteData extends GoRouteData with $HomeRouteData {
  const HomeRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return HomeScreen(
      onLive: context.navigateToLive,
      onSearch: context.navigateToSearch,
      onSpace: context.navigateToSpace,
      onVideo: context.navigateToVideo,
    );
  }
}
