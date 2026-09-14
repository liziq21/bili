import 'package:http/http.dart' as http;

import 'data/source/search/youtube_creator_profile_search_remote_data_source.dart';
import 'data/source/search/youtube_search_suggest_remote_data_source.dart';
import 'data/source/search/youtube_video_search_remote_data_source.dart';
import 'service/youtube_service.dart';

class YouTube {
  YouTube({YoutubeService? youtubeService, http.Client? httpClient})
      : _youtubeService = youtubeService ??
            YoutubeService(httpClient: httpClient);

  final YoutubeService _youtubeService;

  YoutubeService get youtubeService => _youtubeService;

  YouTubeVideoSearchRemoteDataSource videoSearchDataSource() =>
      YouTubeVideoSearchRemoteDataSource(youtubeService: _youtubeService);

  YouTubeCreatorProfileSearchRemoteDataSource
      creatorProfileSearchDataSource() =>
          YouTubeCreatorProfileSearchRemoteDataSource(
            youtubeService: _youtubeService,
          );

  YouTubeSearchSuggestRemoteDataSource searchSuggestDataSource() =>
      YouTubeSearchSuggestRemoteDataSource(youtubeService: _youtubeService);

  void close() {
    _youtubeService.close();
  }
}
