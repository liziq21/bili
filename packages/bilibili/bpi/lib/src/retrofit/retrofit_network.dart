import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../model/reply/network_reply_data.dart';
import '../model/reply/network_reply_reply_data.dart';
import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import '../model/video/network_play_url.dart';
import '../model/video/network_related_video.dart';
import '../model/video/network_video_relation.dart';
import '../model/video/video_detail_data.dart';
import '../network_search_data_source.dart';
import '../network_video_data_source.dart';
import '../search_type.dart';
import 'api_interceptor.dart';
import 'chopper_wbi_interceptor.dart';
import 'json_serializable_converter.dart';
import 'token_manager.dart';
import 'token_storage.dart';

part 'retrofit_network.chopper.dart';

@ChopperApi(baseUrl: Api.base)
abstract class BiliNetworkApi extends ChopperService {
  @GET(
    path: SearchApi.suggest,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  )
  Future<NetworkSearchSuggest> getSuggests(
    @query String term,
    @query String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);

  @GET(path: WbiApiPath.searchAll)
  Future<NetworkSearchResult> searchAll(
    @query String keyword, {
    @query int? page,
    @tag String tag = 'WBI',
  });

  @GET(path: WbiApiPath.searchByType)
  Future<NetworkSearchResult> typeSearch(
    @Query('search_type') SearchType searchType,
    @query String keyword, {
    @query int? page,
    @query String? order,
    @query String? duration,
    @query String? tids,
    @Query('order_sort') String? orderSort,
    @Query('user_type') String? userType,
    @Query('category_id') String? categoryId,
    @Query('pubtime_begin_s') String? pubTimeBeginS,
    @Query('pubtime_end_s') String? pubTimeEndS,
    @tag String tag = 'WBI',
  });

  @GET(path: ApiPath.videoIntro)
  Future<VideoDetailData> videoIntro({@query required String bvid});

  @GET(path: ApiPath.videoRelation)
  Future<NetworkVideoRelation> getVideoRelation({@query required String bvid});

  @GET(path: ApiPath.relatedList)
  Future<NetworkRelatedVideosList> getRelatedVideos({@query required String bvid});

  @GET(path: ApiPath.replyListMain)
  Future<NetworkReplyData> getReplyListMain({
    @query required int oid,
    @query required int type,
    @Query('pagination_str') String? paginationStr,
    @query int? mode,
  });

  @GET(path: ApiPath.replyList)
  Future<NetworkReplyData> getReplyList({
    @query required int oid,
    @query required int type,
    @Query('pn') int? page,
    @query int? sort,
  });

  @GET(path: ApiPath.replyReplyList)
  Future<NetworkReplyReplyData> getReplyReplyList({
    @query required int oid,
    @query required int root,
    @query required int type,
    @Query('pn') int? page,
    @query int? sort,
  });

  @GET(path: WbiApiPath.playUrl)
  Future<NetworkPlayUrl> getPlayUrl(
    @query String bvid,
    @query int cid, {
    @query int qn = 80,
    @query int fnval = 4048,
    @query int fourk = 1,
    @tag String tag = 'WBI',
  });

  static BiliNetworkApi create([ChopperClient? client]) =>
      _$BiliNetworkApi(client ?? .new());
}

class BiliNetworkSearch implements NetworkSearchDataSource, NetworkVideoDataSource {
  BiliNetworkSearch({http.Client? client, TokenStorage? storage})
    : _httpClient = client ?? http.Client(),
      _ownsHttpClient = client == null {
    _chopperClient = ChopperClient(
      client: _httpClient,
      converter: JsonSerializableConverter({
        NetworkSearchResult: NetworkSearchResult.fromJson,
        NetworkSearchSuggest: NetworkSearchSuggest.fromJson,
        VideoDetailData: VideoDetailData.fromJson,
        NetworkVideoRelation: NetworkVideoRelation.fromJson,
        NetworkRelatedVideosList: NetworkRelatedVideosList.fromJson,
        NetworkReplyData: NetworkReplyData.fromJson,
        NetworkReplyReplyData: NetworkReplyReplyData.fromJson,
        NetworkPlayUrl: NetworkPlayUrl.fromJson,
      }),
      interceptors: [
        ApiInterceptor(),
        BiliWbiInterceptor(
          tokenManager: TokenManager(storage: storage),
          client: _httpClient,
        ),
      ],
    );
    _networkApi = BiliNetworkApi.create(_chopperClient);
  }

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  late final ChopperClient _chopperClient;
  late final BiliNetworkApi _networkApi;

