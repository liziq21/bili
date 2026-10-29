import 'package:data/data.dart';
import 'package:model/model.dart';

/// Application boundary for the optional danmaku capability.
abstract interface class DanmakuRepository {
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(String videoId);

  /// 订阅指定直播间的实时弹幕流。
  ///
  /// 取消订阅即断开 WebSocket 连接。
  Stream<DanmakuComment> liveDanmaku(int roomId);
}

final class AppDanmakuRepository([
  final DanmakuRemoteDataSource? _remoteDataSource,
  final LiveDanmakuRemoteDataSource? _liveDanmakuDataSource,
]) implements DanmakuRepository {
  @override
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(String videoId) {
    final remote = _remoteDataSource;
    if (remote == null) {
      return Future.value(
        Result.error(Exception('Current source does not support danmaku')),
      );
    }
    return remote.getDanmaku(videoId);
  }

  @override
  Stream<DanmakuComment> liveDanmaku(int roomId) {
    final live = _liveDanmakuDataSource;
    if (live == null) {
      return const Stream.empty();
    }
    return live.liveDanmaku(roomId);
  }
}
