import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../../search/search_filter.dart';
import '../../../search/sort.dart';
import '../youtube_remote_data_source.dart';
import 'youtube_network_search_mapper.dart';

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
          final selection = filter.selection;
          if (selection == null) {
            continue;
          }
          if (filter.key == 'upload_date') {
            if (selection is YoutubeUploadDateFilterOption) {
              uploadDate = selection.valueInt;
            } else {
              final found = YoutubeUploadDateFilterOption.values.firstWhere(
                (option) => option.value == selection.value,
                orElse: () => YoutubeUploadDateFilterOption.today,
              );
              uploadDate = found.valueInt;
            }
          } else if (filter.key == 'duration') {
            if (selection is YoutubeDurationFilterOption) {
              duration = selection.valueInt;
            } else {
              final found = YoutubeDurationFilterOption.values.firstWhere(
                (option) => option.value == selection.value,
                orElse: () => YoutubeDurationFilterOption.fourTo20Minutes,
              );
              duration = found.valueInt;
            }
          }
        } else if (filter is MultiFilterGroup && filter.key == 'feature') {
          for (final selection in filter.selections) {
            if (selection is YoutubeFeatureFilterOption) {
              features.add(selection.fieldTag);
            } else {
              final found = YoutubeFeatureFilterOption.values.firstWhere(
                (option) => option.value == selection.value,
                orElse: () => YoutubeFeatureFilterOption.hd,
              );
              features.add(found.fieldTag);
            }
          }
        }
      }

      final continuationKey = '$query:$targetPage';
      final previousContinuationKey = '$query:${targetPage - 1}';
      final continuation = targetPage > 1
          ? _continuationTokens[previousContinuationKey]
          : null;

      final response = await _youtubeService.searchVideos(
        query,
        sort: sort,
        uploadDate: uploadDate,
        duration: duration,
        features: features,
        continuation: continuation,
      );
      final nextToken = videoContinuationToken(response);
      if (nextToken != null && nextToken.isNotEmpty) {
        _continuationTokens[continuationKey] = nextToken;
      }

      final videos = videoRenderers(response)
          .map(_toVideoModel)
          .toList(growable: false);
      final totalPages = nextToken == null || nextToken.isEmpty
          ? targetPage
          : targetPage + 1;
      return Result.ok(
        Page<VideoModel>(
          number: targetPage,
          totalPages: totalPages,
          data: videos,
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  VideoModel _toVideoModel(NetworkYouTubeVideoRenderer video) {
    return VideoModel(
      id: video.videoId,
      title: video.title?.value ?? '',
      url: 'https://www.youtube.com/watch?v=${video.videoId}',
      thumbnailUrl: video.thumbnail?.thumbnails.lastOrNull?.url,
      viewCount: _parseInt(video.viewCountText?.value),
      uploadDate: _parseUploadDate(video.publishedTimeText?.value),
      duration: _parseDuration(video.lengthText?.value),
      desc: video.descriptionSnippet?.value,
      creatorProfileName: video.owner?.text.value,
      creatorProfileId: video.owner?.browseId,
    );
  }

  int? _parseInt(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final lower = text.toLowerCase();
    final numMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(K|M)?', caseSensitive: false).firstMatch(lower);
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

  DateTime? _parseUploadDate(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final direct = DateTime.tryParse(text);
    if (direct != null) {
      return direct;
    }
    final match = RegExp(r'\d+').firstMatch(text.toLowerCase());
    if (match == null) {
      return null;
    }
    final amount = int.tryParse(match.group(0)!) ?? 0;
    final lower = text.toLowerCase();
    if (lower.contains('minute') || lower.contains('分钟')) {
      return DateTime.now().subtract(Duration(minutes: amount));
    }
    if (lower.contains('hour') || lower.contains('小时')) {
      return DateTime.now().subtract(Duration(hours: amount));
    }
    if (lower.contains('day') || lower.contains('天')) {
      return DateTime.now().subtract(Duration(days: amount));
    }
    if (lower.contains('week') || lower.contains('周')) {
      return DateTime.now().subtract(Duration(days: amount * 7));
    }
    if (lower.contains('month') || lower.contains('月')) {
      return DateTime.now().subtract(Duration(days: amount * 30));
    }
    if (lower.contains('year') || lower.contains('年')) {
      return DateTime.now().subtract(Duration(days: amount * 365));
    }
    return null;
  }

  int? _parseDuration(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final parts = text.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60 +
          (int.tryParse(parts[2]) ?? 0);
    }
    return null;
  }
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
