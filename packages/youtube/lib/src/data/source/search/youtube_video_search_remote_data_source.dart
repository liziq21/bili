import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../../search/search_filter.dart';
import '../../../search/sort.dart';
import '../youtube_remote_data_source.dart';

final class const YouTubeVideoSearchRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoSearchRemoteDataSource with YouTubeRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [
        YoutubeUploadDateFilterGroup(),
        YoutubeDurationFilterGroup(),
        YoutubeFeatureFilterGroup(),
      ];

  @override
  List<SortOption> get sortOptions => YoutubeSearchSort.values;

  static final Map<String, String> _continuationTokens = {};

  @override
  Future<Result<Page<VideoModel>>> searchVideo(
    String query, {
    int? pageKey,
  }) async {
    return searchVideoWithOptions(
      SearchQuery(query: query, pageKey: pageKey ?? 1),
    );
  }

  Future<Result<Page<VideoModel>>> searchVideoWithOptions(
    SearchQuery searchQuery,
  ) async {
    try {
      final targetPage = searchQuery.pageKey;
      final query = searchQuery.query;

      int? sort;
      if (searchQuery.sortOption is YoutubeSearchSort) {
        sort = (searchQuery.sortOption as YoutubeSearchSort).valueInt;
      }

      int? uploadDate;
      int? duration;
      final features = <int>{};

      for (final filter in searchQuery.filters) {
        if (filter is SingleFilterGroup) {
          if (filter.key == 'upload_date' && filter.selection != null) {
            final sel = filter.selection;
            if (sel is YoutubeUploadDateFilterOption) {
              uploadDate = sel.valueInt;
            } else {
              final found = YoutubeUploadDateFilterOption.values.firstWhere(
                (e) => e.value == sel!.value,
                orElse: () => YoutubeUploadDateFilterOption.today,
              );
              uploadDate = found.valueInt;
            }
          } else if (filter.key == 'duration' && filter.selection != null) {
            final sel = filter.selection;
            if (sel is YoutubeDurationFilterOption) {
              duration = sel.valueInt;
            } else {
              final found = YoutubeDurationFilterOption.values.firstWhere(
                (e) => e.value == sel!.value,
                orElse: () => YoutubeDurationFilterOption.fourTo20Minutes,
              );
              duration = found.valueInt;
            }
          }
        } else if (filter is MultiFilterGroup && filter.key == 'feature') {
          for (final sel in filter.selections) {
            if (sel is YoutubeFeatureFilterOption) {
              features.add(sel.fieldTag);
            } else {
              final found = YoutubeFeatureFilterOption.values.firstWhere(
                (e) => e.value == sel.value,
                orElse: () => YoutubeFeatureFilterOption.hd,
              );
              features.add(found.fieldTag);
            }
          }
        }
      }

      final continuationKey = '$query:$targetPage';
      final prevContinuationKey = '$query:${targetPage - 1}';

      final continuationToken = targetPage > 1
          ? _continuationTokens[prevContinuationKey]
          : null;

      final (videos, nextToken) = await _youtubeService.searchVideos(
        query,
        sort: sort,
        uploadDate: uploadDate,
        duration: duration,
        features: features,
        continuation: continuationToken,
      );

      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens[continuationKey] = nextToken;
      }

      final totalPages = (nextToken != null && nextToken.isNotEmpty)
          ? targetPage + 1
          : targetPage;

      return Result.ok(
        Page<VideoModel>(
          number: targetPage,
          totalPages: totalPages,
          data: videos,
        ),
      );
    } catch (e, st) {
      return Result.error(Exception('$e\n$st'));
    }
  }
}
