import 'package:meta/meta.dart';

/// The placement requested by a danmaku item.
enum DanmakuMode() {
  scrolling,
  top,
  bottom,
  reverse,
  special,
}

/// A source-neutral timed comment.
@immutable
final class const DanmakuComment({
  required final Duration startTime,
  required final DanmakuMode mode,
  required final double fontSize,
  required final int colorArgb,
  required final String content,
  final int? rowId,
});
