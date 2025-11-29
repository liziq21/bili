import '../../bili/category.dart';
import '../../bili/date_range.dart';
import '../../bili/search_order.dart';
import '../../bili/user_type.dart';
import '../../bili/video_duration_filter.dart';
import 'model/search/network_search_result.dart';
import 'model/search/network_search_suggest.dart';
import 'retrofit/api_result.dart';
import 'retrofit/search_api_result.dart';

abstract interface class NetworkSearchDataSource {
  
  Future<ApiResult<NetworkSearchResult>> search(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchArticle(
    String keyword, {
    int? page,
    ArticleCategory? category,
    ArticleSearchOrder? order,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchBiliUser(
    String keyword, {
    int? page,
    UserSearchSort? sort,
    UserType? userType,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchMediaBangumi(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchMediaFt(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchLive(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchLiveRoom(
    String keyword, {
    int? page,
    LiveRoomSearchOrder? order,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchLiveUser(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchPhoto(
    String keyword, {
    int? page,
    PhotoCategory? category,
    PhotoOrVideoSearchOrder? order,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchTopic(
    String keyword, {
    int? page,
  });
  
  Future<ApiResult<NetworkSearchResult>> searchVideo(
    String keyword, {
    int? page,
    PhotoOrVideoSearchOrder? order,
    VideoDurationFilter? duration,
    int? tids,
    DateRange? dateRange
  });
  
  Future<SearchApiResult<NetworkSearchSuggest>> searchSuggest(String term);
  
}