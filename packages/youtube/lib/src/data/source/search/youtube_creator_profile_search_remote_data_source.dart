import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';
import 'youtube_network_search_mapper.dart';

final class const YouTubeCreatorProfileSearchRemoteDataSource(
  final YoutubeService _youtubeService,
) extends CreatorProfileSearchRemoteDataSource with YouTubeRemoteDataSource {
  @override
  List<SortOption> get sortOptions => const [];

  static final Map<String, String> _continuationTokens = {};

  @override
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  }) async {
    try {
      final targetPage = pageKey ?? 1;
      final continuationKey = '$query:$targetPage';
      final previousContinuationKey = '$query:${targetPage - 1}';
      final continuation = targetPage > 1
          ? _continuationTokens[previousContinuationKey]
          : null;

      final response = await _youtubeService.searchChannels(
        query,
        continuation: continuation,
      );
      final nextToken = channelContinuationToken(response);
      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens[continuationKey] = nextToken;
      }

      final profiles = channelRenderers(response)
          .map(_toCreatorProfile)
          .toList(growable: false);
      final totalPages = nextToken == null || nextToken.isEmpty
          ? targetPage
          : targetPage + 1;
      return Result.ok(
        Page<CreatorProfile>(
          number: targetPage,
          totalPages: totalPages,
          data: profiles,
        ),
      );
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  CreatorProfile _toCreatorProfile(NetworkYouTubeChannelRenderer channel) {
    return CreatorProfile(
      id: channel.channelId,
      name: channel.title?.value ?? '',
      thumbnailUrl: channel.thumbnail?.thumbnails.lastOrNull?.url,
      videos: _parseInt(channel.videoCountText?.value),
    );
  }

  int? _parseInt(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  }
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
