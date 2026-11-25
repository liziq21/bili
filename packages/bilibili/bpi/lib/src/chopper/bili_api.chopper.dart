// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'bili_api.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$BiliNetworkApi extends BiliNetworkApi {
  _$BiliNetworkApi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = BiliNetworkApi;

  @override
  Future<NetworkSearchSuggest> getSuggests(
    String term,
    String highlight, [
    String mainVer = 'v1',
  ]) async {
    final Uri $url = Uri.parse('https://s.search.bilibili.com/main/suggest');
    final Map<String, dynamic> $params = <String, dynamic>{
      'term': term,
      'highlight': highlight,
      'main_ver': mainVer,
    };
    final Map<String, String> $headers = {'content-type': 'application/json'};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    final Response<NetworkSearchSuggest> $response = await client
        .send<NetworkSearchSuggest, NetworkSearchSuggest>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkSearchResult> searchAll(
    String keyword, {
    int? page,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/wbi/search/all/v2',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'keyword': keyword,
      'page': page,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkSearchResult> $response = await client
        .send<NetworkSearchResult, NetworkSearchResult>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkSearchResult> typeSearch(
    SearchType searchType,
    String keyword, {
    int? page,
    String? order,
    String? duration,
    String? tids,
    String? orderSort,
    String? userType,
    String? categoryId,
    String? pubTimeBeginS,
    String? pubTimeEndS,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'search_type': searchType,
      'keyword': keyword,
      'page': page,
      'order': order,
      'duration': duration,
      'tids': tids,
      'order_sort': orderSort,
      'user_type': userType,
      'category_id': categoryId,
      'pubtime_begin_s': pubTimeBeginS,
      'pubtime_end_s': pubTimeEndS,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkSearchResult> $response = await client
        .send<NetworkSearchResult, NetworkSearchResult>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<VideoDetailData> videoIntro({required String bvid}) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/web-interface/view');
    final Map<String, dynamic> $params = <String, dynamic>{'bvid': bvid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<VideoDetailData> $response = await client
        .send<VideoDetailData, VideoDetailData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliVideoParts> getVideoParts({required String bvid}) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/player/pagelist');
    final Map<String, dynamic> $params = <String, dynamic>{'bvid': bvid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliVideoParts> $response = await client
        .send<NetworkBiliVideoParts, NetworkBiliVideoParts>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliVideoSnapshot> getVideoSnapshot({
    required String bvid,
    int index = 1,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/player/videoshot');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bvid': bvid,
      'index': index,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliVideoSnapshot> $response = await client
        .send<NetworkBiliVideoSnapshot, NetworkBiliVideoSnapshot>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliVideoTags> getVideoTags({required String bvid}) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/view/detail/tag',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'bvid': bvid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliVideoTags> $response = await client
        .send<NetworkBiliVideoTags, NetworkBiliVideoTags>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliHomeFeed> getHomeFeed({
    int freshType = 3,
    int pageSize = 12,
    int version = 1,
    String feedVersion = 'V8',
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/wbi/index/top/feed/rcmd',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'fresh_type': freshType,
      'ps': pageSize,
      'version': version,
      'feed_version': feedVersion,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkBiliHomeFeed> $response = await client
        .send<NetworkBiliHomeFeed, NetworkBiliHomeFeed>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliSeriesArchives> getSeriesArchives({
    required int mid,
    required int seriesId,
    bool onlyNormal = true,
    String sort = 'desc',
    int page = 1,
    int pageSize = 30,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/series/archives');
    final Map<String, dynamic> $params = <String, dynamic>{
      'mid': mid,
      'series_id': seriesId,
      'only_normal': onlyNormal,
      'sort': sort,
      'pn': page,
      'ps': pageSize,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliSeriesArchives> $response = await client
        .send<NetworkBiliSeriesArchives, NetworkBiliSeriesArchives>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBangumiPlayUrlV2> getBangumiPlayUrlV2({
    int? epId,
    int? cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/pgc/player/web/v2/playurl',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'ep_id': epId,
      'cid': cid,
      'qn': qn,
      'fnval': fnval,
      'fourk': fourk,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBangumiPlayUrlV2> $response = await client
        .send<NetworkBangumiPlayUrlV2, NetworkBangumiPlayUrlV2>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkVideoRelation> getVideoRelation({required String bvid}) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/archive/relation',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'bvid': bvid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkVideoRelation> $response = await client
        .send<NetworkVideoRelation, NetworkVideoRelation>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkRelatedVideosList> getRelatedVideos({
    required String bvid,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/archive/related',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'bvid': bvid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkRelatedVideosList> $response = await client
        .send<NetworkRelatedVideosList, NetworkRelatedVideosList>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/popular',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'pn': page,
      'ps': pageSize,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliPopularResponse> $response = await client
        .send<NetworkBiliPopularResponse, NetworkBiliPopularResponse>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/web-interface/ranking/v2',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'rid': rankingId,
      'type': type,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliRankingResponse> $response = await client
        .send<NetworkBiliRankingResponse, NetworkBiliRankingResponse>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkReplyData> getReplyListMain({
    required int oid,
    required int type,
    String? paginationStr,
    int? mode,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/v2/reply/main');
    final Map<String, dynamic> $params = <String, dynamic>{
      'oid': oid,
      'type': type,
      'pagination_str': paginationStr,
      'mode': mode,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkReplyData> $response = await client
        .send<NetworkReplyData, NetworkReplyData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int? page,
    int? sort,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/v2/reply');
    final Map<String, dynamic> $params = <String, dynamic>{
      'oid': oid,
      'type': type,
      'pn': page,
      'sort': sort,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkReplyData> $response = await client
        .send<NetworkReplyData, NetworkReplyData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int? page,
    int? sort,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/v2/reply/reply');
    final Map<String, dynamic> $params = <String, dynamic>{
      'oid': oid,
      'root': root,
      'type': type,
      'pn': page,
      'sort': sort,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkReplyReplyData> $response = await client
        .send<NetworkReplyReplyData, NetworkReplyReplyData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkPlayUrl> getPlayUrl(
    String bvid,
    int cid, {
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
    int fnver = 0,
    int tryLook = 1,
    int webLocation = 1315873,
    String dmImgList = '[]',
    required String dmImgStr,
    required String dmCoverImgStr,
    required String dmImgInter,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/player/wbi/playurl');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bvid': bvid,
      'cid': cid,
      'qn': qn,
      'fnval': fnval,
      'fourk': fourk,
      'fnver': fnver,
      'try_look': tryLook,
      'web_location': webLocation,
      'dm_img_list': dmImgList,
      'dm_img_str': dmImgStr,
      'dm_cover_img_str': dmCoverImgStr,
      'dm_img_inter': dmImgInter,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkPlayUrl> $response = await client
        .send<NetworkPlayUrl, NetworkPlayUrl>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliPlayerInfo> getPlayerInfo({
    required String bvid,
    required int cid,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/player/v2');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bvid': bvid,
      'cid': cid,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliPlayerInfo> $response = await client
        .send<NetworkBiliPlayerInfo, NetworkBiliPlayerInfo>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/xlive/web-room/v1/index/getH5InfoByRoom',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'room_id': roomId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveRoomDetail> $response = await client
        .send<NetworkLiveRoomDetail, NetworkLiveRoomDetail>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'room_id': roomId,
      'qn': qn,
      'protocol': protocol,
      'format': format,
      'codec': codec,
      'platform': platform,
      'ptype': ptype,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveRoomPlayInfo> $response = await client
        .send<NetworkLiveRoomPlayInfo, NetworkLiveRoomPlayInfo>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'id': roomId};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveDanmakuInfo> $response = await client
        .send<NetworkLiveDanmakuInfo, NetworkLiveDanmakuInfo>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    required List<int> roomIds,
    String reqBiz = 'web',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/xlive/web-room/v1/index/getRoomBaseInfo',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'room_ids': roomIds,
      'req_biz': reqBiz,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveRoomBaseInfo> $response = await client
        .send<NetworkLiveRoomBaseInfo, NetworkLiveRoomBaseInfo>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    required List<int> uids,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/room/v1/Room/get_status_info_by_uids',
    );
    final Map<String, dynamic> $params = <String, dynamic>{'uids[]': uids};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveStatusByUids> $response = await client
        .send<NetworkLiveStatusByUids, NetworkLiveStatusByUids>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    int pageSize = 30,
    String platform = 'web',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.live.bilibili.com/room/v1/room/get_user_recommend',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'page_size': pageSize,
      'platform': platform,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkLiveRecommendedRooms> $response = await client
        .send<NetworkLiveRecommendedRooms, NetworkLiveRecommendedRooms>(
          $request,
        );
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliUserCardData> getUserCard({required int mid}) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/web-interface/card');
    final Map<String, dynamic> $params = <String, dynamic>{'mid': mid};
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliUserCardData> $response = await client
        .send<NetworkBiliUserCardData, NetworkBiliUserCardData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/space/article');
    final Map<String, dynamic> $params = <String, dynamic>{
      'mid': mid,
      'pn': page,
      'ps': pageSize,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBiliUserArticlesData> $response = await client
        .send<NetworkBiliUserArticlesData, NetworkBiliUserArticlesData>(
          $request,
        );
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/space/wbi/arc/search',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'mid': mid,
      'pn': page,
      'ps': pageSize,
      'order': order,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkBiliUserVideosData> $response = await client
        .send<NetworkBiliUserVideosData, NetworkBiliUserVideosData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBangumiSeasonData> getBangumiSeason({
    int? seasonId,
    int? epId,
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/pgc/view/web/season');
    final Map<String, dynamic> $params = <String, dynamic>{
      'season_id': seasonId,
      'ep_id': epId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkBangumiSeasonData> $response = await client
        .send<NetworkBangumiSeasonData, NetworkBangumiSeasonData>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkPlayUrl> getBangumiPlayUrl({
    int? epId,
    int? cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/pgc/player/web/playurl',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'ep_id': epId,
      'cid': cid,
      'qn': qn,
      'fnval': fnval,
      'fourk': fourk,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    final Response<NetworkPlayUrl> $response = await client
        .send<NetworkPlayUrl, NetworkPlayUrl>($request);
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    bool sortReverse = false,
    int? seasonId,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/polymer/web-space/seasons_archives_list',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'mid': mid,
      'page_num': pageNum,
      'page_size': pageSize,
      'sort_reverse': sortReverse,
      'season_id': seasonId,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkBiliPlaylistContentData> $response = await client
        .send<NetworkBiliPlaylistContentData, NetworkBiliPlaylistContentData>(
          $request,
        );
    return $response.bodyOrThrow;
  }

  @override
  Future<NetworkBiliPlaylistListData> getUserPlaylists({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse(
      'https://api.bilibili.com/x/polymer/web-space/seasons_series_list',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'mid': mid,
      'page_num': pageNum,
      'page_size': pageSize,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: tag,
    );
    final Response<NetworkBiliPlaylistListData> $response = await client
        .send<NetworkBiliPlaylistListData, NetworkBiliPlaylistListData>(
          $request,
        );
    return $response.bodyOrThrow;
  }
}
