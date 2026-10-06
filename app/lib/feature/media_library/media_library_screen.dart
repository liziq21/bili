import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../../ui/video_card.dart';
import 'media_history_cubit.dart';

/// 「我的」页（底部导航第三项）
///
/// 当前只承载「观看历史」。设计稿上的收藏 / 下载两个分段不搬：仓内既无对应表也无
/// DAO（`database/table/` 只有 media / video / article / post / creator_profile /
/// media_history / recent_search_query），做出来是两个点开空的分段。设计稿上的
/// 「批量管理」同样不搬——它绑定的是删除 / 移动操作，而历史表没有任何写接口，
/// 留一个按下去没反应的工具条比不给更差。等 LIZ-30 落地本地库再一起补。
///
/// 列表用行式而非网格：历史的语义是「按时间回看」，每条都要看清标题、来源与
/// 观看时间，行式一屏能放下条数更多；网格把每条压成小方块，时间信息挤在一行里。
///
/// [MediaHistoryCubit] 由路由提供：本页若自己再建一个，加载第一页会查询两次，
/// 而列表与翻页状态在两处实例上会各走各的。
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
          // ⚡ Bolt Optimization: Isolate header bar status text and load button rebuilds using BlocSelector.
          // Extracting (itemCount, hasError, isLoading, hasMore) into fine-grained selectors ensures
          // header UI only rebuilds when status flags change, saving unnecessary layout passes.
          BlocSelector<
            MediaHistoryCubit,
            MediaHistoryState,
            ({int itemCount, bool hasError, bool isLoading, bool hasMore})
          >(
            selector: (state) => (
              itemCount: state.items.length,
              hasError: state.error != null,
              isLoading: state.isLoading,
              hasMore: state.hasMore,
            ),
            builder: (context, headerState) {
              // 条数只反映已加载的部分：DAO 是分页查的，表里总数没查过，
              // 写「共 N 项」会让人以为这是全部，翻页后数字还会变。
              final label = headerState.itemCount == 0
                  ? '观看历史'
                  : '观看历史 · 已载入 ${headerState.itemCount} 条';

              // 出错且已经有条目时不整页替换：列表内容比错误更该被看见，
              // 但错误不能因此消失，所以在这里补一条。
              if (headerState.hasError && headerState.itemCount > 0) {
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<MediaHistoryCubit>().loadMore();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                );
              }

              // 加载期间保留按钮、只把它禁用：换成进度圈会让翻页入口
              // 忽隐忽现（列表为空时页内还有一个），读者刚要按就找不到。
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
                  // 只看 hasMore：整页都是文章 / 动态时列表会短暂为空，而视频在下一页。
                  // 附加 items.isNotEmpty 会把唯一的翻页入口一起关掉，那批视频再也到不了。
                  TextButton(
                    onPressed: headerState.hasMore && !headerState.isLoading
                        ? () {
                            HapticFeedback.lightImpact();
                            context.read<MediaHistoryCubit>().loadMore();
                          }
                        : null,
                    child: Text(headerState.hasMore ? '加载更多' : '没有更多了'),
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
///
/// 历史为空是正常状态（新装用户）而不是故障，所以与错误态分开表达。
class const _HistoryList({
  required final void Function(MediaHistoryItem item) onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Replace broad BlocBuilder with BlocSelector for non-content states (loading, error, empty).
    // When items are present, history rows are rendered via context.select in _HistoryRowsContent,
    // avoiding top-level list container rebuilds when unrelated state fields (e.g., error string changes) occur.
    return BlocSelector<
      MediaHistoryCubit,
      MediaHistoryState,
      ({bool isLoading, bool hasError, bool isEmpty})
    >(
      selector: (state) => (
        isLoading: state.isLoading,
        hasError: state.error != null,
        isEmpty: state.items.isEmpty,
      ),
      builder: (context, listState) {
        if (listState.isLoading && listState.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (listState.hasError && listState.isEmpty) {
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

        if (listState.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(icon: Icons.history_rounded, message: '还没有观看记录'),
          );
        }

        return _HistoryRowsContent(onVideoTap: onVideoTap);
      },
    );
  }
}

/// Content wrapper that selects items list specifically to isolate list row rebuilding.
class const _HistoryRowsContent({
  required final void Function(MediaHistoryItem item) onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = context.select<MediaHistoryCubit, List<MediaHistoryItem>>(
      (cubit) => cubit.state.items,
    );
    return _HistoryRows(items: items, onVideoTap: onVideoTap);
  }
}

/// 行式历史条目列表
///
/// 缩略图尺寸按可用宽度算并封顶：宽屏下固定尺寸会在行首留一大片空白，
/// 而封顶后条目宽度仍跟着窗口走，分隔线与标题左边缘始终对齐。
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
            // 分隔线自标题左边缘起（缩略图宽度 + 间距），不贯穿整行：
            // 贯穿会让每行读起来像表格，缩略图与文字之间的关系反而被切断。
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

  /// 数据源展示名
  ///
  /// 历史跨源存放，行上标出来源才看得出这条是哪个服务的；标识对不上任何已注册
  /// 数据源时留空，由 [_HistoryRow] 跳过徽章而不是显示原始标识。
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
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
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

  /// 副标题：来源 · 观看时间
  ///
  /// 历史条目没有播放量（media 表无该列），播放量与上传时间都不适用于「回看」
  /// 这个语境，因此只留来源与观看时间。
  String _subtitle(VideoModel video, String viewedAt) {
    final creator = video.creatorProfileName;
    final parts = <String>[
      if (sourceLabel != null && sourceLabel!.isNotEmpty) sourceLabel!,
      if (creator != null && creator.isNotEmpty) creator,
      viewedAt,
    ];
    return parts.join(' · ');
  }

  /// 观看时间的相对表述
  ///
  /// 用相对表述而不是绝对日期：历史是「回看」场景，「昨天 / 3 天前」比
  /// 「2026-10-02」更快传达新旧顺序。超过一周落到日期，跨年补上年份。
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
