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

  /// 以队列方式打开本地播放列表：首屏是 [videoIds] 的第一条，队列里带上全部
  /// 条目，起播后可以连续切歌。
  ///
  /// 播放列表条目的 `originalId` 可能不是任何一条视频的有效标识（历史数据、
  /// 源侧已删除），解析失败由视频页逐条跳过并汇报，这里不做预检。
  void navigateToPlaylist({
    required String source,
    required List<String> videoIds,
    int startIndex = 0,
  }) {
    if (videoIds.isEmpty) return;
    if (read<MediaSourceCatalog>().find(source) == null) {
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
    final start = startIndex.clamp(0, videoIds.length - 1).toInt();
    VideoRouteData(
      id: videoIds[start],
      source: source,
      queueSource: source,
      queueVideoIds: videoIds,
      queueStartIndex: start,
    ).push(this);
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

  /// 非空时以队列方式打开：[queueVideoIds] 是完整队列，[id] 必须等于其中
  /// [queueStartIndex] 位置上的条目。页面自身不参与 URL，队列随本次 push
  /// 传入，刷新后回到单条播放。
  final String? queueSource,
  final List<String>? queueVideoIds,
  final int? queueStartIndex,
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

    final queuedIds = queueVideoIds;
    final queue = queuedIds == null || queuedIds.isEmpty
        ? null
        : VideoQueueRequest(
            videoIds: queuedIds,
            startIndex: queueStartIndex ?? 0,
          );

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
          return VideoScreen(
            videoId: id,
            queue: queue,
            onBackClick: () => context.pop(),
          );
        },
      ),
    );
  }
}
