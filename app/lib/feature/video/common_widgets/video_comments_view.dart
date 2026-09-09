import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../main.dart';
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
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: CircularProgressIndicator(color: $styles.colors.accent1),
            ),
          );
        }

        if (state.error != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Text(
                '评论加载失败: ${state.error}',
                style: $styles.text.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (state.comments.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Text(
                '暂无评论',
                style: $styles.text.body.copyWith(color: $styles.colors.caption),
              ),
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
            padding: EdgeInsets.all($styles.insets.sm),
            itemCount: state.comments.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => Divider(
              height: 20,
              color: $styles.colors.greyMedium.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
                    child: CircularProgressIndicator(
                      color: $styles.colors.accent1,
                    ),
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
          backgroundColor: $styles.colors.greyStrong,
          backgroundImage: comment.authorAvatar != null
              ? CachedNetworkImageProvider(comment.authorAvatar!)
              : null,
          child: comment.authorAvatar == null
              ? Icon(Icons.person, color: $styles.colors.white, size: 20)
              : null,
        ),
        Gap($styles.insets.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    comment.authorName,
                    style: $styles.text.bodyBold.copyWith(
                      color: $styles.colors.black,
                      fontSize: 13,
                    ),
                  ),
                  if (comment.createdAt != null)
                    Text(
                      '${comment.createdAt!.hour.toString().padLeft(2, '0')}:${comment.createdAt!.minute.toString().padLeft(2, '0')}',
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.caption,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const Gap(4),
              Text(
                comment.content,
                style: $styles.text.body.copyWith(
                  color: $styles.colors.body,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const Gap(6),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      context
                          .read<VideoCommentBloc>()
                          .add(ToggleCommentLike(comment.id));
                    },
                    borderRadius: BorderRadius.circular($styles.corners.sm),
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
                                ? $styles.colors.accent1
                                : $styles.colors.caption,
                          ),
                          const Gap(4),
                          Text(
                            formatCount(comment.likeCount),
                            style: $styles.text.bodySmall.copyWith(
                              fontSize: 11,
                              color: comment.isLiked
                                  ? $styles.colors.accent1
                                  : $styles.colors.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Threaded Sub-replies
              if (comment.replies.isNotEmpty) ...[
                const Gap(8),
                Container(
                  padding: EdgeInsets.all($styles.insets.xs),
                  decoration: BoxDecoration(
                    color: $styles.colors.offWhite,
                    borderRadius: BorderRadius.circular($styles.corners.sm),
                    border: Border.all(
                      color: $styles.colors.greyMedium.withValues(alpha: 0.15),
                    ),
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
                                style: $styles.text.bodyBold.copyWith(
                                  color: $styles.colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: reply.content,
                                style: $styles.text.bodySmall.copyWith(
                                  color: $styles.colors.body,
                                  fontSize: 12,
                                ),
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
