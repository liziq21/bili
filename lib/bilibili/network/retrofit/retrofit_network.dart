import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import '../../constonts/uris.dart';
import '../../search_type.dart';
import '../../../utils/result.dart';
import '../network_search_data_source.dart';
import '../model/api_result.dart';
import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import 'api_call_adapter.dart';

part 'retrofit_network.g.dart';

@RestApi(callAdapter: ApiCallAdapter)
abstract class BiliNetworkApi {
  factory BiliNetworkApi(Dio dio, {String? baseUrl}) = _BiliNetworkApi;

  @GET(ApiUriPaths.search)
  Future<Result<NetworkSearchResult>> searchAll(
    @Query('keyword') String keyword, {
    @Query('page') int? page,
  });

  @GET(ApiUriPaths.searchType)
  Future<Result<NetworkSearchResult>> typeSearch(
    @Query('search_type') SearchType searchType,
    @Query('keyword') String keyword, {
    @Query('page') int? page,
    @Query('order') String? order,
    @Query('duration') String? duration,
    @Query('tids') String? tids,
    @Query('order_sort') String? orderSort,
    @Query('user_type') String? userType,
    @Query('category_id') String? categoryId,
    @Query('pubtime_begin_s') String? pubTimeBeginS,
    @Query('pubtime_end_s') String? pubTimeEndS,
  });

  @GET(SearchUris.suggest)
  @Headers({HttpHeaders.contentTypeHeader: 'application/json'})
  Future<Result<NetworkSearchSuggest>> getSuggests(
    @Query('term') String term,
    @Query('highlight') String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);
}

class BiliNetworkSearch implements NetworkSearchDataSource {
  BiliNetworkSearch({required Dio dio})
    : _networkApi = BiliNetworkApi(dio, baseUrl: ApiUris.base);

  final BiliNetworkApi _networkApi;

  @override
  Future<Result<NetworkSearchResult>> searchAll(String keyword, {int? page}) =>
      _networkApi.searchAll(keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchArticle(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  }) => _networkApi.typeSearch(
    .article,
    keyword,
    page: page,
    order: parameters?['order'],
    orderSort: parameters?['orderSort'],
  );
  /*
    order: parameters?['order'],
    duration: parameters?['duration'],
    tids: parameters?['tids'],
    orderSort: parameters?['orderSort'],
    userType: parameters?['userType'],
    categoryId: parameters?['categoryId'],
    pubTimeBeginS: parameters?['pubTimeBeginS'],
    pubTimeEndS: parameters?['pubTimeEndS'],
*/
  @override
  Future<Result<NetworkSearchResult>> searchBiliUser(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  }) => _networkApi.typeSearch(
    .biliUser,
    keyword,
    page: page,
    order: parameters?['order'],
    orderSort: parameters?['orderSort'],
    userType: parameters?['userType'],
  );

  @override
  Future<Result<NetworkSearchResult>> searchMediaBangumi(
    String keyword, {
    int? page,
  }) => _networkApi.typeSearch(.mediaBangumi, keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchMediaFt(
    String keyword, {
    int? page,
  }) => _networkApi.typeSearch(.mediaFt, keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchLive(String keyword, {int? page}) =>
      _networkApi.typeSearch(.live, keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchLiveRoom(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  }) => _networkApi.typeSearch(
    .liveRoom,
    keyword,
    page: page,
    order: parameters?['order'],
  );

  @override
  Future<Result<NetworkSearchResult>> searchLiveUser(
    String keyword, {
    int? page,
  }) => _networkApi.typeSearch(.liveUser, keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchPhoto(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  }) => _networkApi.typeSearch(
    .photo,
    keyword,
    page: page,
    order: parameters?['order'],
    categoryId: parameters?['categoryId'],
  );

  @override
  Future<Result<NetworkSearchResult>> searchTopic(
    String keyword, {
    int? page,
  }) => _networkApi.typeSearch(.topic, keyword, page: page);

  @override
  Future<Result<NetworkSearchResult>> searchVideo(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  }) => _networkApi.typeSearch(
    .video,
    keyword,
    page: page,
    order: parameters?['order'],
    duration: parameters?['duration'],
    tids: parameters?['tids'],
    pubTimeBeginS: parameters?['pubTimeBeginS'],
    pubTimeEndS: parameters?['pubTimeEndS'],
  );

  @override
  Future<Result<NetworkSearchSuggest>> getSuggests(String term) =>
      _networkApi.getSuggests(term, term);
}

extension on int {
  int intDiv(int divisor) => this ~/ divisor;
}
