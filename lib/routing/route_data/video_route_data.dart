part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void pushToVideo(String id) => VideoRouteData(id: id).push(this);
}

@TypedGoRoute<VideoRouteData>(path: '${Routes.video}/:id')
@immutable
class VideoRouteData extends GoRouteData with $VideoRouteData {
  final String id;
  final String? cid;
  final String? comment_root_id;
  final String? comment_secondary_id;
  final String? dm_progress;
  
  const VideoRouteData({
    required this.id,
    this.cid,
    this.comment_root_id,
    this.comment_secondary_id,
    this.dm_progress,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return VideoScreen(
      onBackClick: () => context.pop(),
      parameters: VideoParameters(
        id: id,
        cid: cid,
        commentRootId: comment_root_id,
        commentSecondaryId: comment_secondary_id,
        dmProgress: dm_progress,
      ),
    );
  }
}
