import 'package:f_biuli/bili/category.dart';
import 'package:f_biuli/bili/date_range.dart';
import 'package:f_biuli/bili/search_order.dart';
import 'package:f_biuli/bili/user_type.dart';
import 'package:f_biuli/bili/video_duration_filter.dart';
import 'model/search/network_search.dart';
import 'model/search/network_search_suggest.dart';
import 'package:f_biuli/utils/result.dart';

abstract interface class NetworkSearchDataSource {
  
  Future<Result<NetworkSearch>> search(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchArticle(
    String keyword, {
    int? page,
    ArticleCategory? category,
    ArticleSearchOrder? order,
  });
  
  Future<Result<NetworkSearch>> searchBiliUser(
    String keyword, {
    int? page,
    UserSearchSort? sort,
    UserType? userType,
  });
  
  Future<Result<NetworkSearch>> searchMediaBangumi(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchMediaFt(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchLive(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchLiveRoom(
    String keyword, {
    int? page,
    LiveRoomSearchOrder? order,
  });
  
  Future<Result<NetworkSearch>> searchLiveUser(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchPhoto(
    String keyword, {
    int? page,
    PhotoCategory? category,
    PhotoOrVideoSearchOrder? order,
  });
  
  Future<Result<NetworkSearch>> searchTopic(
    String keyword, {
    int? page,
  });
  
  Future<Result<NetworkSearch>> searchVideo(
    String keyword, {
    int? page,
    PhotoOrVideoSearchOrder? order,
    VideoDurationFilter? duration,
    int? tids,
    DateRange? dateRange
  });
  
  Future<Result<NetworkSearchSuggest>> searchSuggest(String term);
  
}