import 'package:data/data.dart';

/// 把一条 [MediaStream] 转成 mpv 的 EDL 虚拟媒体地址。
///
/// 播放层拿到 [MediaStream] 后不能直接喂给播放器：音视频分离（DASH）
/// 形态下画面与声音是两个独立地址，mpv 单次打开无法处理。本类把两种形态
/// 收敛成一个 `edl://` 地址，让 mpv 在内部完成解复用。
///
/// EDL 格式见 mpv 官方文档 `DOCS/edl-mpv.rst`。
final class MediaEdl() {
  /// EDL 各项之间的分隔符。
  ///
  /// 规范说「用 `;` 代替换行更方便」，本类必须用它：播放器库打开媒体时
  /// 会把地址逐条写进临时播放列表文件交给 mpv 的 `loadlist`，而每条
  /// 地址后追加一个换行。地址内含换行会被播放列表按行切开——实测
  /// `EDL parsing failed`，且 `!new_stream` 被当成文件名去找。
  static const String _separator = ';';

  /// 该指令开启一条并行轨。指令之后的部分与之前的同时播放，而非接在
  /// 其后——这正是音视频分离需要的语义。
  static const String _newStream = '!new_stream';

  /// 地址中的控制字符。
  ///
  /// 长度前缀转义挡不住这些字符：播放器库把地址按行写进播放列表，切分
  /// 发生在 mpv 读到 EDL 之前，故换行会先把地址劈成两行。实测含原始换行
  /// 的地址转义后仍带换行（`%N%` 只约束 mpv 怎么读，不约束列表怎么切）。
  /// 控制字符本就不该出现在地址里，直接剔除。
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// 构造可交给播放器的地址。
  ///
  /// 三种输入形态对应三种输出：
  /// - 音视频分离（[MediaStream.hasSeparateAudio]）：画面轨后跟
  ///   `!new_stream` 与声音轨，mpv 两条轨同时播放。
  /// - 分段（[MediaStream.isSegmented]）：各片段按 [MediaStream.segments]
  ///   的顺序排列，播完一段接下一段。
  /// - 单文件：直接播放 [MediaStream.videoUrl]。
  ///
  /// 输出是单行的：EDL 首行 `# mpv EDL v0` 必须独占一行，而换行无法
  /// 穿过播放列表，故整体省略该行——规范中它是可选的注释行。
  static String uriOf(MediaStream stream) {
    return 'edl://${_bodyOf(stream)}';
  }

  /// 构造 EDL 正文。
  static String _bodyOf(MediaStream stream) {
    final parts = <String>[];
    final segments = stream.isSegmented
        ? stream.segments.map((segment) => segment.url)
        : [stream.videoUrl];
    parts.addAll(segments.map(_escapeParam));

    final audioUrl = stream.audioUrl;
    if (stream.hasSeparateAudio) {
      parts
        ..add(_newStream)
        ..add(_escapeParam(audioUrl!));
    }
    return parts.join(_separator);
  }

  /// 剔除控制字符后，按 EDL 的 `%字节数%内容` 语法转义单个参数值。
  ///
  /// 参数值里不能裸含 `,;!%`（语法把它们当结构符号，见 `edl-mpv.rst` 的
  /// param 规则）。本服务的 CDN 地址普遍带 `uparams=e,oi,platform,...` 这类
  /// 查询串，含逗号是常态而非特例，不转义会直接 `EDL parsing failed`。
  ///
  /// 按字节数而非字符数计算：语法定义的是字节。剔除控制字符在前，转义在
  /// 后——长度前缀必须按剔除后的内容算。
  static String _escapeParam(String value) {
    final clean = value.replaceAll(_controlChars, '');
    if (!_needsEscaping(clean)) return clean;
    final bytes = _utf8Length(clean);
    return '%$bytes%$clean';
  }

  static bool _needsEscaping(String value) {
    for (final rune in value.runes) {
      if (rune == 0x2C || // ,
          rune == 0x3B || // ;
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
