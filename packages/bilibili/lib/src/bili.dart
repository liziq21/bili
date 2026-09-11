import 'package:bpi/bpi.dart';
import 'package:http/http.dart';

import 'data/source/search/bili_aggregate_search_remote_data_source.dart';
import 'data/source/search/bili_creator_profile_search_remote_data_source.dart';
import 'data/source/search/bili_live_room_search_remote_data_source.dart';
import 'data/source/search/bili_search_suggest_remote_data_source.dart';
import 'data/source/search/bili_video_search_remote_data_source.dart';

// App-layer repository types are imported via the app's own modules.
// This file intentionally does not import app repository classes to keep
// the bilibili package free of app-layer dependencies.
class Bili {
  static Client? client;
  BiliNetworkSearch? _networkSearch;
  NetworkSearchDataSource get _searchApi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  Future<void> close() async => _networkSearch?.close();

  BiliAggregateSearchRemoteDataSource aggregateSearchDataSource() =>
      .new(network: _searchApi);
  BiliCreatorProfileSearchRemoteDataSource creatorProfileSearchDataSource() =>
      .new(network: _searchApi);
  BiliLiveRoomSearchRemoteDataSource liveRoomSearchDataSource() =>
      .new(network: _searchApi);
  BiliVideoSearchRemoteDataSource videoSearchDataSource() =>
      .new(network: _searchApi);
  BiliSearchSuggestRemoteDataSource searchSuggestDataSource() =>
      .new(network: _searchApi);
}
