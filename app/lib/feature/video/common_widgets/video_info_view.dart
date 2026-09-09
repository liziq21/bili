import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../main.dart';
import '../bloc/video_bloc.dart';

class VideoInfoView extends StatefulWidget {
  const VideoInfoView({super.key});

  @override
  State<VideoInfoView> createState() => _VideoInfoViewState();
}

class _VideoInfoViewState extends State<VideoInfoView> {
  bool _isDescExpanded = false;
  bool _isDanmakuActive = true;

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: CircularProgressIndicator(
                color: $styles.colors.accent1,
              ),
            ),
          );
        }

        if (state.error != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Text(
                '加载失败: ${state.error}',
                style: $styles.text.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        final detail = state.videoDetail;
        if (detail == null) {
          return const SizedBox.shrink();
        }

        final video = detail.video;
        final creator = detail.creator;

        return ListView(
          padding: EdgeInsets.all($styles.insets.sm),
          children: [
            // Video Title
            Text(
              video.title,
              style: $styles.text.h3.copyWith(
                color: $styles.colors.black,
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
                      color: $styles.colors.accent1,
                    ),
                    const Gap(2),
                    Text(
                      '${_formatCount(video.viewCount ?? 386000)} 播放',
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.caption,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text('·', style: TextStyle(color: $styles.colors.greyMedium)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum,
                      size: 14,
                      color: $styles.colors.accent2,
                    ),
                    const Gap(2),
                    Text(
                      '2.4万 弹幕',
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.caption,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text('·', style: TextStyle(color: $styles.colors.greyMedium)),
                Text(
                  '1天前',
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.caption,
                    fontSize: 12,
                  ),
                ),
                Text('·', style: TextStyle(color: $styles.colors.greyMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: $styles.colors.greyStrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular($styles.corners.sm),
                  ),
                  child: Text(
                    '原创技术',
                    style: $styles.text.btn.copyWith(
                      color: $styles.colors.accent3,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: $styles.colors.greyStrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular($styles.corners.sm),
                  ),
                  child: Text(
                    video.id.isNotEmpty ? video.id : 'BV1m44y1G7rk',
                    style: $styles.text.btn.copyWith(
                      color: $styles.colors.accent1,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Gap($styles.insets.sm),

            // UP Creator Profile Block
            if (creator != null)
              Container(
                padding: EdgeInsets.all($styles.insets.xs),
                decoration: BoxDecoration(
                  color: $styles.colors.offWhite,
                  borderRadius: BorderRadius.circular($styles.corners.md),
                  border: Border.all(
                    color: $styles.colors.greyMedium.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with Verified Badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: creator.thumbnailUrl != null
                              ? CachedNetworkImageProvider(creator.thumbnailUrl!)
                              : null,
                          child: creator.thumbnailUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: $styles.colors.accent1,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: $styles.colors.white,
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
                                    color: $styles.colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Gap(4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: $styles.colors.accent2,
                              ),
                            ],
                          ),
                          Text(
                            '${_formatCount(creator.subscribers ?? 528000)} 关注者 · 每周硬核解析',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: $styles.text.bodySmall.copyWith(
                              color: $styles.colors.caption,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap($styles.insets.xs),
                    // Open External Origin Link & Follow Button
                    IconButton(
                      iconSize: 18,
                      icon: Icon(
                        Icons.open_in_new,
                        color: $styles.colors.caption,
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: detail.isSubscribed
                            ? $styles.colors.greyMedium.withValues(alpha: 0.3)
                            : $styles.colors.accent1,
                        foregroundColor: detail.isSubscribed
                            ? $styles.colors.body
                            : $styles.colors.white,
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
                        context
                            .read<VideoBloc>()
                            .add(const ToggleCreatorSubscribe());
                      },
                      icon: Icon(
                        detail.isSubscribed ? Icons.check : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        detail.isSubscribed ? '已关注' : '关注',
                        style: $styles.text.btn.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Gap($styles.insets.sm),

            // Multi-Source Tactical Action Bar (Like, Favorite, Sync, Share, Danmaku Toggle)
            Container(
              padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionButton(
                    icon: Icons.thumb_up_outlined,
                    activeIcon: Icons.thumb_up,
                    label: _formatCount(detail.likeCount),
                    isActive: detail.isLiked,
                    color: $styles.colors.accent1,
                    onTap: () {
                      context.read<VideoBloc>().add(const ToggleVideoLike());
                    },
                  ),
                  _ActionButton(
                    icon: Icons.grade_outlined,
                    activeIcon: Icons.grade,
                    label: _formatCount(detail.favoriteCount),
                    isActive: detail.isFavorited,
                    color: $styles.colors.accent3,
                    onTap: () {
                      context.read<VideoBloc>().add(const ToggleVideoFavorite());
                    },
                  ),
                  _ActionButton(
                    icon: Icons.cloud_sync,
                    activeIcon: Icons.cloud_sync,
                    label: '多源换源',
                    isActive: true,
                    color: $styles.colors.accent1,
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
                    label: _formatCount(detail.shareCount),
                    isActive: false,
                    color: $styles.colors.accent2,
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
                    isActive: _isDanmakuActive,
                    color: $styles.colors.accent1,
                    onTap: () {
                      setState(() {
                        _isDanmakuActive = !_isDanmakuActive;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(color: $styles.colors.greyMedium.withValues(alpha: 0.2)),

            // Collapsible Synopsis Box
            Container(
              padding: EdgeInsets.all($styles.insets.xs),
              decoration: BoxDecoration(
                color: $styles.colors.offWhite,
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
                          color: $styles.colors.black,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescExpanded = !_isDescExpanded;
                          });
                        },
                        child: Text(
                          _isDescExpanded ? '收起' : '展开完整大纲',
                          style: $styles.text.bodySmall.copyWith(
                            color: $styles.colors.accent1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    video.desc != null && video.desc!.isNotEmpty
                        ? video.desc!
                        : '探讨 Flutter 从 Skia 全面转向 Impeller 的底层渲染考量。详尽拆解 Shader 预编译、RenderPass 复用机制、Metal / Vulkan 直接后端绑定以及移动平台掉帧消除实践方案。',
                    maxLines: _isDescExpanded ? null : 2,
                    overflow:
                        _isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: $styles.text.bodySmall.copyWith(
                      color: $styles.colors.body,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Gap($styles.insets.md),

            // Multi-Source Related Recommendations Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: $styles.colors.accent1,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '多源关联推荐',
                      style: $styles.text.title2.copyWith(
                        color: $styles.colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '聚合源: Bilibili / YT / Pod',
                  style: $styles.text.bodySmall.copyWith(
                    color: $styles.colors.caption,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Gap($styles.insets.xs),

            // Related Video Feed List
            ..._buildRelatedVideosList(),
          ],
        );
      },
    );
  }

  List<Widget> _buildRelatedVideosList() {
    final relatedList = [
      {
        'title': 'Flutter 3.24 全新渲染管线实战指南：自定义着色器与深度渲染',
        'author': 'CodeCraft',
        'views': '14.2万',
        'source': 'BILIBILI',
        'time': '4天前',
        'duration': '12:40',
        'badgeColor': $styles.colors.accent1,
      },
      {
        'title': 'Why Flutter\'s Impeller Engine Changes Everything for Cross-Platform Devs',
        'author': 'Flutter Dev Hub',
        'views': '290K views',
        'source': 'YOUTUBE',
        'time': '1周前',
        'duration': '18:15',
        'badgeColor': Colors.red.shade400,
      },
      {
        'title': '跨平台框架底层图形层横评：React Native Fabric vs Flutter Impeller',
        'author': '开源音频周刊',
        'views': '3.8万收听',
        'source': 'PEERTUBE / RSS',
        'time': '3天前',
        'duration': '45:20',
        'badgeColor': $styles.colors.accent3,
      },
    ];

    return relatedList.map((item) {
      return Container(
        margin: EdgeInsets.only(bottom: $styles.insets.xs),
        padding: EdgeInsets.all($styles.insets.xxs),
        decoration: BoxDecoration(
          color: $styles.colors.offWhite,
          borderRadius: BorderRadius.circular($styles.corners.md),
        ),
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
                    color: $styles.colors.greyStrong,
                    child: Icon(
                      Icons.play_circle_outline,
                      color: $styles.colors.white.withValues(alpha: 0.7),
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: $styles.colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['duration'] as String,
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.white,
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
                    item['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: $styles.text.bodySmallBold.copyWith(
                      color: $styles.colors.black,
                      height: 1.25,
                      fontSize: 13,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '${item['author']} · ${item['views']}',
                    style: $styles.text.bodySmall.copyWith(
                      color: $styles.colors.caption,
                      fontSize: 11,
                    ),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (item['badgeColor'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['source'] as String,
                          style: $styles.text.btn.copyWith(
                            color: item['badgeColor'] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        item['time'] as String,
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.caption,
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
      );
    }).toList();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular($styles.corners.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : $styles.colors.greyMedium.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? color : $styles.colors.caption,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: $styles.text.bodySmall.copyWith(
              color: isActive ? color : $styles.colors.caption,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
