import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../../youtube_utils.dart';
import '../youtube_remote_data_source.dart';
import 'youtube_network_search_mapper.dart';

final class const YouTubeCreatorProfileSearchRemoteDataSource(
  final YoutubeService _youtubeService,
) extends CreatorProfileSearchRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// YouTube channel IDs are `UC` plus 22 URL-safe characters. The app's
  /// creator-profile repository resolves a channel page by passing the channel
  /// ID as a search query; a text search for an ID does not reliably return
  /// that channel, so ID-shaped queries browse the channel directly.
  static final RegExp _channelIdPattern = RegExp(r'^UC[A-Za-z0-9_-]{22}$');

  @override
  List<SortOption> get sortOptions => const [];

  static final Map<String, String> _continuationTokens = {};

  @override
  Future<Result<Page<CreatorProfile>, Exception>> searchCreatorProfile(
    String query, {
    int? pageKey,
  }) async {
    try {
      final targetPage = pageKey ?? 1;
      final sanitizedQuery = query.replaceAll(_controlChars, '').trim();
      if (sanitizedQuery.isEmpty) {
        return Result.success(
          Page<CreatorProfile>(
            number: targetPage,
            totalPages: targetPage,
            data: const [],
          ),
        );
      }
      if (targetPage == 1 && _channelIdPattern.hasMatch(sanitizedQuery)) {
        final response = await _youtubeService.browseChannel(
          browseId: sanitizedQuery,
        );
        final metadata = response.channelMetadata;
        final header = response.header;
        if (metadata != null || header != null) {
          final avatar = metadata?.avatar ?? header?.avatar;
          return Result.success(
            Page<CreatorProfile>(
              number: 1,
              totalPages: 1,
              data: [
                CreatorProfile(
                  id: metadata?.channelId ?? header!.channelId,
                  name: metadata?.title ?? header?.title ?? '',
                  description: metadata?.description,
                  thumbnailUrl: normalizeYoutubeUrl(
                    avatar == null || avatar.thumbnails.isEmpty
                        ? null
                        : avatar.thumbnails.last.url,
                  ),
                  subscribers: parseYoutubeCount(
                    header?.subscriberCountText?.value,
                  ),
                ),
              ],
            ),
          );
        }
      }
      final continuationKey = '$sanitizedQuery:$targetPage';
      final previousContinuationKey = '$sanitizedQuery:${targetPage - 1}';
      final continuation = targetPage > 1
          ? _continuationTokens[previousContinuationKey]
          : null;

      final response = await _youtubeService.searchChannels(
        sanitizedQuery,
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
      return Result.success(
        Page<CreatorProfile>(
          number: targetPage,
          totalPages: totalPages,
          data: profiles,
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  CreatorProfile _toCreatorProfile(NetworkYouTubeChannelRenderer channel) {
    return CreatorProfile(
      id: channel.channelId,
      name: channel.title?.value ?? '',
      thumbnailUrl: normalizeYoutubeUrl(
        channel.thumbnail?.thumbnails.lastOrNull?.url,
      ),
      videos: _parseInt(channel.videoCountText?.value),
    );
  }

  int? _parseInt(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final lower = text.toLowerCase().replaceAll(',', '');
    final numMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(K|M)?',
      caseSensitive: false,
    ).firstMatch(lower);
    if (numMatch == null) {
      return null;
    }
    final value = double.tryParse(numMatch.group(1)!) ?? 0.0;
    final suffix = numMatch.group(2)?.toUpperCase();
    switch (suffix) {
      case 'M':
        return (value * 1e6).round();
      case 'K':
        return (value * 1e3).round();
      default:
        return value.round();
    }
  }
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
