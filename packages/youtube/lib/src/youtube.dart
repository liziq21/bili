import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'data/source/search/youtube_creator_profile_search_remote_data_source.dart';
import 'data/source/search/youtube_search_suggest_remote_data_source.dart';
import 'data/source/search/youtube_video_search_remote_data_source.dart';

class YouTube {
  YouTube({YoutubeExplode? youtubeExplode})
    : _youtubeExplode = youtubeExplode ?? YoutubeExplode();

  final YoutubeExplode _youtubeExplode;

  YoutubeExplode get youtubeExplode => _youtubeExplode;

  YouTubeVideoSearchRemoteDataSource videoSearchDataSource() =>
      YouTubeVideoSearchRemoteDataSource(youtubeExplode: _youtubeExplode);

  YouTubeCreatorProfileSearchRemoteDataSource
  creatorProfileSearchDataSource() => YouTubeCreatorProfileSearchRemoteDataSource(youtubeExplode: _youtubeExplode);

  YouTubeSearchSuggestRemoteDataSource searchSuggestDataSource() =>
      YouTubeSearchSuggestRemoteDataSource(youtubeExplode: _youtubeExplode);

  void close() {
    _youtubeExplode.close();
  }
}
