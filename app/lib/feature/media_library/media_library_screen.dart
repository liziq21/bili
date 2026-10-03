import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../../ui/video_card.dart';
import 'media_history_cubit.dart';

/// 「我的」页（底部导航第三项）
class const MediaLibraryScreen({
  super.key,

  /// 点按历史条目时的回调
  required final void Function(MediaHistoryItem item) onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            _HistoryList(onVideoTap: onVideoTap),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的',
            style: $styles.text.h3.copyWith(color: colorScheme.onSurface),
          ),
          SizedBox(height: $styles.insets.sm),
          BlocBuilder<MediaHistoryCubit, MediaHistoryState>(
            builder: (context, state) {
              final label = state.items.isEmpty
                  ? '观看历史'
                  : '观看历史 · 已载入 ${state.items.length} 条';

              if (state.error != null && state.items.isNotEmpty) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$label · 加载失败',
                        style: $styles.text.bodySmall.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<MediaHistoryCubit>().loadMore(),
                      child: const Text('重试'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: $styles.text.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: state.hasMore && !state.isLoading
                        ? () => context.read<MediaHistoryCubit>().loadMore()
                        : null,
                    child: Text(state.hasMore ? '加载更多' : '没有更多了'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 历史列表：加载中 / 出错 / 空 / 有内容 四态
class const _HistoryList({
  required final void Function(MediaHistoryItem item) onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaHistoryCubit, MediaHistoryState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.error != null && state.items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(
              icon: Icons.error_outline_rounded,
              message: '历史记录加载失败',
              actionLabel: '重试',
              onAction: () => context.read<MediaHistoryCubit>().loadMore(),
            ),
          );
        }

        if (state.items.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(icon: Icons.history_rounded, message: '还没有观看记录'),
          );
        }

        return _HistoryRows(items: state.items, onVideoTap: onVideoTap);
      },
    );
  }
}

/// 行式历史条目列表
class const _HistoryRows({
  required final List<MediaHistoryItem> items,
  required final void Function(MediaHistoryItem item) onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final thumbWidth = (width * 0.32).clamp(96.0, 200.0);

        return SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: MediaQuery.textScalerOf(context).scale(1),
            indent: thumbWidth + $styles.insets.sm,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _HistoryRow(
              item: item,
              thumbWidth: thumbWidth,
              sourceLabel: _sourceLabel(context, item.sourceId),
              onTap: () => onVideoTap(item),
            );
          },
        );
      },
    );
  }

  static String? _sourceLabel(BuildContext context, String sourceId) {
    for (final source in context.mediaSources) {
      if (source.id == sourceId) return source.name;
    }
    return null;
  }
}

/// 单条历史：左缩略图 + 右标题 / 来源 / 时间
class const _HistoryRow({
  required final MediaHistoryItem item,
  required final double thumbWidth,
  required final VoidCallback onTap,
  final String? sourceLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final video = item.video;
    final duration = VideoCard.formatDuration(video.duration);
    final viewedAtLabel = _formatViewedAt(item.viewedAt);

    return Tooltip(
      message: video.title,
      child: Semantics(
        button: true,
        label: <String>[
          if (sourceLabel != null && sourceLabel!.isNotEmpty) sourceLabel!,
          video.title,
          if (duration.isNotEmpty) '时长 $duration',
          '观看于 $viewedAtLabel',
        ].join('，'),
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: $styles.insets.sm,
              vertical: $styles.insets.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: thumbWidth,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular($styles.corners.sm),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _thumbnail(video.thumbnailUrl, colorScheme),
                            if (duration.isNotEmpty)
                              Positioned(
                                bottom: $styles.insets.xxs,
                                right: $styles.insets.xxs,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: $styles.insets.xxs,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: $styles.colors.scrim.withValues(
                                      alpha: 0.75,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      $styles.corners.sm,
                                    ),
                                  ),
                                  child: Text(
                                    duration,
                                    style: $styles.text.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: $styles.colors.onScrim,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: $styles.insets.sm),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
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
                          _subtitle(video, viewedAtLabel),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(String? url, ColorScheme colorScheme) => switch (url) {
    final String value when value.isNotEmpty => CachedNetworkImage(
      imageUrl: value,
      memCacheWidth: 240,
      fit: BoxFit.cover,
      errorBuilder: (context, url, error) => _placeholder(colorScheme),
    ),
    _ => _placeholder(colorScheme),
  };

  Widget _placeholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Icon(Icons.movie_outlined, color: colorScheme.onSurfaceVariant),
  );

  String _subtitle(VideoModel video, String viewedAt) {
    final creator = video.creatorProfileName;
    final parts = <String>[
      if (sourceLabel != null && sourceLabel!.isNotEmpty) sourceLabel!,
      if (creator != null && creator.isNotEmpty) creator,
      viewedAt,
    ];
    return parts.join(' · ');
  }

  static String _formatViewedAt(DateTime viewedAt) {
    final difference = DateTime.now().difference(viewedAt);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    final now = DateTime.now();
    final sameYear = viewedAt.year == now.year;
    final month = viewedAt.month.toString().padLeft(2, '0');
    final day = viewedAt.day.toString().padLeft(2, '0');
    return sameYear ? '$month-$day' : '${viewedAt.year}-$month-$day';
  }
}

/// 空态 / 错误态的统一版式
class const _Message({
  required final IconData icon,
  required final String message,
  final String? actionLabel,
  final VoidCallback? onAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: $styles.insets.sm),
          Text(
            message,
            style: $styles.text.body.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAction != null) ...[
            SizedBox(height: $styles.insets.xs),
            TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
          ],
        ],
      ),
    );
  }
}
