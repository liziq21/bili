import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import 'package:f_biuli/bili/constonts/uris.dart';
import 'package:f_biuli/bili/category.dart';
import 'package:f_biuli/bili/date_range.dart';
import 'package:f_biuli/bili/search_type.dart';
import 'package:f_biuli/bili/search_result_type.dart';
import 'package:f_biuli/bili/search_order.dart';
import 'package:f_biuli/bili/user_type.dart';
import 'package:f_biuli/bili/video_duration_filter.dart';
import 'package:f_biuli/utils/result.dart';

import '../network_search_data_source.dart';
import '../model/search/network_search.dart';
import '../model/search/network_search_suggest.dart';
import 'api_call_adapter.dart';
import 'api_result.dart'; // retrofit_network.g.dart 需要

part 'retrofit_network.g.dart';

@lazySingleton
@RestApi(callAdapter: ApiCallAdapter)
abstract class BiliNetworkApi {
  
  @factoryMethod
  factory BiliNetworkApi(
    Dio dio, {
    @Named("apiBase") String? baseUrl,
  }) = _BiliNetworkApi;
  
  @GET(ApiUriPaths.search)
  Future<Result<NetworkSearch>> search(
    @Query('keyword') String keyword, {
    @Query('page') int? page,
  });
  
  @GET(ApiUriPaths.searchType)
  Future<Result<NetworkSearch>> searchByType(
    @Query('search_type') SearchType searchType,
    @Query('keyword') String keyword, {
    @Query('page') int? page,
    @Query('order') SearchOrder? order,
    @Query('duration') VideoDurationFilter? duration,
    @Query('tids') int? tids,
    @Query('order_sort') OrderSort? orderSort,
    @Query('user_type') UserType? userType,
    @Query('category_id') Category? categoryId,
    @Query('pubtime_begin_s') int? pubTimeBeginS,
    @Query('pubtime_end_s') int? pubTimeEndS,
  });
  
  @GET(SearchUris.suggest)
  Future<Result<NetworkSearchSuggest>> searchSuggest(
    @Query('term') String term,
    @Query('highlight') String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);
}

@lazySingleton
class BiliNetworkSearch implements NetworkSearchDataSource {
  const BiliNetworkSearch(this.networkApi);
  
  final BiliNetworkApi networkApi;
  
  @override
  Future<Result<NetworkSearch>> search(
    String keyword, {
    int? page,
  }) async => networkApi.search(
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchArticle(
    String keyword, {
    int? page,
    ArticleCategory? category,
    ArticleSearchOrder? order,
  }) async =>
    networkApi.searchByType(
      SearchType.article,
      keyword,
      page: page,
      order: order,
      categoryId: category,
    );
    
  
  @override
  Future<Result<NetworkSearch>> searchBiliUser(
    String keyword, {
    int? page,
    UserSearchSort? sort,
    UserType? userType,
  }) async => networkApi.searchByType(
    SearchType.biliUser,
    keyword,
    page: page,
    order: sort?.order,
    orderSort: sort?.orderSort,
    userType: userType,
  );
  
  @override
  Future<Result<NetworkSearch>> searchMediaBangumi(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    SearchType.mediaBangumi,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchMediaFt(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    SearchType.mediaFt,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchLive(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    SearchType.live,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchLiveRoom(
    String keyword, {
    int? page,
    LiveRoomSearchOrder? order,
  }) async => networkApi.searchByType(
    SearchType.liveRoom,
    keyword,
    page: page,
    order: order,
  );
  
  @override
  Future<Result<NetworkSearch>> searchLiveUser(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    SearchType.liveUser,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchPhoto(
    String keyword, {
    int? page,
    PhotoCategory? category,
    PhotoOrVideoSearchOrder? order,
  }) async => networkApi.searchByType(
    SearchType.photo,
    keyword,
    page: page,
    order: order,
    categoryId: category,
  );
  
  @override
  Future<Result<NetworkSearch>> searchTopic(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    SearchType.topic,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearch>> searchVideo(
    String keyword, {
    int? page,
    PhotoOrVideoSearchOrder? order,
    VideoDurationFilter? duration,
    int? tids,
    DateRange? dateRange,
  }) async => networkApi.searchByType(
    SearchType.video,
    keyword,
    page: page,
    order: order,
    duration: duration,
    tids: tids,
    pubTimeBeginS: dateRange?.start.millisecondsSinceEpoch.intDiv(1000),
    pubTimeEndS: dateRange?.end.millisecondsSinceEpoch.intDiv(1000),
  );
  
  @override
  Future<Result<NetworkSearchSuggest>> searchSuggest(String term) async =>
    networkApi.searchSuggest(term, term);
}

extension on int {
  int intDiv(int divisor) => this ~/ divisor;
}
