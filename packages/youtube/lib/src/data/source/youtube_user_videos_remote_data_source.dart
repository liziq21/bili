import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../youtube_utils.dart';
import 'youtube_remote_data_source.dart';

/// YouTube 频道投稿桥接：InnerTube `browse` 端点（视频 tab）→ 分页视频列表。
///
/// `browse` 只认 continuation token，不认页码；本类按 `channelId:page` 记住
/// 上一页返回的令牌。频道视频 tab 的条目以 `lockupViewModel` 返回。
final class YouTubeUserVideosRemoteDataSource(
  final YoutubeService _youtubeService,
) extends UserVideosRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// InnerTube 频道「视频」tab 的固定 params。不传时 browse 返回频道首页，
  /// 其条目混有 shelf、shorts 与推荐内容，不是按时间排列的投稿列表。
  static const String _videosTabParams = 'EgZ2aWRlb3PyBgQKAjoA';

  final Map<String, String> _continuationTokens = {};

  @override
  Future<Result<Page<VideoModel>, Exception>> fetchUserVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    final sanitizedChannelId = channelId.replaceAll(_controlChars, '').trim();
    if (sanitizedChannelId.isEmpty) {
      return Result.error(Exception('channelId cannot be empty'));
    }
    if (page < 1 || pageSize < 1) {
      return Result.error(Exception('page and pageSize must be positive'));
    }

    try {
      final continuation = page > 1
          ? _continuationTokens['$sanitizedChannelId:${page - 1}']
          : null;
      if (page > 1 && (continuation == null || continuation.isEmpty)) {
        return Result.success(
          Page<VideoModel>(number: page, totalPages: page, data: const []),
        );
      }

      final response = await _youtubeService.browseChannel(
        browseId: continuation == null ? sanitizedChannelId : null,
        continuation: continuation,
        params: continuation == null ? _videosTabParams : null,
      );

      final nextToken = response.continuationToken;
      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens['$sanitizedChannelId:$page'] = nextToken;
      }

      final channelName =
          response.header?.title ?? response.channelMetadata?.title;
      final responseChannelId = response.channelMetadata?.channelId;
      final videos = response.items
          .where((item) => _isPlayableVideoId(item.contentId))
          .map(
            (item) => _toVideoModel(
              item,
              channelName: channelName,
              channelId: responseChannelId,
            ),
          )
          .toList(growable: false);

      return Result.success(
        Page<VideoModel>(
          number: page,
          totalPages: nextToken == null || nextToken.isEmpty ? page : page + 1,
          data: videos,
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  /// `PXC_` 前缀是播放器状态使用的内部 ID，不是 watch 页可用的视频 ID。
  bool _isPlayableVideoId(String contentId) =>
      contentId.isNotEmpty && !contentId.startsWith('PXC_');

  VideoModel _toVideoModel(
    NetworkYouTubeLockupItem item, {
    String? channelName,
    String? channelId,
  }) {
    final thumbnail = item.thumbnail;
    return VideoModel(
      id: item.contentId,
      title: item.title ?? '',
      url: buildYoutubeWatchUrl(item.contentId),
      thumbnailUrl: normalizeYoutubeUrl(
        thumbnail == null || thumbnail.thumbnails.isEmpty
            ? null
            : thumbnail.thumbnails.last.url,
      ),
      viewCount: _viewCountOf(item.metadataRows),
      uploadDate: _uploadDateOf(item.metadataRows),
      creatorProfileName: channelName,
      creatorProfileId: channelId,
    );
  }

  int? _viewCountOf(List<String> metadataRows) {
    for (final row in metadataRows) {
      final lower = row.toLowerCase();
      if (lower.contains('观看') || lower.contains('view')) {
        return parseYoutubeCount(row);
      }
    }
    return null;
  }

  DateTime? _uploadDateOf(List<String> metadataRows) {
    for (final row in metadataRows) {
      if (row.contains('前') || row.toLowerCase().contains('ago')) {
        return parseYoutubeRelativeDate(row);
      }
    }
    return null;
  }
}
