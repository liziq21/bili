part of '../router.dart';

extension BuildContextLive on BuildContext {
  void navigateToLive(String roomId, {String? source}) =>
      LiveRouteData(roomId: roomId, source: source).push(this);
}

@TypedGoRoute<LiveRouteData>(path: '${Routes.live}/:roomId')
@immutable
class const LiveRouteData({required final String roomId, final String? source})
    extends GoRouteData
    with $LiveRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = _resolveSource(context, explicitSource: source);
    if (effectiveSource == null) {
      return NoMediaSourceScreen(
        message:
            AppLocalizations.of(context)?.liveSourceUnavailable ??
            'Live source unavailable',
      );
    }

    return ServiceSourceProviders(
      source: effectiveSource.id,
      child: LiveScreen(roomId: roomId, onBackClick: () => context.pop()),
    );
  }
}
