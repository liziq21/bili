import '../model/feed/network_bili_home_feed.dart';
import '../model/feed/network_bili_popular_response.dart';
import '../model/feed/network_bili_ranking_response.dart';
import '../network_feed_data_source.dart';
import 'bili_network_client.dart';

mixin FeedEndpoints on BiliNetworkClient implements NetworkBiliFeedDataSource {
  @override
  Future<NetworkBiliHomeFeed> getHomeFeed({int pageSize = 12}) =>
      api.getHomeFeed(pageSize: pageSize);

  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) => api.getPopular(page: page, pageSize: pageSize);

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) => api.getRanking(rankingId: rankingId, type: type);
}
