part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void navigateToVideo(String id) => VideoRouteData(id: id).push(this);
}

@TypedGoRoute<VideoRouteData>(path: '${Routes.video}/:id')
@immutable
class VideoRouteData extends GoRouteData with $VideoRouteData {
  const VideoRouteData({
    required this.id,
    this.cid,
    this.commentRootId,
    this.commentSecondaryId,
    this.dmProgress,
  });

  final String id;
  final String? cid;
  final String? commentRootId;
  final String? commentSecondaryId;
  final String? dmProgress;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return VideoScreen(
      onBackClick: () => context.pop(),
      parameters: VideoParameters(
        id: id,
        cid: cid,
        commentRootId: commentRootId,
        commentSecondaryId: commentSecondaryId,
        dmProgress: dmProgress,
      ),
    );
  }
}
