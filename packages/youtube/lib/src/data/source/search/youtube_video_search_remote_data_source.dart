import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import '../youtube_remote_data_source.dart';

final class YoutubeSortOption extends SortOption {
  const YoutubeSortOption(super.label, this.sort);

  final YoutubeSearchSort sort;

  @override
  String get value => sort.name;

  @override
  Map<String, String> toQueryParams() => {'sort': value};
}

final class YoutubeFilterOption implements FilterOption {
  const YoutubeFilterOption({required this.label, required this.value});

  @override
  final String label;

  @override
  final String value;
}

final class const YouTubeVideoSearchRemoteDataSource({
  required final YoutubeService _youtubeService,
}) extends VideoSearchRemoteDataSource with YouTubeRemoteDataSource {
  static const _sortOptionsList = [
    YoutubeSortOption('相关性', YoutubeSearchSort.relevance),
    YoutubeSortOption('上传时间', YoutubeSearchSort.uploadDate),
    YoutubeSortOption('播放量', YoutubeSearchSort.viewCount),
    YoutubeSortOption('评分', YoutubeSearchSort.rating),
  ];

  static const _uploadDateFilterGroup = SingleFilterGroup(
    key: 'upload_date',
    label: '上传时间',
    options: [
      YoutubeFilterOption(label: '1小时内', value: 'lastHour'),
      YoutubeFilterOption(label: '今天', value: 'today'),
      YoutubeFilterOption(label: '本周', value: 'thisWeek'),
      YoutubeFilterOption(label: '本月', value: 'thisMonth'),
      YoutubeFilterOption(label: '本年', value: 'thisYear'),
    ],
  );

  static const _durationFilterGroup = SingleFilterGroup(
    key: 'duration',
    label: '视频时长',
    options: [
      YoutubeFilterOption(label: '4分钟以下', value: 'under4Minutes'),
      YoutubeFilterOption(label: '4-20分钟', value: 'fourTo20Minutes'),
      YoutubeFilterOption(label: '20分钟以上', value: 'over20Minutes'),
    ],
  );

  static const _featureFilterGroup = MultiFilterGroup(
    key: 'feature',
    label: '功能特性',
    options: [
      YoutubeFilterOption(label: '直播', value: 'live'),
      YoutubeFilterOption(label: '4K', value: 'fourK'),
      YoutubeFilterOption(label: '高清', value: 'hd'),
      YoutubeFilterOption(label: '字幕/CC', value: 'subtitles'),
      YoutubeFilterOption(label: '知识共享', value: 'creativeCommons'),
      YoutubeFilterOption(label: '3D', value: 'threeD'),
      YoutubeFilterOption(label: '360°', value: 'threeSixty'),
      YoutubeFilterOption(label: 'HDR', value: 'hdr'),
    ],
  );

  @override
  List<FilterGroup> get filters => const [
        _uploadDateFilterGroup,
        _durationFilterGroup,
        _featureFilterGroup,
      ];

  @override
  List<SortOption> get sortOptions => _sortOptionsList;

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

      YoutubeSearchSort sort = YoutubeSearchSort.relevance;
      if (searchQuery.sortOption is YoutubeSortOption) {
        sort = (searchQuery.sortOption as YoutubeSortOption).sort;
      }

      YoutubeUploadDateFilter? uploadDate;
      YoutubeDurationFilter? duration;
      final features = <YoutubeFeatureFilter>{};

      for (final filter in searchQuery.filters) {
        if (filter is SingleFilterGroup) {
          if (filter.key == 'upload_date' && filter.selection != null) {
            uploadDate = YoutubeUploadDateFilter.values.firstWhere(
              (e) => e.name == filter.selection!.value,
              orElse: () => YoutubeUploadDateFilter.today,
            );
          } else if (filter.key == 'duration' && filter.selection != null) {
            duration = YoutubeDurationFilter.values.firstWhere(
              (e) => e.name == filter.selection!.value,
              orElse: () => YoutubeDurationFilter.fourTo20Minutes,
            );
          }
        } else if (filter is MultiFilterGroup && filter.key == 'feature') {
          for (final sel in filter.selections) {
            final f = YoutubeFeatureFilter.values.firstWhere(
              (e) => e.name == sel.value,
              orElse: () => YoutubeFeatureFilter.hd,
            );
            features.add(f);
          }
        }
      }

      final continuationKey = '$query:$targetPage';
      final prevContinuationKey = '$query:${targetPage - 1}';

      final continuationToken =
          targetPage > 1 ? _continuationTokens[prevContinuationKey] : null;

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
