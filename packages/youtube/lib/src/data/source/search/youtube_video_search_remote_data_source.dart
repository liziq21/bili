import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../../../search/search_filter.dart';
import '../../../search/sort.dart';
import '../../../youtube_utils.dart';
import '../youtube_remote_data_source.dart';
import 'youtube_network_search_mapper.dart';

final class const YouTubeVideoSearchRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoSearchRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

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
  Future<Result<Page<VideoModel>, Exception>> searchVideo(
    SearchQuery searchQuery,
  ) async {
    try {
      final targetPage = searchQuery.pageKey;
      final query = searchQuery.query.replaceAll(_controlChars, '').trim();
      if (query.isEmpty) {
        return Result.success(
          Page<VideoModel>(
            number: targetPage,
            totalPages: targetPage,
            data: const [],
          ),
        );
      }

      int? sort;
      if (searchQuery.sortOption case final YoutubeSearchSort s) {
        sort = s.sortValue;
      }

      int? uploadDate;
      int? duration;
      final features = <int>{};

      for (final filter in searchQuery.filters) {
        switch (filter) {
          case SingleFilterGroup(key: 'upload_date', :final selection):
            uploadDate = youtubeFilterOptionFrom(
              selection,
              YoutubeUploadDateFilterOption.values,
            )?.paramValue;
          case SingleFilterGroup(key: 'duration', :final selection):
            duration = youtubeFilterOptionFrom(
              selection,
              YoutubeDurationFilterOption.values,
            )?.paramValue;
          case MultiFilterGroup(key: 'feature', :final selections):
            for (final selection in selections) {
              final feature = youtubeFilterOptionFrom(
                selection,
                YoutubeFeatureFilterOption.values,
              );
              if (feature != null) {
                features.add(feature.paramValue);
              }
            }
          default:
            break;
        }
      }

      final searchParams = (
        sort: sort,
        uploadDate: uploadDate,
        duration: duration,
        features: features,
      );

      final continuationKey = '$query:$targetPage';
      final previousContinuationKey = '$query:${targetPage - 1}';
      final continuation = targetPage > 1
          ? _continuationTokens[previousContinuationKey]
          : null;

      final response = await _youtubeService.searchVideos(
        query,
        params: searchParams.encode(),
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
      return Result.success(
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
      url: buildYoutubeWatchUrl(video.videoId),
      thumbnailUrl: normalizeYoutubeUrl(
        video.thumbnail?.thumbnails.lastOrNull?.url,
      ),
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

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
