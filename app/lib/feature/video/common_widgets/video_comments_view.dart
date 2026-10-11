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
              if (scrollInfo.depth == 0) {
                context.read<VideoCommentBloc>().add(
                  const FetchNextCommentPage(),
                );
              }
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
    final selection = context
        .select<
          VideoCommentBloc,
          ({VideoComment? comment, VideoCommentReplyState? replyState})
        >((bloc) {
          if (index >= bloc.state.comments.length) {
            return (comment: null, replyState: null);
          }
          final comment = bloc.state.comments[index];
          return (
            comment: comment,
            replyState: bloc.state.replyStates[comment.id],
          );
        });

    final comment = selection.comment;
    final replyState = selection.replyState;

    if (comment == null) {
      return const SizedBox.shrink();
    }

    final hasReplies = comment.replyCount > 0 || comment.replies.isNotEmpty;
    final effectiveReplyState =
        replyState ?? VideoCommentReplyState(replies: comment.replies);
    final replyCount = comment.replyCount > 0
        ? comment.replyCount
        : effectiveReplyState.replies.length;

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
              if (hasReplies) ...[
                const Gap(2),
                Semantics(
                  button: true,
                  enabled: true,
                  label: effectiveReplyState.isExpanded
                      ? '收起回复'
                      : '查看 ${formatCount(replyCount)} 条回复',
                  child: TextButton(
                    key: ValueKey('comment-replies-${comment.id}'),
                    onPressed: () {
                      context.read<VideoCommentBloc>().add(
                        ToggleCommentReplies(comment.id),
                      );
                    },
                    child: Text(
                      effectiveReplyState.isExpanded
                          ? '收起回复'
                          : '查看 ${formatCount(replyCount)} 条回复',
                    ),
                  ),
                ),
              ],
              if (effectiveReplyState.isExpanded)
                _CommentReplies(
                  commentId: comment.id,
                  state: effectiveReplyState,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class const _CommentReplies({
  required final String commentId,
  required final VideoCommentReplyState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter <= 160 &&
            state.hasMore &&
            !state.isLoading) {
          context.read<VideoCommentBloc>().add(
            FetchNextCommentRepliesPage(commentId),
          );
        }
        return false;
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        padding: EdgeInsets.all($styles.insets.xs),
        decoration: BoxDecoration(
          color: $styles.colors.surface,
          borderRadius: BorderRadius.circular($styles.corners.sm),
          border: Border.all(
            color: $styles.colors.outline.withValues(alpha: 0.15),
          ),
        ),
        child: state.replies.isEmpty && state.isLoading
            ? Padding(
                padding: EdgeInsets.all($styles.insets.sm),
                child: Center(
                  child: CircularProgressIndicator(
                    color: $styles.colors.accentFill,
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount:
                    state.replies.length +
                    (state.isLoading ? 1 : 0) +
                    (state.error != null ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  if (state.error != null && index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '评论回复暂不可用',
                          style: $styles.text.bodySmall.copyWith(
                            color: $styles.colors.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<VideoCommentBloc>().add(
                              FetchNextCommentRepliesPage(commentId),
                            );
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    );
                  }

                  final replyIndex = state.error != null ? index - 1 : index;
                  if (replyIndex >= state.replies.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: $styles.insets.xs,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: $styles.colors.accentFill,
                        ),
                      ),
                    );
                  }

                  final reply = state.replies[replyIndex];
                  return Text.rich(
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
                  );
                },
              ),
      ),
    );
  }
}
