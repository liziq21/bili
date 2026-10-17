import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// A single item from Bilibili's public danmaku XML response.
@immutable
final class NetworkBiliDanmaku {
  const NetworkBiliDanmaku({
    required this.startSeconds,
    required this.mode,
    required this.fontSize,
    required this.color,
    required this.sentAt,
    required this.pool,
    required this.userHash,
    required this.rowId,
    required this.content,
  });

  /// Seconds from the beginning of the media at which this comment appears.
  final double startSeconds;

  /// Bilibili's renderer mode value from the `p` attribute.
  final int mode;

  /// Font size in source pixels from the `p` attribute.
  final double fontSize;

  /// ARGB color encoded as a decimal integer by Bilibili.
  final int color;

  /// Server timestamp from the `p` attribute, in seconds since epoch.
  final int sentAt;

  /// Bilibili's comment pool identifier.
  final int pool;

  /// An anonymized sender hash. It is not an account credential.
  final String userHash;

  /// Bilibili's stable row identifier.
  final int rowId;

  /// The visible comment text.
  final String content;

  factory NetworkBiliDanmaku.fromElement(XmlElement element) {
    final parameters = element.getAttribute('p')?.split(',');
    if (parameters == null || parameters.length < 8) {
      throw const FormatException('Danmaku item has an incomplete p attribute');
    }

    final startSeconds = double.tryParse(parameters[0]);
    final mode = int.tryParse(parameters[1]);
    final fontSize = double.tryParse(parameters[2]);
    final color = int.tryParse(parameters[3]);
    final sentAt = int.tryParse(parameters[4]);
    final pool = int.tryParse(parameters[5]);
    final rowId = int.tryParse(parameters[7]);
    if (startSeconds == null ||
        !startSeconds.isFinite ||
        startSeconds < 0 ||
        mode == null ||
        fontSize == null ||
        !fontSize.isFinite ||
        fontSize <= 0 ||
        color == null ||
        sentAt == null ||
        pool == null ||
        rowId == null) {
      throw const FormatException('Danmaku item has invalid p attributes');
    }

    return NetworkBiliDanmaku(
      startSeconds: startSeconds,
      mode: mode,
      fontSize: fontSize,
      color: color,
      sentAt: sentAt,
      pool: pool,
      userHash: parameters[6],
      rowId: rowId,
      content: element.innerText,
    );
  }
}

/// The metadata and comments returned by `comment.bilibili.com/{cid}.xml`.
@immutable
final class NetworkBiliDanmakuDocument {
  const NetworkBiliDanmakuDocument({
    required this.chatServer,
    required this.chatId,
    required this.mission,
    required this.maxLimit,
    required this.state,
    required this.realName,
    required this.comments,
  });

  final String? chatServer;
  final int? chatId;
  final int? mission;
  final int? maxLimit;
  final int? state;
  final int? realName;
  final List<NetworkBiliDanmaku> comments;

  factory NetworkBiliDanmakuDocument.fromXml(String source) {
    final document = XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'i') {
      throw const FormatException('Danmaku XML root must be <i>');
    }

    final comments = <NetworkBiliDanmaku>[];
    for (final element in root.findElements('d')) {
      try {
        comments.add(NetworkBiliDanmaku.fromElement(element));
      } on FormatException {
        // A single malformed comment must not discard the complete response.
      }
    }

    return NetworkBiliDanmakuDocument(
      chatServer: _textOf(root, 'chatserver'),
      chatId: _intOf(root, 'chatid'),
      mission: _intOf(root, 'mission'),
      maxLimit: _intOf(root, 'maxlimit'),
      state: _intOf(root, 'state'),
      realName: _intOf(root, 'real_name'),
      comments: List.unmodifiable(comments),
    );
  }

  static String? _textOf(XmlElement root, String name) {
    final element = root.getElement(name);
    final value = element?.innerText.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static int? _intOf(XmlElement root, String name) {
    final value = _textOf(root, name);
    return value == null ? null : int.tryParse(value);
  }
}
