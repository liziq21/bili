import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/motion.dart';
import '../../../main.dart';
import '../bloc/video_bloc.dart';

String _formatCount(int count) {
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}万';
  }
  return '$count';
}

// ⚡ Bolt Optimization: Extracted static recommendations into compile-time const widgets.
// Avoids re-instantiating list of maps, closures, text style copyWith objects,
// and non-const layout widgets during VideoBloc state emissions.
const List<_RelatedVideoCard> _relatedVideoCards = [
  _RelatedVideoCard(
    title: 'Flutter 3.24 全新渲染管线实战指南：自定义着色器与深度渲染',
    author: 'CodeCraft',
    views: '14.2万',
    source: 'BILIBILI',
    time: '4天前',
    duration: '12:40',
    onTap: null,
  ),
  _RelatedVideoCard(
    title: 'Why Flutter\'s Impeller Engine Changes Everything for Cross-Platform Devs',
    author: 'Flutter Dev Hub',
    views: '290K views',
    source: 'YOUTUBE',
    time: '1周前',
    duration: '18:15',
    onTap: null,
  ),
  _RelatedVideoCard(
    title: '跨平台框架底层图形层横评：React Native Fabric vs Flutter Impeller',
    author: '开源音频周刊',
    views: '3.8万收听',
    source: 'PEERTUBE / RSS',
    time: '3天前',
    duration: '45:20',
    onTap: null,
  ),
];

class const VideoInfoView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Use BlocSelector to check top-level loading/error/hasDetail state.
    // Isolates status view (loading / error) from frequent child state updates (e.g. like, favorite, subscribe).
    return BlocSelector<
      VideoBloc,
      VideoState,
      ({bool isLoading, Object? error, bool hasDetail})
    >(
      selector: (state) => (
        isLoading: state.isLoading,
        error: state.error,
        hasDetail: state.videoDetail != null,
      ),
      builder: (context, status) {
        if (status.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: CircularProgressIndicator(
                color: $styles.colors.accentFill,
              ),
            ),
          );
        }

        if (status.error != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Text(
                '视频加载失败，请重试',
                style: $styles.text.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (!status.hasDetail) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: EdgeInsets.all($styles.insets.sm),
          children: [
            const _VideoHeaderSection(),
            Gap($styles.insets.sm),
            const _CreatorProfileSection(),
            Gap($styles.insets.sm),
            const _ActionButtonsSection(),
            Divider(color: $styles.colors.outline.withValues(alpha: 0.2)),
            const _SynopsisSection(),
            Gap($styles.insets.md),
            const _RecommendationsHeader(),
            Gap($styles.insets.xs),
            ..._relatedVideoCards,
          ],
        );
      },
    );
  }
}

