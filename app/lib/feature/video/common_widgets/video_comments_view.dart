import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:data/data.dart';

import '../bloc/video_comment_bloc.dart';

class VideoCommentsView extends StatelessWidget {
  const VideoCommentsView({super.key});

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoCommentBloc, VideoCommentState>(
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
                '评论加载失败: ${state.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        if (state.comments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('暂无评论'),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              context.read<VideoCommentBloc>().add(const FetchNextCommentPage());
            }
            return false;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.comments.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final comment = state.comments[index];
              return _CommentItem(
                comment: comment,
                formatCount: _formatCount,
              );
            },
          ),
        );
      },
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.formatCount,
  });

  final VideoComment comment;
  final String Function(int) formatCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: comment.authorAvatar != null
              ? CachedNetworkImageProvider(comment.authorAvatar!)
              : null,
          child: comment.authorAvatar == null ? const Icon(Icons.person) : null,
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (comment.createdAt != null)
                    Text(
                      '${comment.createdAt!.hour.toString().padLeft(2, '0')}:${comment.createdAt!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
              const Gap(4),
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
              const Gap(8),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      context
                          .read<VideoCommentBloc>()
                          .add(ToggleCommentLike(comment.id));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14,
                            color: comment.isLiked
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const Gap(4),
                          Text(
                            formatCount(comment.likeCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: comment.isLiked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 二级回复列表
              if (comment.replies.isNotEmpty) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comment.replies.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${reply.authorName}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: reply.content,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
