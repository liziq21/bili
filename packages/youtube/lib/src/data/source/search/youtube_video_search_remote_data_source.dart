import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../youtube_remote_data_source.dart';

final class const YouTubeVideoSearchRemoteDataSource({
  required final YoutubeExplode _youtubeExplode,
}) extends VideoSearchRemoteDataSource with YouTubeRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<VideoModel>>> searchVideo(
    String query, {
    int? pageKey,
  }) async {
    try {
      final targetPage = pageKey ?? 1;
      VideoSearchList searchList = await _youtubeExplode.search.search(query);

      for (int i = 1; i < targetPage; i++) {
        final nextPage = await searchList.nextPage();
        if (nextPage == null) {
          return Result.ok(
            Page<VideoModel>(
              number: targetPage,
              totalPages: targetPage,
              data: const [],
            ),
          );
        }
        searchList = nextPage;
      }

      final videos = searchList.map((item) {
        return VideoModel(
          id: item.id.value,
          title: item.title,
          url: item.url,
          thumbnailUrl: item.thumbnails.mediumResUrl,
          viewCount: item.engagement.viewCount,
          uploadDate: item.uploadDate,
          duration: item.duration?.inSeconds,
          desc: item.description,
          creatorProfileName: item.author,
          creatorProfileId: item.channelId.value,
        );
      }).toList();

      final totalPages = searchList.isNotEmpty ? targetPage + 1 : targetPage;

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
