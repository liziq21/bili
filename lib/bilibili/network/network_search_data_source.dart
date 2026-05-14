import '../../utils/result.dart';
import 'model/search/network_search_result.dart';
import 'model/search_suggest/network_search_suggest.dart';

abstract interface class NetworkSearchDataSource {
  Future<Result<NetworkSearchResult>> searchAll(String keyword, {int? page});

  Future<Result<NetworkSearchResult>> searchArticle(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  });

  Future<Result<NetworkSearchResult>> searchBiliUser(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  });

  Future<Result<NetworkSearchResult>> searchMediaBangumi(
    String keyword, {
    int? page,
  });

  Future<Result<NetworkSearchResult>> searchMediaFt(
    String keyword, {
    int? page,
  });

  Future<Result<NetworkSearchResult>> searchLive(String keyword, {int? page});

  Future<Result<NetworkSearchResult>> searchLiveRoom(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  });

  Future<Result<NetworkSearchResult>> searchLiveUser(
    String keyword, {
    int? page,
  });

  Future<Result<NetworkSearchResult>> searchPhoto(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  });

  Future<Result<NetworkSearchResult>> searchTopic(String keyword, {int? page});

  Future<Result<NetworkSearchResult>> searchVideo(
    String keyword, {
    int? page,
    Map<String, String>? parameters,
  });

  Future<Result<NetworkSearchSuggest>> getSuggests(String term);
}
