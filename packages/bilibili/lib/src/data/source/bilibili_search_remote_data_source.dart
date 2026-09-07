import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/search_results.dart';

class BilibiliSearchRemoteDataSource implements SearchRemoteDataSource {
  const BilibiliSearchRemoteDataSource({required this._network});

  final NetworkSearchDataSource _network;

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<AggregateSearchPage>> searchAll(String query, {int? pageKey}) {
    return _network
        .searchAll(query, page: pageKey)
        .then((it) => it.asModel())
        .toResult();
  }

  @override
  Future<Result<Page<CreatorProfile>>> searchBiliUser(String query, {int? pageKey}) {
    return _network
        .searchBiliUser(query, page: pageKey)
        .then((it) => it.asPagedCreatorProfile())
        .toResult();
  }

  @override
  Future<Result<Page<LiveRoomModel>>> searchLiveRoom(String query, {int? pageKey}) {
    return _network
        .searchLiveRoom(query, page: pageKey)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }

  @override
  Future<Result<Page<VideoModel>>> searchVideo(String query, {int? pageKey}) {
    return _network
        .searchVideo(query, page: pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    return _network
        .getSuggests(query)
        .then((value) => value.tag.map((e) => e.term).toList())
        .toResult();
  }
}
