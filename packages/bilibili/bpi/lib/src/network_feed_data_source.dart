import 'model/feed/network_bili_popular_response.dart';
import 'model/feed/network_bili_ranking_response.dart';

abstract interface class NetworkBiliFeedDataSource {
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  });

  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  });
}
