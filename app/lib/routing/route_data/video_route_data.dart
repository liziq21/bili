part of '../router.dart';

extension BuildContextVideo on BuildContext {
  void navigateToVideo(String id, {String? source}) {
    if (source != null && read<MediaSourceCatalog>().find(source) == null) {
      ScaffoldMessenger.of(this)
          .showSnackBar(const SnackBar(content: Text('视频所属的数据源不可用')));
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
      return const NoMediaSourceScreen(message: '视频所属的数据源不可用');
    }

    return ServiceSourceProviders(
      key: ValueKey('video:${effectiveSource.id}'),
      source: effectiveSource.id,
      child: Builder(
        builder: (context) {
          if (context.read<VideoDetailRepository?>() == null) {
            return const NoMediaSourceScreen(message: '当前数据源暂不支持查看视频详情');
          }
          return VideoScreen(videoId: id);
        },
      ),
    );
  }
}
