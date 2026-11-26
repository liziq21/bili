import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../../routing/navigation_callbacks.dart';
import '../../ui/video_card.dart';
import 'media_history_cubit.dart';

/// 「我的」页（底部导航第三项）
///
/// 当前只承载「观看历史」。收藏、下载和批量管理由本地库的其他功能负责，
/// 这里保持历史列表自身的分页、来源标识和导航行为。
///
/// 列表用行式而非网格：历史的语义是「按时间回看」，每条都要看清标题、来源与
/// 观看时间，行式一屏能放下条数更多；网格把每条压成小方块，时间信息挤在一行里。
///
/// [MediaHistoryCubit] 由路由提供：本页若自己再建一个，加载第一页会查询两次，
/// 而列表与翻页状态在两处实例上会各走各的。
class const MediaLibraryScreen({
  super.key,

  /// 点按历史条目时的回调
  final MediaLibraryVideoNavCallback? onVideoTap,
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
    final l10n = AppLocalizations.of(context);
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
          // 页面的一级标题由 LocalLibraryScreen 的 AppBar 提供（「我的」）。
          // 这里原先还有一个「我的」H3，和 AppBar 的「本地库」同屏并存两个
          // 不同的页名，且只有历史 Tab 多出这一段（#666）。分组信息已经在
          // 下一行的「观看历史 · 已载入 N 条」里，不再重复。
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
              final buttonEnabled = _loadMoreButtonEnabled(
                hasMore: headerState.hasMore,
                isLoading: headerState.isLoading,
              );
              // 条数只反映已加载的部分：DAO 是分页查的，表里总数没查过，
              // 写「共 N 项」会让人以为这是全部，翻页后数字还会变。
              final label = headerState.itemCount == 0
                  ? (l10n?.watchHistory ?? 'Watch history')
                  : l10n?.watchHistoryLoadedCount('${headerState.itemCount}') ??
                        'Watch history';

              // 出错且已经有条目时不整页替换：列表内容比错误更该被看见，
              // 但错误不能因此消失，所以在这里补一条。
              if (headerState.hasError && headerState.itemCount > 0) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.tabLoadFailed(label) ?? label,
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.errorText,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<MediaHistoryCubit>().loadMore();
                      },
                      child: Text(l10n?.retry ?? 'Retry'),
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
                  // 清空入口同样常驻、只按状态禁用：出现/消失会让整行文字在
                  // 删除最后一条的瞬间横跳。
                  IconButton(
                    onPressed: headerState.itemCount == 0
                        ? null
                        : () => unawaited(_confirmClearHistory(context)),
                    tooltip:
                        l10n?.clearAllWatchHistory ?? 'Clear all watch history',
                    icon: const Icon(AppIcons.deleteSweep),
                  ),
                  // 只看 hasMore：整页都是文章 / 动态时列表会短暂为空，而视频在下一页。
                  // 附加 items.isNotEmpty 会把唯一的翻页入口一起关掉，那批视频再也到不了。
                  //
                  // 没有下一页时这里不再放「没有更多了」：工具条在列表之前，
                  // 读者会先读到结束标记再看到下面还有记录。结束标记改由列表
                  // 末尾的 [_HistoryFooter] 承载。
                  if (headerState.hasMore)
                    Tooltip(
                      message: tooltipMessage(l10n, headerState: headerState),
                      child: Semantics(
                        button: true,
                        enabled: buttonEnabled,
                        label: tooltipMessage(l10n, headerState: headerState),
                        child: TextButton(
                          onPressed: buttonEnabled
                              ? () {
                                  HapticFeedback.lightImpact();
                                  context.read<MediaHistoryCubit>().loadMore();
                                }
                              : null,
                          child: Text(l10n?.loadMore ?? 'Load more'),
                        ),
                      ),
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

bool _loadMoreButtonEnabled({required bool hasMore, required bool isLoading}) =>
    hasMore && !isLoading;

/// 清空全部历史：先确认再删，删除后给出可感知的结果提示
///
/// 清空不可撤销，所以确认对话框是唯一入口，不提供「长按一次就清空」的快捷路径。
Future<void> _confirmClearHistory(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<MediaHistoryCubit>();
  // 对话框与删除都会让发起调用的 context 退出树（列表清空后整段重建），
  // messenger 必须先取好，否则提示发不出去。
  final messenger = ScaffoldMessenger.of(context);
  unawaited(HapticFeedback.mediumImpact());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n?.clearWatchHistoryConfirm ?? 'Clear all watch history?'),
      content: Text(
        l10n?.clearWatchHistoryMessage ??
            'This removes every entry from your watch history. '
                'The action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n?.delete ?? 'Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final cleared = await cubit.clearAll();
  if (!cleared) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n?.watchHistoryCleared ?? 'Watch history cleared'),
      ),
    );
}

