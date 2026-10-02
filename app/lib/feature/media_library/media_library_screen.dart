import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../ui/common/utils/layout_breakpoints.dart';
import '../../ui/video_card.dart';
import 'media_history_cubit.dart';

/// 媒体资产页（底部导航第三项）
///
/// 当前只承载「观看历史」。收藏与下载不做：仓内既无对应表也无 DAO
/// （`database/table/` 只有 media / video / article / post / creator_profile /
/// media_history / recent_search_query），主页的 `bookmarks` / `downloaded`
/// 筛选项至今仍是 [HomeFilterKind.placeholder]。给不出内容的导航项不做，
/// 避免点进去是空页。
class const MediaLibraryScreen({
  super.key,
  required this.onVideoTap,
  this.pageSize = 20,
}) extends StatelessWidget {
  /// 点按历史条目时的回调
  final void Function(VideoModel video) onVideoTap;

  /// 单页加载的条数
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MediaHistoryCubit(
        mediaHistoryDao: context.read(),
        pageSize: pageSize,
      ),
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _header(context),
              ),
              _HistoryList(onVideoTap: onVideoTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.sm,
        $styles.insets.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '观看历史',
              style: $styles.text.h3?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          BlocBuilder<MediaHistoryCubit, MediaHistoryState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return TextButton(
                onPressed: state.hasMore && state.items.isNotEmpty
                    ? () => context.read<MediaHistoryCubit>().loadMore()
                    : null,
                child: Text(state.hasMore ? '加载更多' : '没有更多了'),
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
  required this.onVideoTap,
}) extends StatelessWidget {
  final void Function(VideoModel video) onVideoTap;

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
            child: _Message(
              icon: Icons.history_rounded,
              message: '还没有观看记录',
            ),
          );
        }

        return _MediaGrid(items: state.items, onVideoTap: onVideoTap);
      },
    );
  }
}

/// 历史条目的响应式网格
class const _MediaGrid({
  required this.items,
  required this.onVideoTap,
}) extends StatelessWidget {
  final List<VideoModel> items;
  final void Function(VideoModel video) onVideoTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = LayoutSize.fromWidth(width).feedColumnsFor(width);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.sm,
        $styles.insets.xl,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: $styles.insets.sm,
          crossAxisSpacing: $styles.insets.sm,
          // 卡片高由封面 16:9 + 两行文字推导，不写固定宽高比：字体放大后
          // 固定比例会把标题裁掉。
          childAspectRatio: _cardAspectRatio(context, width / columns),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = items[index];
            return VideoCard(
              videoInfoBase: video,
              onTap: () => onVideoTap(video),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  static double _cardAspectRatio(BuildContext context, double cardWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    final titleHeight =
        scaler.scale($styles.text.title2.fontSize ?? 14) * 1.25 * 2;
    final subtitleHeight =
        scaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4;
    final totalHeight =
        cardWidth * 9 / 16 +
        titleHeight +
        subtitleHeight +
        $styles.insets.sm * 2 +
        $styles.insets.xxs;
    return cardWidth / totalHeight;
  }
}

/// 空态 / 错误态的统一版式
class const _Message({
  required this.icon,
  required this.message,
  this.actionLabel,
  this.onAction,
}) extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
            style: $styles.text.body?.copyWith(
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
