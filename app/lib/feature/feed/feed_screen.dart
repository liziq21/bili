import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/app_database.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../routing/navigation_callbacks.dart';
import '../home/widgets/feed_status_view.dart';
import 'feed_cubit.dart';
import 'widgets/feed_channel_section.dart';

/// 订阅动态页：已落库的订阅投稿按频道分组，组可展开/收起。
///
/// 页面只读本地数据（[FeedCubit] 订阅两个 Drift 查询流），远端拉取由
/// [FeedLoadManager] 在启动与下拉刷新时完成，因此这里没有「加载更多」：
/// 条目不是分页来的，是增量落库来的。
class const FeedScreen({
  super.key,
  final VideoNavCallback? onVideo,
  final bool sourceSupportsFeed = true,
}) extends StatelessWidget {
  Future<void> _onRefresh(BuildContext context) =>
      context.read<FeedCubit>().refresh();

  void _onEntryTap(BuildContext context, FeedEntryEntity entry) {
    // 先标记已读再跳转：跳转会卸载页面，await 之后再取 messenger / cubit
    // 就晚了。标记失败不影响播放。
    final cubit = context.read<FeedCubit>();
    if (!entry.isRead) {
      unawaited(cubit.markEntryRead(entry.channelId, entry.entryId));
    }
    onVideo?.call(entry.entryId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: $styles.insets.sm,
        title: Text(l10n?.feedTitle ?? 'Subscription feed'),
      ),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
          if (state.hasError) {
            return FeedStatusView.failure(
              title: l10n?.feedTitle ?? 'Subscription feed',
              onRetry: () => _onRefresh(context),
            );
          }
          if (!sourceSupportsFeed && state.isEmpty) {
            return FeedStatusView(
              icon: Icons.rss_feed_rounded,
              message:
                  l10n?.feedUnsupportedTitle ??
                  'This source has no subscription feed',
            );
          }
          if (state.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: $styles.insets.xxl),
                  FeedStatusView(
                    icon: Icons.rss_feed_rounded,
                    message: l10n?.feedEmptyTitle ?? 'No subscription updates',
                    description: l10n?.feedEmptyDescription,
                  ),
                ],
              ),
            );
          }

          final rows = _rowsFor(state);

          return RefreshIndicator(
            onRefresh: () => _onRefresh(context),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: $styles.insets.lg),
              itemCount: rows.length,
              itemBuilder: (context, index) => switch (rows[index]) {
                _ChannelRow(:final group) => FeedChannelHeader(
                  key: ValueKey(group.channelId),
                  group: group,
                  expanded: state.isExpanded(group.channelId),
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    context.read<FeedCubit>().toggleChannel(group.channelId);
                  },
                  onMarkChannelRead: () => context
                      .read<FeedCubit>()
                      .markChannelRead(group.channelId),
                ),
                _EntryRow(:final group, :final entry) => FeedEntryTile(
                  key: ValueKey('${group.channelId}/${entry.entryId}'),
                  entry: entry,
                  onTap: () => _onEntryTap(context, entry),
                ),
              },
            ),
          );
        },
      ),
    );
  }

  /// 展开的分组摊平成一份行列表，收起的分组只剩头部。
  ///
  /// 用扁平列表而不是「分组 → 子列表」的嵌套结构：收起时整组条目不进树，
  /// 列表也只为可见行建 widget，而不是先建出全部条目再隐藏。
  List<_FeedRow> _rowsFor(FeedState state) => [
    for (final group in state.groups) ...[
      _ChannelRow(group),
      if (state.isExpanded(group.channelId))
        for (final entry in group.entries) _EntryRow(group, entry),
    ],
  ];
}

/// 列表中的一行：频道头部或一条条目
sealed class _FeedRow();

final class _ChannelRow(final FeedChannelGroup group) extends _FeedRow;

final class _EntryRow(
  final FeedChannelGroup group,
  final FeedEntryEntity entry,
) extends _FeedRow;
