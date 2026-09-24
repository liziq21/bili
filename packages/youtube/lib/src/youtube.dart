import 'package:data/data.dart';
import 'package:http/http.dart' as http;
import 'package:ypi/ypi.dart';

import 'data/source/search/youtube_creator_profile_search_remote_data_source.dart';
import 'data/source/search/youtube_search_suggest_remote_data_source.dart';
import 'data/source/search/youtube_video_search_remote_data_source.dart';
import 'data/source/youtube_feed_remote_data_source.dart';

class YouTube({YoutubeService? youtubeService, http.Client? httpClient}) implements MediaSource {
  this
    : _youtubeService =
          youtubeService ?? YoutubeService(httpClient: httpClient);

  final YoutubeService _youtubeService;

  YoutubeService get youtubeService => _youtubeService;

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube';

  @override
  YouTubeVideoSearchRemoteDataSource get videoSearchDataSource =>
      YouTubeVideoSearchRemoteDataSource(_youtubeService);

  @override
  YouTubeCreatorProfileSearchRemoteDataSource
  get creatorProfileSearchDataSource =>
      YouTubeCreatorProfileSearchRemoteDataSource(_youtubeService);

  @override
  YouTubeSearchSuggestRemoteDataSource get searchSuggestDataSource =>
      YouTubeSearchSuggestRemoteDataSource(_youtubeService);

  @override
  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;

  @override
  LiveRoomSearchRemoteDataSource? get liveRoomSearchDataSource => null;

  @override
  VideoDetailRemoteDataSource? get videoDetailDataSource => null;

  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  List<VideoFeedRemoteDataSource> get videoFeedDataSources => [
        YouTubeRecommendVideoFeedRemoteDataSource(_youtubeService),
        YouTubeTrendingVideoFeedRemoteDataSource(_youtubeService),
      ];

  @override
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  @override
  Future<void> close() async {
    _youtubeService.close();
  }
}
