part of '../router.dart';

extension BuildContextSpace on BuildContext {
  void navigateToSpace(String mid) => SpaceRouteData(mid: mid).push(this);
}

@TypedGoRoute<SpaceRouteData>(path: '${Routes.space}/:mid')
@immutable
class SpaceRouteData extends GoRouteData with $SpaceRouteData {
  const SpaceRouteData({required this.mid});

  final String mid;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SpaceScreen(mid: mid, onBackClick: () => context.pop());
  }
}
