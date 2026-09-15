part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void navigateToVideo(String id, {String? source}) {
    VideoDetailRepository? repo;
    try {
      repo = read<VideoDetailRepository?>();
    } catch (_) {
      repo = null;
    }

    if (repo != null) {
      VideoRouteData(id: id, source: source).push(this);
    } else {
      ScaffoldMessenger.of(this).showSnackBar(
        const SnackBar(
          content: Text('当前数据源暂不支持查看视频详情'),
        ),
      );
    }
  }
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
  final String? source;
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
