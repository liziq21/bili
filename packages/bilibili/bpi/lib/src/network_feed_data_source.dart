import 'model/feed/network_bili_popular_response.dart';

abstract interface class NetworkBiliFeedDataSource {
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  });
}
