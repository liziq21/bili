import 'dart:async';
import 'dart:math' as math;

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_remote_data_source.dart';

final class BiliVideoCommentRemoteDataSource({
  required final NetworkVideoDataSource network,
}) extends VideoCommentRemoteDataSource
    with BiliRemoteDataSource
    implements VideoCommentRepliesRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final sanitizedVideoId = videoId.replaceAll(_controlChars, '').trim();
      if (sanitizedVideoId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      final oid = await _resolveObjectId(sanitizedVideoId);

      final replyData = await network.getReplyList(
        oid: oid,
        type: 1,
        page: page,
      );

      final replies = (replyData.replies ?? []).map(_mapReplyItem).toList();

      final totalCount = replyData.cursor?.allCount ?? replies.length;
      final totalPages = totalCount > 0 ? (totalCount / pageSize).ceil() : 1;

      return Result.success(
        Page<VideoComment>(
          number: page,
          totalPages: totalPages > 0 ? totalPages : 1,
          data: replies,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoCommentReplies(
    String videoId,
    String rootCommentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final sanitizedVideoId = videoId.replaceAll(_controlChars, '').trim();
      final sanitizedRootId = rootCommentId
          .replaceAll(_controlChars, '')
          .trim();
      if (sanitizedVideoId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      final root = int.tryParse(sanitizedRootId);
      if (root == null || root <= 0) {
        return Result.error(Exception('Root comment ID must be numeric'));
      }

      final replyData = await network.getReplyReplyList(
        oid: await _resolveObjectId(sanitizedVideoId),
        root: root,
        type: 1,
        page: page,
      );
      final replies = (replyData.replies ?? []).map(_mapReplyItem).toList();
      final responsePageSize = replyData.page?.size ?? pageSize;
      final safePageSize = responsePageSize > 0 ? responsePageSize : 20;
      final totalCount = replyData.page?.count ?? replies.length;
      final totalPages = totalCount > 0
          ? (totalCount / safePageSize).ceil()
          : 1;

      return Result.success(
        Page<VideoComment>(
          number: page,
          totalPages: totalPages > 0 ? totalPages : 1,
          data: replies,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<int> _resolveObjectId(String videoId) async {
    final numericAid = int.tryParse(videoId);
    if (numericAid != null) return numericAid;

    final detail = await network.getVideoDetail(bvid: videoId);
    return detail.aid;
  }

  static VideoComment _mapReplyItem(NetworkReplyItem item) {
    final replies = (item.replies ?? []).map(_mapReplyItem).toList();
    final replyCount = math.max(
      replies.length,
      math.max(item.count ?? 0, item.rcount ?? 0),
    );

    return VideoComment(
      id: item.rpid.toString(),
      authorName: item.member?.uname ?? '',
      authorAvatar: normalizeBiliUrl(item.member?.avatar),
      content: item.content?.message ?? '',
      likeCount: item.like ?? 0,
      isLiked: item.action == 1,
      createdAt: item.ctime != null
          ? DateTime.fromMillisecondsSinceEpoch(item.ctime! * 1000)
          : null,
      replies: replies,
      replyCount: replyCount,
    );
  }
}
