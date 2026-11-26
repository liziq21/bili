import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/live_room.dart';
import 'bili_remote_data_source.dart';
import 'bili_result.dart';

/// 直播推荐 Feed。
///
/// 走 `/room/v1/room/get_user_recommend`：它按推荐返回正在开播的房间，不是
/// 对关键词「直播」的搜索。搜索端点与搜索页共用风控额度，一被限流首页直播
/// tab 就直接失败，而且「直播」这个关键词本身也不是推荐语义（#672）。
final class const BiliRecommendLiveRoomFeedRemoteDataSource({
  required final NetworkLiveDataSource _network,
}) extends LiveRoomFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'live';

  @override
  String get title => '直播';

  @override
  Future<Result<Page<LiveRoomModel>, Exception>> fetchFeed({int? pageKey}) {
    final page = pageKey ?? 1;
    // 推荐端点没有翻页参数，一次就返回一屏推荐；再翻只会重复同一批房间。
    if (page > 1) {
      return Future.value(
        Result.success(
          Page<LiveRoomModel>(number: page, totalPages: page, data: const []),
        ),
      );
    }
    return _network
        .getRecommendedLiveRooms()
        .then(
          (it) => Page<LiveRoomModel>(
            number: 1,
            totalPages: 1,
            data: [for (final room in it.rooms) room.asModel()],
          ),
        )
        .toBiliResult();
  }
}
