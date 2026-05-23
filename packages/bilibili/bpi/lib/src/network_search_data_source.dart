import 'model/search/network_search_result.dart';
import 'model/search_suggest/network_search_suggest.dart';

abstract interface class NetworkSearchDataSource {
  Future<NetworkSearchResult> searchAll(String keyword, {int? page});

  Future<NetworkSearchResult> searchArticle(
    String keyword, {
    int? page,
    String? order,
    String? orderSort,
  });

  Future<NetworkSearchResult> searchBiliUser(
    String keyword, {
    int? page,
    String? order,
    String? orderSort,
    String? userType,
  });

  Future<NetworkSearchResult> searchMediaBangumi(String keyword, {int? page});

  Future<NetworkSearchResult> searchMediaFt(String keyword, {int? page});

  Future<NetworkSearchResult> searchLive(String keyword, {int? page});

  Future<NetworkSearchResult> searchLiveRoom(
    String keyword, {
    int? page,
    String? order,
  });

  Future<NetworkSearchResult> searchLiveUser(String keyword, {int? page});

  Future<NetworkSearchResult> searchPhoto(
    String keyword, {
    int? page,
    String? order,
    String? categoryId,
  });

  Future<NetworkSearchResult> searchTopic(String keyword, {int? page});

  Future<NetworkSearchResult> searchVideo(
    String keyword, {
    int? page,
    String? order,
    String? duration,
    String? tids,
    String? pubTimeBeginS,
    String? pubTimeEndS,
  });

  Future<NetworkSearchSuggest> getSuggests(String term);
}