/// 删除单条历史：确认后删库并提示
///
/// 长按而不是常驻删除按钮：历史行是回看入口，误触删除的代价比多点一次长按高。
Future<void> _confirmDeleteHistoryItem(
  BuildContext context,
  MediaHistoryItem item,
) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<MediaHistoryCubit>();
  // 删除后这一行本身就从树里消失，发起调用的 context 随即失效。
  final messenger = ScaffoldMessenger.of(context);
  unawaited(HapticFeedback.mediumImpact());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        l10n?.deleteHistoryItemConfirm(item.video.title) ??
            'Delete "${item.video.title}" from history?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n?.delete ?? 'Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final removed = await cubit.removeItem(item);
  if (!removed) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n?.historyItemRemoved ?? 'Removed from history'),
      ),
    );
}

String tooltipMessage(
  AppLocalizations? l10n, {
  required ({int itemCount, bool hasError, bool isLoading, bool hasMore})
  headerState,
}) {
  if (headerState.isLoading) {
    return l10n?.loadingHistory ?? 'Loading history...';
  }
  return l10n?.loadMoreHistory ?? 'Load more history';
}

/// 历史列表：加载中 / 出错 / 空 / 有内容 四态
///
/// 历史为空是正常状态（新装用户）而不是故障，所以与错误态分开表达。
class const _HistoryList({final MediaLibraryVideoNavCallback? onVideoTap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              icon: AppIcons.error,
              message: l10n?.historyLoadFailed ?? 'Failed to load history',
              actionLabel: l10n?.retry ?? 'Retry',
              onAction: () => context.read<MediaHistoryCubit>().loadMore(),
            ),
          );
        }

        if (listState.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(
              icon: AppIcons.history,
              message: l10n?.noWatchHistory ?? 'No watch history yet',
            ),
          );
        }

        return _HistoryRowsContent(onVideoTap: onVideoTap);
      },
    );
  }
}

/// Content wrapper that selects list data to isolate list row rebuilding.
class const _HistoryRowsContent({
  final MediaLibraryVideoNavCallback? onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = context
        .select<
          MediaHistoryCubit,
          ({
            List<MediaHistoryItem> items,
            Map<MediaHistoryProgressKey, MediaHistoryProgress> progressByMedia,
            bool hasMore,
          })
        >(
          (cubit) => (
            items: cubit.state.items,
            progressByMedia: cubit.state.progressByMedia,
            hasMore: cubit.state.hasMore,
          ),
        );
    return _HistoryRows(
      items: history.items,
      progressByMedia: history.progressByMedia,
      hasMore: history.hasMore,
      onVideoTap: onVideoTap,
    );
  }
}

/// 行式历史条目列表
///
/// 缩略图尺寸按可用宽度算并封顶：宽屏下固定尺寸会在行首留一大片空白，
/// 而封顶后条目宽度仍跟着窗口走，分隔线与标题左边缘始终对齐。
class const _HistoryRows({
  required final List<MediaHistoryItem> items,
  required final Map<MediaHistoryProgressKey, MediaHistoryProgress>
  progressByMedia,
  required final bool hasMore,
  final MediaLibraryVideoNavCallback? onVideoTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Pre-compute source name lookup map and divider style parameters.
    // Reading the immutable catalog once at the top of _HistoryRows avoids repeated
    // InheritedWidget lookups and list iterations per item built on scroll.
    final sourceNames = {
      for (final source in context.mediaSourceDefinitions)
        source.id: source.name,
    };

    return SliverMainAxisGroup(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final thumbWidth = (width * 0.32).clamp(96.0, 200.0);
            final dividerThickness = MediaQuery.textScalerOf(context).scale(1);
            final dividerIndent = thumbWidth + $styles.insets.sm;
            final dividerColor = Theme.of(context).colorScheme.outlineVariant;

            return SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: dividerThickness,
                // 分隔线自标题左边缘起（缩略图宽度 + 间距），不贯穿整行：
                // 贯穿会让每行读起来像表格，缩略图与文字之间的关系反而被切断。
                indent: dividerIndent,
                color: dividerColor,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final navigate = onVideoTap;
                return _HistoryRow(
                  item: item,
                  progress:
                      progressByMedia[(
                        sourceId: item.sourceId,
                        originalId: item.video.id,
                      )],
                  thumbWidth: thumbWidth,
                  sourceLabel: sourceNames[item.sourceId],
                  onTap: navigate == null
                      ? null
                      : () => navigate(item.sourceId, item.video.id),
                  onLongPress: () =>
                      unawaited(_confirmDeleteHistoryItem(context, item)),
                );
              },
            );
          },
        ),
        // 结束标记必须跟最后一条记录之后，而不是列表之前的工具条里。
        if (!hasMore) const SliverToBoxAdapter(child: _HistoryFooter()),
      ],
    );
  }
}

