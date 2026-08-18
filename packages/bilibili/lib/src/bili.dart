import 'package:bpi/bpi.dart';

import 'data/repository/bilibili_search_contents_repository.dart';
import 'data/repository/bilibili_search_suggest_repository.dart';

class Bili() {
  late final NetworkSearchDataSource _bpi = BiliNetworkSearch();

  BilibiliVideoSearchRepository videoSearchRepository() => .new(network: _bpi);

  BilibiliUserSearchRepository userSearchRepository() => .new(network: _bpi);

  BilibiliLiveRoomSearchRepository liveRoomSearchRepository() =>
      .new(network: _bpi);

  BilibiliAggregateSearchRepository aggregateSearchRepository() =>
      .new(network: _bpi);

  BilibiliSearchSuggestRepository searchSuggestRepository() =>
      .new(network: _bpi);
}
