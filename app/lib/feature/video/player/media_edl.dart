import 'package:data/data.dart';

/// 把一条 [MediaStream] 转成 mpv 的 EDL 虚拟媒体地址。
///
/// 播放层拿到 [MediaStream] 后不能直接喂给播放器：音视频分离（DASH）
/// 形态下画面与声音是两个独立地址，mpv 单次 `open()` 无法处理。本类把
/// 两种形态收敛成一个 `edl://` 地址，让 mpv 在内部完成解复用。
///
/// EDL 格式见 mpv 官方文档 `DOCS/edl-mpv.rst`（首行 `# mpv EDL v0`）。
final class MediaEdl() {
  /// EDL 首行，mpv 用它识别文件头。
  static const String _header = '# mpv EDL v0';

  /// 该指令开启一条并行轨。指令之后的部分与之前的同时播放，而非接在
  /// 其后——这正是音视频分离需要的语义。
  static const String _newStream = '!new_stream';

  /// 构造可交给 `player.open()` 的地址。
  ///
  /// 三种输入形态对应三种输出：
  /// - 音视频分离（[MediaStream.hasSeparateAudio]）：画面轨后跟
  ///   `!new_stream` 与声音轨，mpv 两条轨同时播放。
  /// - 分段（[MediaStream.isSegmented]）：各片段按 [MediaStream.segments]
  ///   的顺序排列，播完一段接下一段。
  /// - 单文件：直接播放 [MediaStream.videoUrl]。
  static String uriOf(MediaStream stream) {
    final body = _bodyOf(stream);
    return 'edl://$_header\n$body';
  }

  /// 构造 EDL 正文（不含首行）。
  static String _bodyOf(MediaStream stream) {
    final lines = <String>[];
    final segments = stream.isSegmented
        ? stream.segments.map((segment) => segment.url)
        : [stream.videoUrl];
    lines.addAll(segments.map(_escapeParam));

    final audioUrl = stream.audioUrl;
    if (stream.hasSeparateAudio) {
      lines
        ..add(_newStream)
        ..add(_escapeParam(audioUrl!));
    }
    return lines.join('\n');
  }

  /// 按 EDL 的 `%字节数%内容` 语法转义单个参数值。
  ///
  /// 参数值里不能裸含 `,;\n!`（语法把它们当结构符号，见
  /// `edl-mpv.rst` 的 param 规则）。本服务的 CDN 地址普遍带
  /// `uparams=e,oi,platform,trid,...` 这类查询串，含逗号是常态而非
  /// 特例，不转义会直接 `EDL parsing failed`。
  ///
  /// 按字节数而非字符数计算：语法定义的是字节。
  static String _escapeParam(String value) {
    if (!_needsEscaping(value)) return value;
    final bytes = _utf8Length(value);
    return '%$bytes%$value';
  }

  static bool _needsEscaping(String value) {
    for (final rune in value.runes) {
      if (rune == 0x2C || // ,
          rune == 0x3B || // ;
          rune == 0x0A || // \n
          rune == 0x21 || // !
          rune == 0x25) {
        // %
        return true;
      }
    }
    return false;
  }

  static int _utf8Length(String value) {
    var length = 0;
    for (final rune in value.runes) {
      if (rune <= 0x7F) {
        length += 1;
      } else if (rune <= 0x7FF) {
        length += 2;
      } else if (rune <= 0xFFFF) {
        length += 3;
      } else {
        length += 4;
      }
    }
    return length;
  }
}
