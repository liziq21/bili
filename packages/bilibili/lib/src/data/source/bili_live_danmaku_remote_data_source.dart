import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import 'bili_remote_data_source.dart';

/// B站直播弹幕数据源。
///
/// 通过 getDanmuInfo 获取弹幕服务器地址与鉴权 token，连接 WebSocket
/// 订阅实时弹幕，映射为 [DanmakuComment]。
final class BiliLiveDanmakuRemoteDataSource({
  required final NetworkLiveDataSource network,
}) extends LiveDanmakuRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// 匿名访问的固定 buvid3（无登录态）。
  static const String _buvid =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  @override
  Stream<DanmakuComment> liveDanmaku(int roomId) async* {
    try {
      final info = await network.getDanmuInfo(roomId: roomId);
      final client = LiveDanmakuWsClient(
        host: info.host,
        wssPort: info.wssPort,
        roomId: roomId,
        token: info.token,
        buvid: _buvid,
      );
      await for (final message in client.messages) {
        final sanitized = message.content.replaceAll(_controlChars, '').trim();
        if (sanitized.isEmpty) continue;
        yield DanmakuComment(
          startTime: Duration.zero,
          mode: modeOf(message.mode),
          fontSize: message.fontSize.toDouble(),
          colorArgb: 0xFF000000 | message.colorArgb,
          content: sanitized,
          rowId: message.rowId,
        );
      }
    } on Object {
      // Stream ends on error.
    }
  }

  static DanmakuMode modeOf(int mode) {
    return switch (mode) {
      4 => DanmakuMode.bottom,
      5 => DanmakuMode.top,
      6 => DanmakuMode.reverse,
      7 || 8 => DanmakuMode.special,
      _ => DanmakuMode.scrolling,
    };
  }
}
