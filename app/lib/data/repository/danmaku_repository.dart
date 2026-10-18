import 'package:data/data.dart';
import 'package:model/model.dart';

/// Application boundary for the optional danmaku capability.
abstract interface class DanmakuRepository() {
  Future<Result<List<DanmakuComment>>> getDanmaku(String videoId);
}

final class AppDanmakuRepository([
  final DanmakuRemoteDataSource? _remoteDataSource,
]) implements DanmakuRepository {
  @override
  Future<Result<List<DanmakuComment>>> getDanmaku(String videoId) {
    final remote = _remoteDataSource;
    if (remote == null) {
      return Future.value(
        Result.error(Exception('Current source does not support danmaku')),
      );
    }
    return remote.getDanmaku(videoId);
  }
}
