import 'package:data/data.dart';
import 'package:http/http.dart' as http;
import 'package:ypi/ypi.dart';

import 'data/source/search/youtube_creator_profile_search_remote_data_source.dart';
import 'data/source/search/youtube_search_suggest_remote_data_source.dart';
import 'data/source/search/youtube_video_search_remote_data_source.dart';

class YouTube implements MediaSource {
  YouTube({YoutubeService? youtubeService, http.Client? httpClient})
      : _youtubeService = youtubeService ??
            YoutubeService(httpClient: httpClient);

  final YoutubeService _youtubeService;

  YoutubeService get youtubeService => _youtubeService;

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube';

  @override
  YouTubeVideoSearchRemoteDataSource get videoSearchDataSource =>
      YouTubeVideoSearchRemoteDataSource(youtubeService: _youtubeService);

  @override
  YouTubeCreatorProfileSearchRemoteDataSource
      get creatorProfileSearchDataSource =>
          YouTubeCreatorProfileSearchRemoteDataSource(
            youtubeService: _youtubeService,
          );

  @override
  YouTubeSearchSuggestRemoteDataSource get searchSuggestDataSource =>
      YouTubeSearchSuggestRemoteDataSource(youtubeService: _youtubeService);

  @override
  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;

  @override
  LiveRoomSearchRemoteDataSource? get liveRoomSearchDataSource => null;

  @override
  VideoDetailRemoteDataSource? get videoDetailDataSource => null;

  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  Future<void> close() async {
    _youtubeService.close();
  }
}
