import 'package:data/data.dart';
import 'package:http/http.dart' as http;
import 'package:ypi/ypi.dart';

import 'data/source/search/youtube_creator_profile_search_remote_data_source.dart';
import 'data/source/search/youtube_search_suggest_remote_data_source.dart';
import 'data/source/search/youtube_video_search_remote_data_source.dart';
import 'data/source/youtube_media_stream_remote_data_source.dart';
import 'data/source/youtube_playlist_content_remote_data_source.dart';
import 'data/source/youtube_user_videos_remote_data_source.dart';
import 'data/source/youtube_video_comment_remote_data_source.dart';
import 'data/source/youtube_video_detail_remote_data_source.dart';

class YouTube({YoutubeService? youtubeService, http.Client? httpClient})
    implements MediaSource {
  this
    : _youtubeService =
          youtubeService ?? YoutubeService(httpClient: httpClient ?? client);

  static http.Client? client;

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
  YouTubeVideoDetailRemoteDataSource get videoDetailDataSource =>
      YouTubeVideoDetailRemoteDataSource(_youtubeService);

  @override
  YouTubeVideoCommentRemoteDataSource get videoCommentDataSource =>
      YouTubeVideoCommentRemoteDataSource(_youtubeService);

  /// 二级回复使用评论线程里的 reply continuation token，响应形态与顶层
  /// 评论列表不同；仓库内只有顶层评论 fixture，故不声明该能力。
  @override
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;

  @override
  DanmakuRemoteDataSource? get danmakuDataSource => null;
  @override
  LiveDanmakuRemoteDataSource? get liveDanmakuDataSource => null;

  @override
  YouTubeMediaStreamRemoteDataSource get mediaStreamDataSource =>
      YouTubeMediaStreamRemoteDataSource(
        _youtubeService,
        _youtubeService.playerUserAgent,
      );
  @override
  LiveRoomDetailRemoteDataSource? get liveRoomDetailDataSource => null;

  @override
  List<VideoFeedRemoteDataSource> get videoFeedDataSources => const [];

  @override
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  @override
  YouTubeUserVideosRemoteDataSource get userVideosDataSource =>
      YouTubeUserVideosRemoteDataSource(_youtubeService);

  @override
  UserArticlesRemoteDataSource? get userArticlesDataSource => null;

  @override
  YouTubePlaylistContentRemoteDataSource get playlistContentDataSource =>
      YouTubePlaylistContentRemoteDataSource(_youtubeService);

  @override
  ChannelPlaylistsRemoteDataSource? get channelPlaylistsDataSource => null;

  @override
  Future<void> close() async {
    _youtubeService.close();
  }
}
