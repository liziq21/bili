part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void navigateToVideo(String id, {String? source}) {
    if (source != null && read<MediaSourceCatalog>().find(source) == null) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(this)?.videoSourceUnavailable ??
                'Video source unavailable',
          ),
        ),
      );
      return;
    }

    // The route owns the source scope and performs the capability check after
    // creating the selected source. The caller may be outside that scope (for
    // example the media-library branch), so checking a context repository here
    // would incorrectly reject valid historical items.
    VideoRouteData(id: id, source: source).push(this);
  }
}

@TypedGoRoute<VideoRouteData>(path: '${Routes.video}/:id')
@immutable
class const VideoRouteData({
  required final String id,
  final String? source,
  final String? cid,
  final String? commentRootId,
  final String? commentSecondaryId,
  final String? dmProgress,
}) extends GoRouteData with $VideoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = _resolveSource(context, explicitSource: source);
    if (effectiveSource == null) {
      return NoMediaSourceScreen(
        message:
            AppLocalizations.of(context)?.videoSourceUnavailable ??
            'Video source unavailable',
      );
    }

    return ServiceSourceProviders(
      key: ValueKey('video:${effectiveSource.id}'),
      source: effectiveSource.id,
      child: Builder(
        builder: (context) {
          if (context.read<VideoDetailRepository?>() == null) {
            return NoMediaSourceScreen(
              message:
                  AppLocalizations.of(context)?.videoDetailSourceUnsupported ??
                  'Source does not support video details',
            );
          }
          return VideoScreen(videoId: id);
        },
      ),
    );
  }
}