class const _VideoHeaderSection() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Scoped selector for VideoModel fields (title, viewCount, id).
    // Prevents header from rebuilding when user likes, favorites, or subscribes.
    final video = context.select<VideoBloc, VideoModel?>(
      (bloc) => bloc.state.videoDetail?.video,
    );
    if (video == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Title
        Text(
          video.title,
          style: $styles.text.h3.copyWith(
            color: $styles.colors.onSurfaceStrong,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        Gap($styles.insets.xs),

        // Video Stats Chips Row
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility,
                  size: 14,
                  color: $styles.colors.accentFill,
                ),
                const Gap(2),
                Text(
                  '${_formatCount(video.viewCount ?? 386000)} 播放',
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text('·', style: TextStyle(color: $styles.colors.outline)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum, size: 14, color: $styles.colors.secondary),
                const Gap(2),
                Text(
                  '2.4万 弹幕',
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text('·', style: TextStyle(color: $styles.colors.outline)),
            Text(
              '1天前',
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Text('·', style: TextStyle(color: $styles.colors.outline)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: $styles.colors.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular($styles.corners.sm),
              ),
              child: Text(
                '原创技术',
                style: $styles.text.btn.copyWith(
                  color: $styles.colors.tertiary,
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: $styles.colors.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular($styles.corners.sm),
              ),
              child: Text(
                video.id.isNotEmpty ? video.id : 'BV1m44y1G7rk',
                style: $styles.text.btn.copyWith(
                  color: $styles.colors.accentText,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class const _CreatorProfileSection() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Scoped selector for creator profile and subscription state.
    // Keeps creator profile widget isolated so like/favorite toggles do not rebuild it.
    final creatorData = context
        .select<VideoBloc, ({CreatorProfile? creator, bool isSubscribed})?>((
          bloc,
        ) {
          final detail = bloc.state.videoDetail;
          if (detail == null) return null;
          return (creator: detail.creator, isSubscribed: detail.isSubscribed);
        });

    if (creatorData == null || creatorData.creator == null) {
      return const SizedBox.shrink();
    }

    final creator = creatorData.creator!;
    final isSubscribed = creatorData.isSubscribed;

    return Container(
      padding: EdgeInsets.all($styles.insets.xs),
      decoration: BoxDecoration(
        color: $styles.colors.surface,
        borderRadius: BorderRadius.circular($styles.corners.md),
        border: Border.all(
          color: $styles.colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar with Verified Badge
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    creator.thumbnailUrl != null &&
                        creator.thumbnailUrl!.isNotEmpty
                    ? ResizeImage.resizeIfNeeded(
                        128,
                        128,
                        CachedNetworkImageProvider(creator.thumbnailUrl!),
                      )
                    : null,
                child:
                    creator.thumbnailUrl == null ||
                        creator.thumbnailUrl!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: $styles.colors.accentFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 10,
                    color: $styles.colors.onScrim,
                  ),
                ),
              ),
            ],
          ),
          Gap($styles.insets.xs),
          // Name & Fan Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: $styles.text.bodyBold.copyWith(
                          color: $styles.colors.onSurfaceStrong,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(4),
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: $styles.colors.secondary,
                    ),
                  ],
                ),
                Text(
                  '${_formatCount(creator.subscribers ?? 528000)} 关注者 · 每周硬核解析',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Gap($styles.insets.xs),
          // Open External Origin Link & Follow Button
          IconButton(
            tooltip: '在浏览器中打开原链接',
            iconSize: 18,
            icon: Icon(
              Icons.open_in_new,
              color: $styles.colors.onSurfaceVariant,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('跳转原源作者主页'),
                  duration: $styles.times.fast,
                ),
              );
            },
          ),
          Tooltip(
            message: isSubscribed ? '取消关注创作者' : '关注创作者',
            child: Semantics(
              button: true,
              selected: isSubscribed,
              excludeSemantics: true,
              label: isSubscribed
                  ? '已关注创作者 ${creator.name}'
                  : '关注创作者 ${creator.name}',
              tooltip: isSubscribed ? '取消关注创作者' : '关注创作者',
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<VideoBloc>().add(const ToggleCreatorSubscribe());
              },
              child: AnimatedContainer(
                duration: Motion.standard,
                curve: Motion.easingStandard,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed
                        ? $styles.colors.outline.withValues(alpha: 0.3)
                        : $styles.colors.accentFill,
                    foregroundColor: isSubscribed
                        ? $styles.colors.onSurface
                        : $styles.colors.onScrim,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: $styles.insets.xs,
                      vertical: $styles.insets.xxs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular($styles.corners.lg),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<VideoBloc>().add(
                      const ToggleCreatorSubscribe(),
                    );
                  },
                  icon: AnimatedSwitcher(
                    duration: Motion.standard,
                    switchInCurve: Motion.easingEmphasized,
                    switchOutCurve: Motion.easingDecelerate,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isSubscribed ? Icons.check : Icons.add,
                      key: ValueKey(isSubscribed),
                      size: 16,
                    ),
                  ),
                  label: Text(
                    isSubscribed ? '已关注' : '关注',
                    style: $styles.text.btn.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _ActionButtonsSection() extends StatefulWidget {
  @override
  State<_ActionButtonsSection> createState() => _ActionButtonsSectionState();
}

class _ActionButtonsSectionState()
    extends State<_ActionButtonsSection>
    with AutomaticKeepAliveClientMixin {
  bool _isDanmakuActive = true;

  // This section is a direct child of the ListView at line 96. A child that
  // does not request keep-alive is disposed once the recommendations list
  // scrolls it past the cache extent, which resets `_isDanmakuActive` to its
  // default. Measured on the app fixture: with a 100px-tall viewport, two
  // scrolls to the bottom and back return the toggle to "弹幕开".
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ⚡ Bolt Optimization: Scoped selector for action metrics (likes, favorites, shares).
    // Rebuilds ONLY this action bar when like/favorite status changes, without rebuilding
    // the title, creator profile, synopsis, or recommendation list.
    final metrics = context
        .select<
          VideoBloc,
          ({
            int likeCount,
            int favoriteCount,
            int shareCount,
            bool isLiked,
            bool isFavorited,
          })?
        >((bloc) {
          final detail = bloc.state.videoDetail;
          if (detail == null) return null;
          return (
            likeCount: detail.likeCount,
            favoriteCount: detail.favoriteCount,
            shareCount: detail.shareCount,
            isLiked: detail.isLiked,
            isFavorited: detail.isFavorited,
          );
        });

    if (metrics == null) return const SizedBox.shrink();

    // 写失败只提示一句，不动页面内容：乐观更新已被 bloc 回滚，详情仍在屏上，
    // 把它并入加载失败通道会把整页顶成「视频加载失败」，与刚发生的写操作无关。
    return BlocListener<VideoBloc, VideoState>(
      listenWhen: (previous, current) =>
          current.actionError != null &&
          previous.actionError != current.actionError,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              duration: $styles.times.fast,
            ),
          );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ActionButton(
              icon: Icons.thumb_up_outlined,
              activeIcon: Icons.thumb_up,
              label: _formatCount(metrics.likeCount),
              actionName: '点赞',
              isActive: metrics.isLiked,
              color: $styles.colors.accentFill,
              onTap: () {
                context.read<VideoBloc>().add(const ToggleVideoLike());
              },
            ),
            _ActionButton(
              icon: Icons.grade_outlined,
              activeIcon: Icons.grade,
              label: _formatCount(metrics.favoriteCount),
              actionName: '收藏',
              isActive: metrics.isFavorited,
              color: $styles.colors.tertiary,
              onTap: () {
                context.read<VideoBloc>().add(const ToggleVideoFavorite());
              },
            ),
            _ActionButton(
              icon: Icons.cloud_sync,
              activeIcon: Icons.cloud_sync,
              label: '多源换源',
              actionName: '多源换源',
              tooltip: '切换视频数据源',
              isActive: true,
              color: $styles.colors.accentFill,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('自动切换至最优可用的解析线路'),
                    duration: $styles.times.fast,
                  ),
                );
              },
            ),
            _ActionButton(
              icon: Icons.share_outlined,
              activeIcon: Icons.share,
              label: _formatCount(metrics.shareCount),
              actionName: '分享',
              tooltip: '分享视频',
              isActive: false,
              color: $styles.colors.secondary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('分享多源视频链接'),
                    duration: $styles.times.fast,
                  ),
                );
              },
            ),
            _ActionButton(
              icon: _isDanmakuActive
                  ? Icons.closed_caption
                  : Icons.closed_caption_disabled,
              activeIcon: Icons.closed_caption,
              label: _isDanmakuActive ? '弹幕开' : '弹幕关',
              actionName: '弹幕',
              tooltip: _isDanmakuActive ? '关闭弹幕' : '开启弹幕',
              isActive: _isDanmakuActive,
              color: $styles.colors.accentFill,
              onTap: () {
                setState(() {
                  _isDanmakuActive = !_isDanmakuActive;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class const _SynopsisSection() extends StatefulWidget {
  @override
  State<_SynopsisSection> createState() => _SynopsisSectionState();
}

class _SynopsisSectionState()
    extends State<_SynopsisSection>
    with AutomaticKeepAliveClientMixin {
  bool _isDescExpanded = false;

  // Same reason as _ActionButtonsSectionState: a ListView child without
  // keep-alive loses this flag when it is scrolled out of the cache extent.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ⚡ Bolt Optimization: Scoped selector for video description.
    // Localizes expansion state (_isDescExpanded) so toggling synopsis does not rebuild
    // surrounding widgets (header, creator info, recommendations).
    final desc = context.select<VideoBloc, String?>(
      (bloc) => bloc.state.videoDetail?.video.desc,
    );

    return Container(
      padding: EdgeInsets.all($styles.insets.xs),
      decoration: BoxDecoration(
        color: $styles.colors.surface,
        borderRadius: BorderRadius.circular($styles.corners.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本期摘要 & 核心技术点',
                style: $styles.text.bodyBold.copyWith(
                  color: $styles.colors.onSurfaceStrong,
                  fontSize: 13,
                ),
              ),
              Semantics(
                button: true,
                expanded: _isDescExpanded,
                label: _isDescExpanded ? '收起摘要' : '展开完整大纲',
                tooltip: _isDescExpanded ? '收起摘要' : '展开完整大纲',
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isDescExpanded = !_isDescExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular($styles.corners.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        _isDescExpanded ? '收起' : '展开完整大纲',
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.accentText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(6),
          AnimatedSize(
            duration: Motion.standard,
            curve: Motion.easingEmphasized,
            alignment: Alignment.topCenter,
            child: Text(
              desc != null && desc.isNotEmpty ? desc : '探讨 Flutter 从 Skia 全面转向 Impeller 的底层渲染考量。详尽拆解 Shader 预编译、RenderPass 复用机制、Metal / Vulkan 直接后端绑定以及移动平台掉帧消除实践方案。',
              maxLines: _isDescExpanded ? null : 2,
              overflow: _isDescExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _RecommendationsHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: $styles.colors.accentFill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(6),
            Text(
              '多源关联推荐',
              style: $styles.text.title2.copyWith(
                color: $styles.colors.onSurfaceStrong,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class const _RelatedVideoCard({
  required final String title,
  required final String author,
  required final String views,
  required final String source,
  required final String time,
  required final String duration,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final semanticLabel = '$title, $author, $views, $time';

    return Container(
      margin: EdgeInsets.only(bottom: $styles.insets.xs),
      child: Material(
        color: $styles.colors.surface,
        borderRadius: BorderRadius.circular($styles.corners.md),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            child: Padding(
              padding: EdgeInsets.all($styles.insets.xxs),
              child: Row(
                children: [
                  // Thumbnail with duration badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular($styles.corners.sm),
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 68,
                          color: $styles.colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.play_circle_outline,
                            color: $styles.colors.onScrim.withValues(
                              alpha: 0.7,
                            ),
                            size: 28,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: $styles.colors.scrim.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              duration,
                              style: $styles.text.bodySmall.copyWith(
                                color: $styles.colors.onScrim,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap($styles.insets.xs),

                  // Metadata column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: $styles.text.bodySmallBold.copyWith(
                            color: $styles.colors.onSurfaceStrong,
                            height: 1.25,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '$author · $views',
                          style: $styles.text.bodySmall.copyWith(
                            color: $styles.colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: $styles.colors.onSurfaceVariant
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                source,
                                style: $styles.text.btn.copyWith(
                                  color: $styles.colors.onSurface,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Gap(6),
                            Text(
                              time,
                              style: $styles.text.bodySmall.copyWith(
                                color: $styles.colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const _ActionButton({
  required final IconData icon,
  required final IconData activeIcon,
  required final String label,
  required final String actionName,
  required final bool isActive,
  required final Color color,
  required final VoidCallback onTap,
  final String? tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final semanticLabel = '$actionName $label';
    final computedTooltip =
        tooltip ?? (isActive ? '取消$actionName' : actionName);

    return Tooltip(
      message: computedTooltip,
      // Semantics 上已带同一个 tooltip 标签，不排除会让读屏用户听到两遍。
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: true,
        selected: isActive,
        excludeSemantics: true,
        label: semanticLabel,
        tooltip: computedTooltip,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular($styles.corners.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: Motion.standard,
                  curve: Motion.easingStandard,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withValues(alpha: 0.15)
                        : $styles.colors.outline.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: Motion.standard,
                    switchInCurve: Motion.easingEmphasized,
                    switchOutCurve: Motion.easingDecelerate,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey(isActive),
                      size: 20,
                      color: isActive ? color : $styles.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Gap(4),
                Text(
                  label,
                  style: $styles.text.bodySmall.copyWith(
                    color: isActive ? color : $styles.colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
