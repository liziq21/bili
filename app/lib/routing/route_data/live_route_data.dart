part of '../router.dart';

extension BuildContextLive on BuildContext {
  void navigateToLive(String roomId, {String? source}) =>
      LiveRouteData(roomId: roomId, source: source).push(this);
}

@TypedGoRoute<LiveRouteData>(path: '${Routes.live}/:roomId')
@immutable
class LiveRouteData extends GoRouteData with $LiveRouteData {
  const LiveRouteData({required this.roomId, this.source});

  final String roomId;
  final String? source;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = source ?? _resolveSource(context);

    return ServiceSourceProviders(
      source: effectiveSource,
      child: LiveScreen(roomId: roomId, onBackClick: () => context.pop()),
    );
  }
}
