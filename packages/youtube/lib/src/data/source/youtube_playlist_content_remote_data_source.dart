import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../youtube_utils.dart';
import 'youtube_remote_data_source.dart';

/// YouTube 远端播放列表桥接：InnerTube `browse` 端点（`browseId=VL<id>`）。
///
/// `browse` 只认 continuation token，不认页码；本类按 `playlistId:page`
/// 记住上一页返回的令牌。列表信息头只在首屏返回，后续页仍从响应里读取，
/// 取不到时退回请求参数中的列表标识。
final class YouTubePlaylistContentRemoteDataSource(
  final YoutubeService _youtubeService,
) extends PlaylistContentRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  final Map<String, String> _continuationTokens = {};

  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylistContent({
    required String playlistId,
    int page = 1,
    int pageSize = 30,
  }) async {
    final sanitizedPlaylistId = playlistId.replaceAll(_controlChars, '').trim();
    if (sanitizedPlaylistId.isEmpty) {
      return Result.error(Exception('playlistId cannot be empty'));
    }
    if (page < 1 || pageSize < 1) {
      return Result.error(Exception('page and pageSize must be positive'));
    }

    try {
      final continuation = page > 1
          ? _continuationTokens['$sanitizedPlaylistId:${page - 1}']
          : null;
      if (page > 1 && (continuation == null || continuation.isEmpty)) {
        return Result.success(
          Page<PlaylistDetail>(number: page, totalPages: page, data: const []),
        );
      }

      final response = await _youtubeService.browsePlaylist(
        playlistId: continuation == null ? sanitizedPlaylistId : null,
        continuation: continuation,
      );

      final nextToken = response.continuationToken;
      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens['$sanitizedPlaylistId:$page'] = nextToken;
      }

      final header = response.header;
      final owner = header?.owner;
      final thumbnail = header?.thumbnail;
      final detail = PlaylistDetail(
        id: header?.playlistId ?? sanitizedPlaylistId,
        title: header?.title ?? '',
        description: header?.description,
        coverUrl: normalizeYoutubeUrl(
          thumbnail == null || thumbnail.thumbnails.isEmpty
              ? null
              : thumbnail.thumbnails.last.url,
        ),
        creatorName: owner?.text.value,
        creatorId: owner?.browseId,
        totalCount: parseYoutubeCount(header?.videoCountText),
        items: response.items
            .map(
              (item) => _toVideoModel(
                item,
                channelName: owner?.text.value,
                channelId: owner?.browseId,
              ),
            )
            .toList(growable: false),
      );

      return Result.success(
        Page<PlaylistDetail>(
          number: page,
          totalPages: nextToken == null || nextToken.isEmpty ? page : page + 1,
          data: [detail],
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  VideoModel _toVideoModel(
    NetworkYouTubePlaylistVideoItem item, {
    String? channelName,
    String? channelId,
  }) {
    final thumbnail = item.thumbnail;
    return VideoModel(
      id: item.videoId,
      title: item.title ?? '',
      url: buildYoutubeWatchUrl(item.videoId),
      thumbnailUrl: normalizeYoutubeUrl(
        thumbnail == null || thumbnail.thumbnails.isEmpty
            ? null
            : thumbnail.thumbnails.last.url,
      ),
      viewCount: _viewCountOf(item.metadataRows),
      uploadDate: _uploadDateOf(item.metadataRows),
      duration: _durationOf(item.lengthText),
      creatorProfileName: item.author?.text.value ?? channelName,
      creatorProfileId: item.author?.browseId ?? channelId,
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

  int? _durationOf(String? lengthText) {
    if (lengthText == null || lengthText.isEmpty) return null;
    final parts = lengthText.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    }
    return null;
  }
}