/// 列表末尾的「没有更多了」：只在确实列出了一条以上记录时出现。
///
/// 空态已有自己的空列表提示，再补一条「没有更多了」等于告诉读者列表底部
/// 还有内容可以看。
class const _HistoryFooter() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: $styles.insets.md),
      child: Center(
        child: Text(
          l10n.noMoreItems,
          style: $styles.text.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 单条历史：左缩略图 + 右标题 / 来源 / 时间
class const _HistoryRow({
  required final MediaHistoryItem item,
  final MediaHistoryProgress? progress,
  required final double thumbWidth,
  required final VoidCallback? onTap,
  final VoidCallback? onLongPress,
  final String? sourceLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final video = item.video;
    final duration = VideoCard.formatDuration(video.duration);
    final viewedAtLabel = _formatViewedAt(item.viewedAt, l10n);
    final progressLabel = _formatProgress(progress, l10n);
    final progressSemantics = switch (progressLabel) {
      final label? => [label],
      _ => const <String>[],
    };

    // `excludeSemantics: true` drops the InkWell's own actions, so tap and
    // long-press both have to be declared on the Semantics node as well.
    void handleTap() {
      HapticFeedback.lightImpact();
      onTap?.call();
    }

    final tapHandler = onTap == null ? null : handleTap;

    return Tooltip(
      message: video.title,
      child: Semantics(
        button: true,
        label: <String?>[
          if (sourceLabel != null && sourceLabel!.isNotEmpty) sourceLabel!,
          video.title,
          if (duration.isNotEmpty) l10n?.durationLabel(duration),
          ...progressSemantics,
          l10n?.watchedAt(viewedAtLabel),
        ].whereType<String>().join(l10n?.commaSeparator ?? ','),
        onTap: tapHandler,
        onLongPress: onLongPress,
        excludeSemantics: true,
        child: InkWell(
          onTap: tapHandler,
          onLongPress: onLongPress,
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
                          _subtitle(video, viewedAtLabel, progressLabel, l10n),
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
    child: Icon(AppIcons.movie, color: colorScheme.onSurfaceVariant),
  );

  /// 副标题：来源 · 播放进度 · 观看时间
  ///
  /// 历史条目没有播放量（media 表无该列），播放量与上传时间都不适用于「回看」
  /// 这个语境，因此只留来源、播放进度与观看时间。
  String _subtitle(
    VideoModel video,
    String viewedAt,
    String? progressLabel,
    AppLocalizations? l10n,
  ) {
    final creator = video.creatorProfileName;
    final progressParts = switch (progressLabel) {
      final label? => [label],
      _ => const <String>[],
    };
    final parts = <String>[
      if (sourceLabel != null && sourceLabel!.isNotEmpty) sourceLabel!,
      if (creator != null && creator.isNotEmpty) creator,
      ...progressParts,
      viewedAt,
    ];
    return parts.join(l10n?.spacedDot ?? ' - ');
  }

  /// Formats saved progress without requiring a duration in the media cache.
  static String? _formatProgress(
    MediaHistoryProgress? progress,
    AppLocalizations? l10n,
  ) {
    if (progress == null) return null;
    if (progress.completed) return l10n?.finishedWatching ?? 'Finished';
    final seconds = progress.progressSeconds;
    final formatted = VideoCard.formatDuration(seconds);
    if (formatted.isEmpty) return null;
    return l10n?.watchedDuration(formatted);
  }

  /// 观看时间的相对表述
  ///
  /// 用相对表述而不是绝对日期：历史是「回看」场景，「昨天 / 3 天前」比
  /// 「2026-10-02」更快传达新旧顺序。超过一周落到日期，跨年补上年份。
  static String _formatViewedAt(DateTime viewedAt, AppLocalizations? l10n) {
    // ⚡ Bolt Optimization: Instantiate system clock time once per row format.
    final now = DateTime.now();
    final difference = now.difference(viewedAt);
    if (difference.inMinutes < 1) return l10n?.justNow ?? 'Just now';
    if (difference.inHours < 1) {
      return l10n?.minutesAgo(difference.inMinutes) ?? 'Just now';
    }
    if (difference.inDays < 1) {
      return l10n?.hoursAgo(difference.inHours) ?? 'Earlier today';
    }
    if (difference.inDays < 7) {
      return l10n?.daysAgo(difference.inDays) ?? 'This week';
    }
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
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAction?.call();
              },
              child: Text(actionLabel ?? ''),
            ),
          ],
        ],
      ),
    );
  }
}
