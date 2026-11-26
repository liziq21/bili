import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:http/http.dart';

import 'data/source/bili_channel_playlists_remote_data_source.dart';
import 'data/source/bili_creator_profile_remote_data_source.dart';
import 'data/source/bili_feed_remote_data_source.dart';
import 'data/source/bili_live_room_detail_remote_data_source.dart';
import 'data/source/bili_danmaku_remote_data_source.dart';
import 'data/source/bili_live_danmaku_remote_data_source.dart';
import 'data/source/bili_media_stream_remote_data_source.dart';
import 'data/source/bili_playlist_content_remote_data_source.dart';
import 'data/source/bili_popular_video_feed_remote_data_source.dart';
import 'data/source/bili_ranking_video_feed_remote_data_source.dart';
import 'data/source/bili_user_articles_remote_data_source.dart';
import 'data/source/bili_user_videos_remote_data_source.dart';
import 'data/source/bili_video_comment_remote_data_source.dart';
import 'data/source/bili_video_detail_remote_data_source.dart';
import 'data/source/search/bili_aggregate_search_remote_data_source.dart';
import 'data/source/search/bili_creator_profile_search_remote_data_source.dart';
import 'data/source/search/bili_live_room_search_remote_data_source.dart';
import 'data/source/search/bili_search_suggest_remote_data_source.dart';
import 'data/source/search/bili_video_search_remote_data_source.dart';

class Bili() implements MediaSource {
  static Client? client;

  /// 直播流地址探测所用的客户端工厂。
  ///
  /// 刻意不复用 [client]：debug 构建把 [client] 包成 `HttpLogClient`，它在
  /// `send()` 里先 `response.stream.toBytes()` 把整个响应读完。直播流是无限
  /// 响应，`toBytes()` 永不结束，于是每个候选都在探测超时后被判为不可用，
  /// 直播间在 debug 下 100% 加载失败且重试不可能成功（#664）。探测只需要
  /// 首批字节，用不带缓冲的裸客户端即可。
  static Client Function() probeClientFactory = Client.new;

  /// 播放地址请求时携带的浏览器标识。
  ///
  /// B站 CDN 对裸 `Mozilla/5.0` 的请求会拒绝，故此处用带完整平台与版本
  /// 信息的标识。取值与 bpi 请求层（`api_interceptor.dart:14`）刻意不同：
  /// 那是 API 请求的标识，这是分片 CDN 的标识，两者互不影响。
  static const String browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  BiliNetworkSearch? _networkSearch;

  NetworkSearchDataSource get _searchApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  NetworkUserDataSource get _userApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  NetworkUserPlaylistDataSource get _userPlaylistApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  NetworkVideoDataSource get _videoApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  NetworkLiveDataSource get _liveApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  NetworkBiliFeedDataSource get _feedApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  @override
  String get id => 'bilibili';

  @override
  String get name => 'Bilibili';

  @override
  Future<void> close() async => _networkSearch?.close();

  @override
  BiliAggregateSearchRemoteDataSource get aggregateSearchDataSource =>
      .new(network: _searchApi);

  @override
  BiliCreatorProfileSearchRemoteDataSource get creatorProfileSearchDataSource =>
      .new(network: _searchApi);

  @override
  BiliCreatorProfileRemoteDataSource get creatorProfileDataSource =>
      .new(network: _userApi);

  @override
  BiliLiveRoomSearchRemoteDataSource get liveRoomSearchDataSource =>
      .new(network: _searchApi);

  @override
  BiliVideoSearchRemoteDataSource get videoSearchDataSource =>
      .new(network: _searchApi);

  @override
  BiliSearchSuggestRemoteDataSource get searchSuggestDataSource =>
      .new(network: _searchApi);

  @override
  BiliVideoDetailRemoteDataSource get videoDetailDataSource =>
      .new(network: _videoApi);

  @override
  BiliVideoCommentRemoteDataSource get videoCommentDataSource =>
      .new(network: _videoApi);

  @override
  BiliVideoCommentRemoteDataSource get videoCommentRepliesDataSource =>
      .new(network: _videoApi);

  @override
  BiliDanmakuRemoteDataSource get danmakuDataSource => .new(network: _videoApi);

  @override
  BiliLiveDanmakuRemoteDataSource get liveDanmakuDataSource =>
      .new(network: _liveApi);

  @override
  BiliMediaStreamRemoteDataSource get mediaStreamDataSource =>
      .new(network: _videoApi, browserUserAgent: browserUserAgent);

  @override
  BiliLiveRoomDetailRemoteDataSource get liveRoomDetailDataSource => .new(
    network: _liveApi,
    browserUserAgent: browserUserAgent,
    clientFactory: probeClientFactory,
  );

  @override
  List<VideoFeedRemoteDataSource> get videoFeedDataSources => [
    BiliPopularVideoFeedRemoteDataSource(network: _feedApi),
    BiliRankingVideoFeedRemoteDataSource(network: _feedApi),
  ];

  @override
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => [
    BiliRecommendLiveRoomFeedRemoteDataSource(network: _liveApi),
  ];

  @override
  UserVideosRemoteDataSource? get userVideosDataSource =>
      BiliUserVideosRemoteDataSource(network: _userApi);

  @override
  UserArticlesRemoteDataSource? get userArticlesDataSource =>
      BiliUserArticlesRemoteDataSource(network: _userApi);

  @override
  PlaylistContentRemoteDataSource? get playlistContentDataSource =>
      BiliPlaylistContentRemoteDataSource(network: _userApi);

  @override
  ChannelPlaylistsRemoteDataSource? get channelPlaylistsDataSource =>
      BiliChannelPlaylistsRemoteDataSource(network: _userPlaylistApi);
}
