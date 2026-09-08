import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

abstract interface class VideoCommentRepository {
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  });
}

class AppVideoCommentRepository implements VideoCommentRepository {
  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    const totalPages = 3;
    if (page > totalPages) {
      return Result.ok(Page<VideoComment>(number: page, totalPages: totalPages, data: []));
    }

    final comments = List.generate(
      pageSize,
      (index) {
        final commentId = 'comment_${page}_$index';
        return VideoComment(
          id: commentId,
          authorName: '评论用户 ${page * 100 + index}',
          authorAvatar: 'https://picsum.photos/seed/user_${page}_$index/100/100',
          content: '这是一条对视频 $videoId 的极佳评价！代码架构清晰，BLoC 状态管理封装得非常合理。第 $page 页第 $index 条评论。',
          likeCount: (index + 1) * 12,
          isLiked: false,
          createdAt: DateTime.now().subtract(Duration(hours: index + 1, minutes: page * 5)),
          replies: index % 3 == 0
              ? [
                  VideoComment(
                    id: '${commentId}_reply_1',
                    authorName: '热心网友 A',
                    authorAvatar: 'https://picsum.photos/seed/reply_a_$index/100/100',
                    content: '同意楼上的看法，讲得非常赞！',
                    likeCount: 5,
                    createdAt: DateTime.now().subtract(Duration(minutes: index * 10 + 2)),
                  ),
                ]
              : const [],
        );
      },
    );

    return Result.ok(Page<VideoComment>(
      number: page,
      totalPages: totalPages,
      data: comments,
    ));
  }
}
