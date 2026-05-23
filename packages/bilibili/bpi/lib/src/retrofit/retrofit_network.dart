import 'dart:io';

import 'package:chopper/chopper.dart';

import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import '../network_search_data_source.dart';
import '../search_type.dart';
import '../uris.dart';
import 'json_serializable_converter.dart';

part 'retrofit_network.chopper.dart';

@ChopperApi(baseUrl: ApiUris.base)
abstract class BiliNetworkApi extends ChopperService {
  @GET(
    path: SearchUris.suggest,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  )
  Future<NetworkSearchSuggest> getSuggests(
    @Query('term') String term,
    @Query('highlight') String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);

  @GET(path: ApiUriPaths.search)
  Future<NetworkSearchResult> searchAll(
    @Query('keyword') String keyword, {
    @Query('page') int? page,
  });

  @GET(path: ApiUriPaths.searchType)
  Future<NetworkSearchResult> typeSearch(
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

  static BiliNetworkApi create([ChopperClient? client]) => _$BiliNetworkApi(
    client ??
        .new(
          converter: JsonSerializableConverter({
            NetworkSearchResult: NetworkSearchResult.fromJson,
            NetworkSearchSuggest: NetworkSearchSuggest.fromJson,
          }),
        ),
  );
}

class BiliNetworkSearch implements NetworkSearchDataSource {
  final BiliNetworkApi _networkApi;

  BiliNetworkSearch() : _networkApi = BiliNetworkApi.create();

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
}
