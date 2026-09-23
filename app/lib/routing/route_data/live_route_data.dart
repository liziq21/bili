part of '../router.dart';

extension BuildContextLive on BuildContext {
  void navigateToLive(String roomId, {String? source}) =>
      LiveRouteData(roomId: roomId, source: source).push(this);
}

@TypedGoRoute<LiveRouteData>(path: '${Routes.live}/:roomId')
@immutable
class const LiveRouteData({required final String roomId, final String? source}) extends GoRouteData with $LiveRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = source ?? _resolveSource(context);

    return ServiceSourceProviders(
      source: effectiveSource,
      child: LiveScreen(roomId: roomId, onBackClick: () => context.pop()),
    );
  }
}
