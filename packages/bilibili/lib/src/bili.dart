import 'package:bpi/bpi.dart';
import 'package:http/http.dart';

import 'data/repository/bilibili_search_contents_repository.dart';
import 'data/repository/bilibili_search_suggest_repository.dart';

class Bili() {
  static Client? client;
  BiliNetworkSearch? _networkSearch;
  NetworkSearchDataSource get _bpi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  Future<void> close() async => _networkSearch?.close();
  BilibiliVideoSearchRepository videoSearchRepository() => .new(network: _bpi);

  BilibiliUserSearchRepository userSearchRepository() => .new(network: _bpi);

  BilibiliLiveRoomSearchRepository liveRoomSearchRepository() =>
      .new(network: _bpi);

  BilibiliAggregateSearchRepository aggregateSearchRepository() =>
      .new(network: _bpi);

  BilibiliSearchSuggestRepository searchSuggestRepository() =>
      .new(network: _bpi);
}
