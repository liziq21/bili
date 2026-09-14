part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void navigateToVideo(String id, {ServiceSource? source}) =>
      VideoRouteData(id: id, source: source).push(this);
}

@TypedGoRoute<VideoRouteData>(path: '${Routes.video}/:id')
@immutable
class VideoRouteData extends GoRouteData with $VideoRouteData {
  const VideoRouteData({
    required this.id,
    this.source,
    this.cid,
    this.commentRootId,
    this.commentSecondaryId,
    this.dmProgress,
  });

  final String id;
  final ServiceSource? source;
  final String? cid;
  final String? commentRootId;
  final String? commentSecondaryId;
  final String? dmProgress;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final effectiveSource = source ?? _resolveSource(context);

    return ServiceSourceProviders(
      source: effectiveSource,
      child: VideoScreen(videoId: id),
    );
  }
}
