import '../model/search/network_search_result.dart';
import '../model/search_suggest/network_search_suggest.dart';
import '../network_search_data_source.dart';
import 'bili_network_client.dart';

mixin SearchEndpoints on BiliNetworkClient implements NetworkSearchDataSource {
  @override
  Future<NetworkSearchSuggest> getSuggests(String term) =>
      api.getSuggests(term, term);

  @override
  Future<NetworkSearchResult> searchAll(String keyword, {int? page}) =>
      api.searchAll(keyword, page: page);

  @override
  Future<NetworkSearchResult> searchArticle(
    String keyword, {
    int? page,
    String? order,
    String? orderSort,
  }) => api.typeSearch(
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
  }) => api.typeSearch(
    .biliUser,
    keyword,
    page: page,
    order: order,
    orderSort: orderSort,
    userType: userType,
  );

  @override
  Future<NetworkSearchResult> searchLive(String keyword, {int? page}) =>
      api.typeSearch(.live, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchLiveRoom(
    String keyword, {
    int? page,
    String? order,
  }) => api.typeSearch(.liveRoom, keyword, page: page, order: order);

  @override
  Future<NetworkSearchResult> searchLiveUser(String keyword, {int? page}) =>
      api.typeSearch(.liveUser, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchMediaBangumi(String keyword, {int? page}) =>
      api.typeSearch(.mediaBangumi, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchMediaFt(String keyword, {int? page}) =>
      api.typeSearch(.mediaFt, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchPhoto(
    String keyword, {
    int? page,
    String? order,
    String? categoryId,
  }) => api.typeSearch(
    .photo,
    keyword,
    page: page,
    order: order,
    categoryId: categoryId,
  );

  @override
  Future<NetworkSearchResult> searchTopic(String keyword, {int? page}) =>
      api.typeSearch(.topic, keyword, page: page);

  @override
  Future<NetworkSearchResult> searchVideo(
    String keyword, {
    int? page,
    String? order,
    String? duration,
    String? tids,
    String? pubTimeBeginS,
    String? pubTimeEndS,
  }) => api.typeSearch(
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