  Future<void> close() async {
    _chopperClient.dispose();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  @override
  Future<NetworkSearchSuggest> getSuggests(String term) =>
      _networkApi.getSuggests(term, term);

  @override
  Future<NetworkSearchResult> searchAll(String keyword, {int? page}) =>
      _networkApi.searchAll(keyword, page: page);

  @override
  Future<NetworkSearchResult> searchArticle(
    String keyword, {
    int? page,
    String? order,
    String? orderSort,
  }) => _networkApi.typeSearch(
    .article,
    keyword,
    page: page,
    order: order,
    orderSort: orderSort,
  );

  @override
  Future<NetworkSearchResult> searchBiliUser(
    String keyword, {
    int? page,
    String? order,
    String? orderSort,
    String? userType,
  }) => _networkApi.typeSearch(
    .biliUser,
    keyword,
    page: page,
    order: order,
    orderSort: orderSort,
    userType: userType,
  );

  @override
  Future<NetworkSearchResult> searchLive(String keyword, {int? page}) =>
      _networkApi.typeSearch(.live, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchLiveRoom(
    String keyword, {
    int? page,
    String? order,
  }) => _networkApi.typeSearch(.liveRoom, keyword, page: page, order: order);

  @override
  Future<NetworkSearchResult> searchLiveUser(String keyword, {int? page}) =>
      _networkApi.typeSearch(.liveUser, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchMediaBangumi(String keyword, {int? page}) =>
      _networkApi.typeSearch(.mediaBangumi, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchMediaFt(String keyword, {int? page}) =>
      _networkApi.typeSearch(.mediaFt, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchPhoto(
    String keyword, {
    int? page,
    String? order,
    String? categoryId,
  }) => _networkApi.typeSearch(
    .photo,
    keyword,
    page: page,
    order: order,
    categoryId: categoryId,
  );

  @override
  Future<NetworkSearchResult> searchTopic(String keyword, {int? page}) =>
      _networkApi.typeSearch(.topic, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchVideo(
    String keyword, {
    int? page,
    String? order,
    String? duration,
    String? tids,
    String? pubTimeBeginS,
    String? pubTimeEndS,
  }) => _networkApi.typeSearch(
    .video,
    keyword,
    page: page,
    order: order,
    duration: duration,
    tids: tids,
    pubTimeBeginS: pubTimeBeginS,
    pubTimeEndS: pubTimeEndS,
  );

  @override
  Future<VideoDetailData> getVideoDetail({required String bvid}) =>
      _networkApi.videoIntro(bvid: bvid);

  @override
  Future<NetworkVideoRelation> getVideoRelation({required String bvid}) =>
      _networkApi.getVideoRelation(bvid: bvid);

  @override
  Future<List<NetworkRelatedVideo>> getRelatedVideos({required String bvid}) async {
    final response = await _networkApi.getRelatedVideos(bvid: bvid);
    return response.items;
  }

  @override
  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int page = 1,
    int sort = 1,
    String? nextOffset,
  }) {
    if (nextOffset != null && nextOffset.isNotEmpty) {
      final paginationStr = '{"offset":"${nextOffset.replaceAll('"', '\\"')}"}';
      return _networkApi.getReplyListMain(
        oid: oid,
        type: type,
        paginationStr: paginationStr,
        mode: sort + 2,
      );
    }
    return _networkApi.getReplyList(
      oid: oid,
      type: type,
      page: page,
      sort: sort,
    );
  }

  @override
  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int page = 1,
  }) => _networkApi.getReplyReplyList(
    oid: oid,
    root: root,
    type: type,
    page: page,
    sort: 1,
  );

  @override
  Future<NetworkPlayUrl> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) => _networkApi.getPlayUrl(
    bvid,
    cid,
    qn: qn,
    fnval: fnval,
    fourk: fourk,
  );
}
