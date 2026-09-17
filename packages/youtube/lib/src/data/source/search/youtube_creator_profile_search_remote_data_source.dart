import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeCreatorProfileSearchRemoteDataSource({
  required final YoutubeService _youtubeService,
}) extends CreatorProfileSearchRemoteDataSource with YouTubeRemoteDataSource {
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
      final prevContinuationKey = '$query:${targetPage - 1}';

      final continuationToken = targetPage > 1
          ? _continuationTokens[prevContinuationKey]
          : null;

      final (profiles, nextToken) = await _youtubeService.searchChannels(
        query,
        continuation: continuationToken,
      );

      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens[continuationKey] = nextToken;
      }

      final totalPages = (nextToken != null && nextToken.isNotEmpty)
          ? targetPage + 1
          : targetPage;

      return Result.ok(
        Page<CreatorProfile>(
          number: targetPage,
          totalPages: totalPages,
          data: profiles,
        ),
      );
    } catch (e, st) {
      return Result.error(Exception('$e\n$st'));
    }
  }
}
