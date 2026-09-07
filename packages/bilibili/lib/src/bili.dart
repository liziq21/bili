import 'package:bpi/bpi.dart';
import 'package:http/http.dart';

import 'data/source/bilibili_search_remote_data_source.dart';

// App-layer repository types are imported via the app's own modules.
// This file intentionally does not import app repository classes to keep
// the bilibili package free of app-layer dependencies.
class Bili {
  static Client? client;
  BiliNetworkSearch? _networkSearch;
  NetworkSearchDataSource get _bpi {
    _networkSearch ??= BiliNetworkSearch(client: client);
    return _networkSearch!;
  }

  Future<void> close() async => _networkSearch?.close();

  BilibiliSearchRemoteDataSource searchRemoteDataSource() =>
      BilibiliSearchRemoteDataSource(network: _bpi);
}
