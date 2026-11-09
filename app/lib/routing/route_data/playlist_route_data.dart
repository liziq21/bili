part of '../router.dart';

extension BuildContextPlaylist on BuildContext {
  void navigateToPlaylist(String playlistId, {String? source}) =>
      PlaylistRouteData(playlistId: playlistId, source: source).push(this);
}

@TypedGoRoute<PlaylistRouteData>(path: '${Routes.playlist}/:playlistId')
@immutable
class const PlaylistRouteData({
  required final String playlistId,
  final String? source,
}) extends GoRouteData with $PlaylistRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = _resolveSource(context, explicitSource: source);
    if (effectiveSource == null) {
      return NoMediaSourceScreen(
        message:
            AppLocalizations.of(context)?.playlistSourceUnavailable ??
            'Playlist source unavailable',
      );
    }

    return ServiceSourceProviders(
      source: effectiveSource.id,
      child: PlaylistScreen(
        playlistId: playlistId,
        onBackClick: () => context.pop(),
      ),
    );
  }
}
