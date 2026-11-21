import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../youtube_utils.dart';
import 'youtube_remote_data_source.dart';

/// YouTube 视频评论桥接：Watch Next 取评论续页令牌，再用 `next` 端点翻页。
///
/// InnerTube 的评论列表没有页码，只有 continuation token。能力接口按页码
/// 调用，因此本类按 `videoId:page` 记住上一页返回的令牌；第一页的令牌来自
/// Watch Next 的评论区段落。
///
/// 二级回复暂不实现：回复续页与评论列表的响应形态不同，仓库内没有对应的
/// 真实 fixture，按 `packages/AGENTS.md` 的 endpoint 规则不实现未验证的路径。
final class YouTubeVideoCommentRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoCommentRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  final Map<String, String> _continuationTokens = {};

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

      final String? token;
      if (page <= 1) {
        final watchNext = await _youtubeService.getWatchNext(
          videoId: sanitizedVideoId,
        );
        token = watchNext.commentsContinuationToken;
      } else {
        token = _continuationTokens['$sanitizedVideoId:${page - 1}'];
      }

      if (token == null || token.isEmpty) {
        return Result.success(
          Page<VideoComment>(number: page, totalPages: page, data: const []),
        );
      }

      final response = await _youtubeService.getComments(token);
      final nextToken = response.continuationToken;
      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens['$sanitizedVideoId:$page'] = nextToken;
      }

      return Result.success(
        Page<VideoComment>(
          number: page,
          totalPages: nextToken == null || nextToken.isEmpty ? page : page + 1,
          data: response.items.map(_toVideoComment).toList(growable: false),
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  VideoComment _toVideoComment(NetworkYouTubeCommentThread thread) {
    final avatar = thread.author?.avatar;
    return VideoComment(
      id: thread.commentId,
      authorName: thread.author?.displayName ?? '',
      authorAvatar: normalizeYoutubeUrl(
        avatar == null || avatar.thumbnails.isEmpty
            ? null
            : avatar.thumbnails.last.url,
      ),
      content: thread.text ?? '',
      likeCount: parseYoutubeCount(thread.likeCountText) ?? 0,
      createdAt: parseYoutubeRelativeDate(thread.publishedTimeText),
      replyCount: thread.replyCount ?? 0,
    );
  }
}
