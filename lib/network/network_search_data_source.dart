import '../../bili/category.dart';
import '../../bili/date_range.dart';
import '../../bili/search_order.dart';
import '../../bili/user_type.dart';
import '../../bili/video_duration_filter.dart';
import '../../utils/reault.dart';
import 'model/search/network_search_result.dart';
import 'model/search/network_search_suggest.dart';

abstract interface class NetworkSearchDataSource {
  
  Future<Result<NetworkSearchResult>> search(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchArticle(
    String keyword, {
    int? page,
    ArticleCategory? category,
    ArticleSearchOrder? order,
  });
  
  Future<Result<NetworkSearchResult>> searchBiliUser(
    String keyword, {
    int? page,
    UserSearchSort? sort,
    UserType? userType,
  });
  
  Future<Result<NetworkSearchResult>> searchMediaBangumi(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchMediaFt(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchLive(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchLiveRoom(
    String keyword, {
    int? page,
    LiveRoomSearchOrder? order,
  });
  
  Future<Result<NetworkSearchResult>> searchLiveUser(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchPhoto(
    String keyword, {
    int? page,
    PhotoCategory? category,
    PhotoOrVideoSearchOrder? order,
  });
  
  Future<Result<NetworkSearchResult>> searchTopic(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearchResult>> searchVideo(
    String keyword, {
    int? page,
    PhotoOrVideoSearchOrder? order,
    VideoDurationFilter? duration,
    int? tids,
    DateRange? dateRange
  });
  
  Future<Result<NetworkSearchSuggest>> getSuggests(String term);
  
}