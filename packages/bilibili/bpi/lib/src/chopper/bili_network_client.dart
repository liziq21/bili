import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../device/bili_device_fingerprint.dart';
import '../model/feed/network_bili_popular_response.dart';
import '../model/feed/network_bili_ranking_response.dart';
import '../model/live/network_live_danmaku_info.dart';
import '../model/live/network_live_room_detail.dart';
import '../model/live/network_live_room_play_info.dart';
import '../model/reply/network_reply_data.dart';
import '../model/reply/network_reply_reply_data.dart';
import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import '../model/user/network_bili_playlist_content.dart';
import '../model/user/network_bili_user_article.dart';
import '../model/user/network_bili_user_card.dart';
import '../model/user/network_bili_user_videos.dart';
import '../model/video/network_bangumi_season.dart';
import '../model/video/network_bili_player_info.dart';
import '../model/video/network_play_url.dart';
import '../model/video/network_related_video.dart';
import '../model/video/network_video_relation.dart';
import '../model/video/video_detail_data.dart';
import 'api_interceptor.dart';
import 'bili_api.dart';
import 'danmaku_client.dart';
import 'error_interceptor.dart';
import 'json_serializable_converter.dart';
import 'token_manager.dart';
import 'token_storage.dart';
import 'wbi_interceptor.dart';

/// Shared Chopper wiring for the bpi endpoint mixins.
///
/// [BiliNetworkSearch] assembles the per-domain mixins on top of this client;
/// the mixins only reach the endpoints through [api].
class BiliNetworkClient {
  BiliNetworkClient({http.Client? client, TokenStorage? storage})
    : httpClient = client ?? http.Client(),
      _ownsHttpClient = client == null,
      device = BiliDeviceFingerprint.forge() {
    final converter = JsonSerializableConverter(
      {
        NetworkSearchResult: NetworkSearchResult.fromJson,
        NetworkSearchSuggest: NetworkSearchSuggest.fromJson,
        VideoDetailData: VideoDetailData.fromJson,
        NetworkVideoRelation: NetworkVideoRelation.fromJson,
        NetworkRelatedVideosList: NetworkRelatedVideosList.fromJson,
        NetworkReplyData: NetworkReplyData.fromJson,
        NetworkReplyReplyData: NetworkReplyReplyData.fromJson,
        NetworkPlayUrl: NetworkPlayUrl.fromJson,
        NetworkBiliPlayerInfo: NetworkBiliPlayerInfo.fromJson,
        NetworkLiveRoomDetail: NetworkLiveRoomDetail.fromJson,
        NetworkLiveRoomPlayInfo: NetworkLiveRoomPlayInfo.fromJson,
        NetworkLiveDanmakuInfo: NetworkLiveDanmakuInfo.fromJson,
        NetworkBiliUserCardData: NetworkBiliUserCardData.fromJson,
        NetworkBiliUserArticlesData: NetworkBiliUserArticlesData.fromJson,
        NetworkBiliUserVideosData: NetworkBiliUserVideosData.fromJson,
        NetworkBangumiSeasonData: NetworkBangumiSeasonData.fromJson,
        NetworkBiliPlaylistContentData: NetworkBiliPlaylistContentData.fromJson,
        NetworkBiliPlaylistListData: NetworkBiliPlaylistListData.fromJson,
      },
      envelopeFactories: {
        NetworkBiliPopularResponse: NetworkBiliPopularResponse.fromJson,
        NetworkBiliRankingResponse: NetworkBiliRankingResponse.fromJson,
      },
    );
    _chopperClient = ChopperClient(
      client: httpClient,
      converter: converter,
      errorConverter: converter,
      interceptors: [
        // Outermost on purpose: it has to cover the interceptors below and
        // Chopper's response converter, where JSON decoding happens.
        const BpiErrorInterceptor(),
        const ApiInterceptor(),
        BiliWbiInterceptor(
          tokenManager: TokenManager(storage: storage),
          client: httpClient,
        ),
      ],
    );
    api = BiliNetworkApi.create(_chopperClient);
  }

  final http.Client httpClient;
  final bool _ownsHttpClient;
  final BiliDeviceFingerprint device;

  /// Client for the XML danmaku endpoint, which is not JSON.
  late final BiliDanmakuClient danmaku = BiliDanmakuClient(httpClient);

  late final ChopperClient _chopperClient;
  late final BiliNetworkApi api;

  Future<void> close() async {
    _chopperClient.dispose();
    if (_ownsHttpClient) {
      httpClient.close();
    }
  }
}
