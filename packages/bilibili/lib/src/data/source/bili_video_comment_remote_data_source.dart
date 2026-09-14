import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import 'bili_remote_data_source.dart';

final class BiliVideoCommentRemoteDataSource({
  required final NetworkVideoDataSource network,
}) extends VideoCommentRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      int oid;
      final numericAid = int.tryParse(videoId);
      if (numericAid != null) {
        oid = numericAid;
      } else {
        final detail = await network.getVideoDetail(bvid: videoId);
        oid = detail.aid;
      }

      final replyData = await network.getReplyList(
        oid: oid,
        type: 1,
        page: page,
      );

      final replies = (replyData.replies ?? []).map(_mapReplyItem).toList();

      final totalCount = replyData.cursor?.allCount ?? replies.length;
      final totalPages = totalCount > 0 ? (totalCount / pageSize).ceil() : 1;

      return Result.ok(
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

  static VideoComment _mapReplyItem(NetworkReplyItem item) {
    return VideoComment(
      id: item.rpid.toString(),
      authorName: item.member?.uname ?? '',
      authorAvatar: _formatUrl(item.member?.avatar),
      content: item.content?.message ?? '',
      likeCount: item.like ?? 0,
      isLiked: item.action == 1,
      createdAt: item.ctime != null
          ? DateTime.fromMillisecondsSinceEpoch(item.ctime! * 1000)
          : null,
      replies: (item.replies ?? []).map(_mapReplyItem).toList(),
    );
  }

  static String _formatUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}
