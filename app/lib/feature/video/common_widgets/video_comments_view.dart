import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../main.dart';
import '../bloc/video_comment_bloc.dart';

class const VideoCommentsView({super.key}) extends StatelessWidget {
  static String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<VideoCommentBloc?>() == null) {
      return const Center(child: Text('当前数据源暂不支持评论'));
    }

    // ⚡ Bolt Optimization: Use BlocSelector to isolate list container state
    // (loading, error, comment count, hasMore) from individual comment item updates.
    // Toggling likes or sub-reply states on a single comment will not force re-evaluating
    // or re-instantiating the whole comment list viewport layout.
    return BlocSelector<
      VideoCommentBloc,
      VideoCommentState,
      ({bool isLoading, Object? error, int commentCount, bool hasMore})
    >(
      selector: (state) => (
        isLoading: state.isLoading,
        error: state.error,
        commentCount: state.comments.length,
        hasMore: state.hasMore,
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
                '评论加载失败，请稍后重试',
                style: $styles.text.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          );
        }

        if (status.commentCount == 0) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all($styles.insets.lg),
              child: Text(
                '暂无评论',
                style: $styles.text.body.copyWith(
                  color: $styles.colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              context.read<VideoCommentBloc>().add(
                const FetchNextCommentPage(),
              );
            }
            return false;
          },
          child: ListView.separated(
            padding: EdgeInsets.all($styles.insets.sm),
            itemCount: status.commentCount + (status.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => Divider(
              height: 20,
              color: $styles.colors.outline.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              if (index >= status.commentCount) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: $styles.insets.xs),
                    child: CircularProgressIndicator(
                      color: $styles.colors.accentFill,
                    ),
                  ),
                );
              }

              return _CommentItem(index: index, formatCount: _formatCount);
            },
          ),
        );
      },
    );
  }
}

class const _CommentItem({
  required final int index,
  required final String Function(int) formatCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Selective state listener via context.select.
    // Listens strictly to the VideoComment item at `index`.
    // Includes bounds checking to safely return null if the comment list shrinks.
    // Re-renders ONLY this specific _CommentItem when its state changes (e.g., like toggles),
    // skipping build passes for all other visible comment items in the list.
    final comment = context.select<VideoCommentBloc, VideoComment?>(
      (bloc) => index < bloc.state.comments.length
          ? bloc.state.comments[index]
          : null,
    );

    if (comment == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: $styles.colors.surfaceContainerHighest,
          backgroundImage:
              comment.authorAvatar != null && comment.authorAvatar!.isNotEmpty
              ? ResizeImage.resizeIfNeeded(
                  128,
                  128,
                  CachedNetworkImageProvider(comment.authorAvatar!),
                )
              : null,
          child: comment.authorAvatar == null || comment.authorAvatar!.isEmpty
              ? Icon(Icons.person, color: $styles.colors.onScrim, size: 20)
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
                      color: $styles.colors.onSurfaceStrong,
                      fontSize: 13,
                    ),
                  ),
                  if (comment.createdAt != null)
                    Text(
                      '${comment.createdAt!.hour.toString().padLeft(2, '0')}:${comment.createdAt!.minute.toString().padLeft(2, '0')}',
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const Gap(4),
              Text(
                comment.content,
                style: $styles.text.body.copyWith(
                  color: $styles.colors.onSurface,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const Gap(6),
              Row(
                children: [
                  Semantics(
                    button: true,
                    enabled: true,
                    selected: comment.isLiked,
                    excludeSemantics: true,
                    label: '点赞评论 ${formatCount(comment.likeCount)}',
                    tooltip: comment.isLiked ? '取消点赞' : '点赞评论',
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<VideoCommentBloc>().add(
                          ToggleCommentLike(comment.id),
                        );
                      },
                      borderRadius: BorderRadius.circular($styles.corners.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 14,
                              color: comment.isLiked
                                  ? $styles.colors.accentFill
                                  : $styles.colors.onSurfaceVariant,
                            ),
                            const Gap(4),
                            Text(
                              formatCount(comment.likeCount),
                              style: $styles.text.bodySmall.copyWith(
                                fontSize: 11,
                                color: comment.isLiked
                                    ? $styles.colors.accentText
                                    : $styles.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
                    color: $styles.colors.surface,
                    borderRadius: BorderRadius.circular($styles.corners.sm),
                    border: Border.all(
                      color: $styles.colors.outline.withValues(alpha: 0.15),
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
                                  color: $styles.colors.onSurfaceStrong,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: reply.content,
                                style: $styles.text.bodySmall.copyWith(
                                  color: $styles.colors.onSurface,
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
