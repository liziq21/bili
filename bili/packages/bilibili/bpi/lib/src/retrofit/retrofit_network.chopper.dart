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
    final Response $response = await client
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
    final Response $response = await client
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
    final Response $response = await client
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
    final Response $response = await client
        .send<VideoDetailData, VideoDetailData>($request);
    return $response.bodyOrThrow;
  }
}
