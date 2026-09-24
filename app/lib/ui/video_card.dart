import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';

enum VideoCardVariant() { defaultCard, feed }

class const VideoCard({
  super.key,
  required final VideoModel videoInfoBase,
  final GestureTapCallback? onTap,
  final VideoCardVariant variant = VideoCardVariant.defaultCard,
  final String? sourceBadge,
  final String? creatorAvatarUrl,
  final VoidCallback? onMorePressed,
}) extends StatelessWidget {
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String formatViewCount(int? count) {
    if (count == null) return '';
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  static String formatRelativeDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()} 年前';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()} 个月前';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }

  Widget _thumbnailPlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Icon(Icons.movie_outlined, color: colorScheme.onSurfaceVariant),
  );

  Widget _thumbnail(ColorScheme colorScheme) =>
      switch (videoInfoBase.thumbnailUrl) {
        final String url when url.isNotEmpty => CachedNetworkImage(
          imageUrl: url,
          memCacheWidth: 480,
          fit: BoxFit.cover,
          errorBuilder: (context, url, error) =>
              _thumbnailPlaceholder(colorScheme),
        ),
        _ => _thumbnailPlaceholder(colorScheme),
      };

  @override
  Widget build(BuildContext context) {
    if (variant == VideoCardVariant.feed) {
      final formattedViews = formatViewCount(videoInfoBase.viewCount);
      final formattedDate = formatRelativeDate(videoInfoBase.uploadDate);
      final feedSubtitle = formattedViews.isNotEmpty
          ? (formattedDate.isNotEmpty
                ? '$formattedViews 观看 • $formattedDate'
                : '$formattedViews 观看')
          : (formattedDate.isNotEmpty
                ? formattedDate
                : (videoInfoBase.uploadDate != null
                      ? '${videoInfoBase.uploadDate}'
                      : ''));
      return _buildFeedCard(context, feedSubtitle);
    }

    final subtitleText =
        '${videoInfoBase.viewCount} 观看 • ${videoInfoBase.uploadDate}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: videoInfoBase.title,
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: '${videoInfoBase.title}, $subtitleText',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图区域
                AspectRatio(
                  aspectRatio: 16 / 9, // 固定的 16:9
                  child: _thumbnail(Theme.of(context).colorScheme),
                ),
                // 文字区域：用 Expanded 承接剩下的所有空间
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          videoInfoBase.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, String subtitleText) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationStr = formatDuration(videoInfoBase.duration);
    final creatorName = videoInfoBase.creatorProfileName ?? '未知创作者';

    final semanticLabel = <String>[
      if (sourceBadge != null && sourceBadge!.isNotEmpty) sourceBadge!,
      videoInfoBase.title,
      '创作者: $creatorName',
      if (durationStr.isNotEmpty) '时长 $durationStr',
      if (subtitleText.isNotEmpty) subtitleText,
    ].join('，');

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular($styles.corners.md),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular($styles.corners.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabel,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图及覆盖 Badge 区域
                ExcludeSemantics(
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: videoInfoBase.thumbnailUrl ?? '',
                          memCacheWidth: 480,
                          fit: BoxFit.cover,
                          errorBuilder: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      // 顶部来源/平台 Badge
                      if (sourceBadge != null && sourceBadge!.isNotEmpty)
                        Positioned(
                          top: $styles.insets.xs,
                          left: $styles.insets.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: $styles.insets.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(
                                $styles.corners.sm,
                              ),
                            ),
                            child: Text(
                              sourceBadge!,
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      // 右下角时长 Badge
                      if (durationStr.isNotEmpty)
                        Positioned(
                          bottom: $styles.insets.xs,
                          right: $styles.insets.xs,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: $styles.insets.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(
                                $styles.corners.sm,
                              ),
                            ),
                            child: Text(
                              durationStr,
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 信息与 Creator 元数据区域
                Padding(
                  padding: EdgeInsets.all($styles.insets.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Creator 头像
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage:
                                    (creatorAvatarUrl != null &&
                                        creatorAvatarUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        creatorAvatarUrl!,
                                      )
                                    : null,
                                child:
                                    (creatorAvatarUrl == null ||
                                        creatorAvatarUrl!.isEmpty)
                                    ? Text(
                                        creatorName.isNotEmpty
                                            ? creatorName[0].toUpperCase()
                                            : '?',
                                        style: $styles.text.bodySmallBold
                                            .copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: $styles.insets.xs),

                              // 标题与次要信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      videoInfoBase.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: $styles.text.title2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                        height: 1.25,
                                      ),
                                    ),
                                    SizedBox(height: $styles.insets.xxs),
                                    Text(
                                      subtitleText.isNotEmpty
                                          ? '$creatorName • $subtitleText'
                                          : creatorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: $styles.text.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 更多操作按钮
                      if (onMorePressed != null)
                        IconButton(
                          tooltip: '更多选项',
                          icon: Icon(
                            Icons.more_vert_rounded,
                            semanticLabel: '更多选项',
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onMorePressed,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
