import 'package:data/data.dart';
import 'package:model/model.dart';

/// 直播间详情与直播流地址的应用层仓库。
///
/// 直接透传中立能力接口的 [Result]，不做额外包装——
/// 错误语义已在 bpi 适配层收敛，这里没有新信息可加。
class const AppLiveRoomRepository(
  final LiveRoomDetailRemoteDataSource _remoteDataSource,
) {
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(int roomId) =>
      _remoteDataSource.getLiveRoomDetail(roomId);

  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) =>
      _remoteDataSource.getLiveRoomStream(roomId);
}
