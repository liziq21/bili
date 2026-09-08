import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../routing/router.dart';
import '../../../ui/video_card.dart';
import '../bloc/video_bloc.dart';

class VideoInfoView extends StatefulWidget {
  const VideoInfoView({super.key});

  @override
  State<VideoInfoView> createState() => _VideoInfoViewState();
}

class _VideoInfoViewState extends State<VideoInfoView> {
  bool _isDescExpanded = false;

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '加载失败: ${state.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          padding: const EdgeInsets.all(16.0),
          children: [
            // UP 主信息栏
            if (creator != null) ...[
              Row(
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
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creator.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatCount(creator.subscribers ?? 0)} 关注者',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      context.read<VideoBloc>().add(const ToggleCreatorSubscribe());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: detail.isSubscribed
                          ? Colors.grey.shade300
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Text(
                      detail.isSubscribed ? '已关注' : '+ 关注',
                      style: TextStyle(
                        color: detail.isSubscribed
                            ? Colors.black87
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
            ],

            // 视频标题与基本统计
            Text(
              video.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const Gap(4),
                Text(
                  '${_formatCount(video.viewCount ?? 0)} 播放',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (video.uploadDate != null) ...[
                  const Gap(12),
                  Text(
                    '${video.uploadDate!.year}-${video.uploadDate!.month.toString().padLeft(2, '0')}-${video.uploadDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            const Gap(16),

            // 互动操作按钮栏（点赞、收藏、分享）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: detail.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: _formatCount(detail.likeCount),
                  isSelected: detail.isLiked,
                  onTap: () {
                    context.read<VideoBloc>().add(const ToggleVideoLike());
                  },
                ),
                _ActionButton(
                  icon: detail.isFavorited ? Icons.star : Icons.star_border,
                  label: _formatCount(detail.favoriteCount),
                  isSelected: detail.isFavorited,
                  onTap: () {
                    context.read<VideoBloc>().add(const ToggleVideoFavorite());
                  },
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: _formatCount(detail.shareCount),
                  isSelected: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制视频链接'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Gap(16),
            const Divider(),

            // 视频简介（可折叠）
            if (video.desc != null && video.desc!.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _isDescExpanded = !_isDescExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.desc!,
                        maxLines: _isDescExpanded ? 100 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _isDescExpanded ? '收起' : '展开简介',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Icon(
                            _isDescExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              const Divider(),
            ],

            // 相关推荐视频列表
            if (detail.relatedVideos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '相关推荐',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detail.relatedVideos.length,
                separatorBuilder: (_, _) => const Gap(8),
                itemBuilder: (context, index) {
                  final item = detail.relatedVideos[index];
                  return SizedBox(
                    height: 110,
                    child: VideoCard(
                      videoInfoBase: item,
                      onTap: () => context.navigateToVideo(item.id),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final color = isSelected
        ? activeColor
        : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
