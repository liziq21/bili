import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import 'youtube_remote_data_source.dart';

final class const YouTubeRecommendVideoFeedRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoFeedRemoteDataSource with YouTubeRemoteDataSource {
  @override
  String get id => 'recommend';

  @override
  String get title => '推荐视频';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) async {
    try {
      final (videos, _) = await _youtubeService.searchVideos('Flutter');
      return Result.ok(
        Page<VideoModel>(
          number: pageKey ?? 1,
          totalPages: 1,
          data: videos,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final class const YouTubeTrendingVideoFeedRemoteDataSource(
  final YoutubeService _youtubeService,
) extends VideoFeedRemoteDataSource with YouTubeRemoteDataSource {
  @override
  String get id => 'trending';

  @override
  String get title => '时下热门';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) async {
    try {
      final (videos, _) = await _youtubeService.searchVideos('Trending');
      return Result.ok(
        Page<VideoModel>(
          number: pageKey ?? 1,
          totalPages: 1,
          data: videos,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}
