import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../../ui/common/utils/layout_breakpoints.dart';
import '../../ui/video_card.dart';
import 'media_history_cubit.dart';

/// 媒体资产页（底部导航第三项）
///
/// 当前只承载「观看历史」。收藏与下载不做：仓内既无对应表也无 DAO
///（`database/table/` 只有 media / video / article / post / creator_profile /
/// media_history / recent_search_query），主页的 `bookmarks` / `downloaded`
/// 筛选项至今仍是 [HomeFilterKind.placeholder]。给不出内容的导航项不做，
/// 避免点进去是空页。
///
/// [MediaHistoryCubit] 由路由提供：本页若自己再建一个，加载第一页会查询两次，
/// 而列表与翻页状态在两处实例上会各走各的。
class const MediaLibraryScreen({
  super.key,
  required this.onVideoTap,
}) extends StatelessWidget {
  /// 点按历史条目时的回调
  final void Function(MediaHistoryItem item) onVideoTap;

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
              // 只看 hasMore：整页都是文章 / 动态时列表会短暂为空，而视频在下一页。
              // 附加 items.isNotEmpty 会把唯一的翻页入口一起关掉，那批视频再也到不了。
              return TextButton(
                onPressed: state.hasMore
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
class const _HistoryList({required this.onVideoTap}) extends StatelessWidget {
  final void Function(MediaHistoryItem item) onVideoTap;

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
  final List<MediaHistoryItem> items;
  final void Function(MediaHistoryItem item) onVideoTap;

  /// 单张视频卡片高度：封面 16:9 + 文字区块，随字体缩放变化
  ///
  /// 与 `home/widgets/video_feed_section.dart` 的同名静态方法同一套算法，两处各算
  /// 一次：共用需要把度量从 home 的部件里挪到公共位置，不在本页顺手做。
  static double cardExtent(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleHeight =
        textScaler.scale($styles.text.title2.fontSize ?? 14) * 1.25 * 2;
    final subtitleHeight =
        textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4;
    return cardWidth * 9 / 16 +
        titleHeight +
        subtitleHeight +
        $styles.insets.sm * 2 +
        $styles.insets.xxs;
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        $styles.insets.sm,
        $styles.insets.xs,
        $styles.insets.sm,
        $styles.insets.xl,
      ),
      // 列数按网格的实际可用宽度算：宽屏下侧边导航栏与分隔线已经占掉一部分宽度，
      // 用整屏宽度会在临界点多选一列，卡片被挤窄。
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = LayoutSize.fromWidth(width).feedColumnsFor(width);
          final spacing = $styles.insets.sm;
          final cardWidth = (width - spacing * (columns - 1)) / columns;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              // 高度由封面 16:9 + 文字区块推导，不写固定宽高比：字体放大后
              // 固定比例会把标题裁掉。
              mainAxisExtent: cardExtent(context, cardWidth),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return VideoCard(
                  // 用 feed 变体：历史条目没有播放量与时长（media 表无对应列），
                  // defaultCard 会把 null 直接拼进副标题渲染成「null 观看」。
                  variant: VideoCardVariant.feed,
                  videoInfoBase: item.video,
                  sourceBadge: _sourceLabel(context, item.sourceId),
                  onTap: () => onVideoTap(item),
                );
              },
              childCount: items.length,
            ),
          );
        },
      ),
    );
  }

  /// 数据源展示名
  ///
  /// 历史跨源存放，卡片上标出来源才看得出这条是哪个服务的；标识对不上任何已注册
  /// 数据源时留空，由 [VideoCard] 跳过徽章而不是显示原始标识。
  static String? _sourceLabel(BuildContext context, String sourceId) {
    for (final source in context.mediaSources) {
      if (source.id == sourceId) return source.name;
    }
    return null;
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
