import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliVideoSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends VideoSearchRemoteDataSource with BiliRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [];
  @override
  List<SortOption> get sortOptions => const [];
  @override
  Future<Result<Page<VideoModel>>> searchVideo(String query, {int? pageKey}) {
    return _network
        .searchVideo(query, page: pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }
}
