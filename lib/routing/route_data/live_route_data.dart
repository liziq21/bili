part of '../router.dart';

extension BuildContextLive on BuildContext {
  void navigateToLive(String roomId) => LiveRouteData(roomId: roomId).push(this);
}

@TypedGoRoute<LiveRouteData>(path: '${Routes.live}/:roomId')
@immutable
class LiveRouteData extends GoRouteData with $LiveRouteData {
  final String roomId;
  
  const LiveRouteData({ required this.roomId });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LiveScreen(
      roomId: roomId,
      onBackClick: () => context.pop(),
    );
  }
}

