// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'retrofit_network.dart';

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
    String tag = 'WBI',
  }) async {
    final Uri $url = Uri.parse('https://api.bilibili.com/x/player/wbi/playurl');
    final Map<String, dynamic> $params = <String, dynamic>{
      'bvid': bvid,
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
      tag: tag,
    );
    final Response<NetworkPlayUrl> $response = await client
        .send<NetworkPlayUrl, NetworkPlayUrl>($request);
    return $response.bodyOrThrow;
  }
}
