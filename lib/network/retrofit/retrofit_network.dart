import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../bili/constonts/uris.dart';
import '../../bili/category.dart';
import '../../bili/date_range.dart';
import '../../bili/search_type.dart';
import '../../bili/search_order.dart';
import '../../bili/user_type.dart';
import '../../bili/video_duration_filter.dart';
import '../../utils/result.dart';
import '../network_search_data_source.dart';
import '../model/search/network_search_result.dart';
import '../model/search/search_suggest/network_search_suggest.dart';
import 'api_call_adaper.dart';
import 'api_result.dart';

part 'retrofit_network.g.dart';

@RestApi(callAdapter: ApiCallAdapter)
abstract class BiliNetworkApi {
  
  factory BiliNetworkApi(Dio dio, { String? baseUrl }) = _BiliNetworkApi;
  
  @GET(ApiUriPaths.search)
  Future<Result<NetworkSearchResult>> search(
    @Query('keyword') String keyword, {
    @Query('page') int? page,
  });
  
  @GET(ApiUriPaths.searchType)
  Future<Result<NetworkSearchResult>> searchByType(
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
  Future<Result<NetworkSearchSuggest>> getSuggests(
    @Query('term') String term,
    @Query('highlight') String highlight, [
    @Query('main_ver') String mainVer = 'v1',
  ]);
}

class BiliNetworkSearch implements NetworkSearchDataSource {

  final BiliNetworkApi networkApi = BiliNetworkApi(
    Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          HttpHeaders.cookieHeader: '{"SESSDATA"="xxx"}',
        },
      ),
    ),
    baseUrl: ApiUris.base,
  );
  
  @override
  Future<Result<NetworkSearchResult>> search(
    String keyword, {
    int? page,
  }) async => networkApi.search(
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchArticle(
    String keyword, {
    int? page,
    ArticleCategory? category,
    ArticleSearchOrder? order,
  }) async =>
    networkApi.searchByType(
      .article,
      keyword,
      page: page,
      order: order,
      categoryId: category,
    );
    
  
  @override
  Future<Result<NetworkSearchResult>> searchBiliUser(
    String keyword, {
    int? page,
    UserSearchSort? sort,
    UserType? userType,
  }) async => networkApi.searchByType(
    .biliUser,
    keyword,
    page: page,
    order: sort?.order,
    orderSort: sort?.orderSort,
    userType: userType,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchMediaBangumi(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    .mediaBangumi,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchMediaFt(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    .mediaFt,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchLive(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    .live,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchLiveRoom(
    String keyword, {
    int? page,
    LiveRoomSearchOrder? order,
  }) async => networkApi.searchByType(
    .liveRoom,
    keyword,
    page: page,
    order: order,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchLiveUser(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    .liveUser,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchPhoto(
    String keyword, {
    int? page,
    PhotoCategory? category,
    PhotoOrVideoSearchOrder? order,
  }) async => networkApi.searchByType(
    .photo,
    keyword,
    page: page,
    order: order,
    categoryId: category,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchTopic(
    String keyword, {
    int? page,
  }) async => networkApi.searchByType(
    .topic,
    keyword,
    page: page,
  );
  
  @override
  Future<Result<NetworkSearchResult>> searchVideo(
    String keyword, {
    int? page,
    PhotoOrVideoSearchOrder? order,
    VideoDurationFilter? duration,
    int? tids,
    DateRange? dateRange,
  }) async => networkApi.searchByType(
    .video,
    keyword,
    page: page,
    order: order,
    duration: duration,
    tids: tids,
    pubTimeBeginS: dateRange?.start.millisecondsSinceEpoch.intDiv(1000),
    pubTimeEndS: dateRange?.end.millisecondsSinceEpoch.intDiv(1000),
  );
  
  @override
  Future<Result<NetworkSearchSuggest>> getSuggests(String term) async =>
    networkApi.getSuggests(term, term);
}

extension on int {
  int intDiv(int divisor) => this ~/ divisor;
}
