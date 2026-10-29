import 'dart:convert';

/// 直播弹幕消息（op=5 包体 JSON）解析出的原始字段。
class DanmakuMessage {
  const DanmakuMessage({
    required this.mode,
    required this.fontSize,
    required this.colorArgb,
    required this.content,
    required this.rowId,
  });

  /// 弹幕模式（1=滚动 4=底部 5=顶部 6=逆向 7/8=特殊）。
  final int mode;
  final int fontSize;
  final int colorArgb;
  final String content;
  final int rowId;

  /// 从 op=5 包体（JSON 字节）解析弹幕消息；畸形输入返回 null。
  ///
  /// JSON 结构（DANMU_MSG）：
  /// info[0] = [time, mode, fontsize, color, sent_at, pool, userhash, rowid]
  /// info[1] = content
  static DanmakuMessage? parse(List<int> body) {
    try {
      final json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
      final info = json['info'];
      if (info is! List || info.length < 2) return null;
      final params = info[0];
      if (params is! List || params.length < 8) return null;
      final content = info[1];
      if (content is! String) return null;
      return DanmakuMessage(
        mode: params[1] as int,
        fontSize: params[2] as int,
        colorArgb: params[3] as int,
        content: content,
        rowId: params[7] as int,
      );
    } on Object {
      return null;
    }
  }
}
