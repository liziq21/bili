import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/search_results.dart';
import 'bili_remote_data_source.dart';

final class const BiliRecommendLiveRoomFeedRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends LiveRoomFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'live';

  @override
  String get title => '正在直播';

  @override
  Future<Result<Page<LiveRoomModel>>> fetchFeed({int? pageKey}) {
    return _network
        .searchLiveRoom('直播', page: pageKey)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }
}
