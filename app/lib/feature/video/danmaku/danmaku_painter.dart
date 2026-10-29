import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

import 'danmaku_settings.dart';

/// 弹幕浮层颜色配置（从主题角色取值，不构造任意颜色）。
typedef DanmakuColors = ({
  Color onScrim,
  Color accentText,
  Color secondary,
  Color tertiary,
  Color outline,
});

/// 共享弹幕画家：视频弹幕浮层与直播弹幕浮层复用。
///
/// [position] 是当前时间轴位置（Duration），[comments] 中的每条弹幕
/// 以 [DanmakuComment.startTime] 标记其出现时刻。可见性窗口由
/// [DanmakuSettings] 的时长参数控制。
final class DanmakuPainter({
  required final List<DanmakuComment> comments,
  required final Duration position,
  required final DanmakuSettings settings,
  required final DanmakuColors colors,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final currentSeconds =
        position.inMicroseconds / Duration.microsecondsPerSecond;
    final lineHeight = settings.fontSize * 1.5;
    final normalRows = math.max(
      1,
      math.min(8, (size.height / lineHeight).floor()),
    );
    final visible = comments.where((comment) {
      final duration = _durationOf(comment);
      final elapsed =
          currentSeconds -
          comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;
      return elapsed >= 0 && elapsed <= duration;
    });

    for (final comment in visible) {
      _paintComment(
        canvas,
        size,
        comment,
        lineHeight,
        normalRows,
        currentSeconds,
      );
    }
  }

  void _paintComment(
    Canvas canvas,
    Size size,
    DanmakuComment comment,
    double lineHeight,
    int normalRows,
    double currentSeconds,
  ) {
    final fontSize = (settings.fontSize * (comment.fontSize / 25)).clamp(
      settings.fontSize * .75,
      settings.fontSize * 1.4,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: comment.content,
        style: TextStyle(
          color: _colorFor(comment).withValues(alpha: settings.opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: colors.outline.withValues(alpha: settings.opacity),
              blurRadius: settings.outlineRadius,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width * 1.5);

    final elapsed =
        currentSeconds -
        comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;
    final duration = _durationOf(comment);
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final rowId = comment.rowId ?? comment.content.hashCode;
    final row = rowId.abs();
    final Offset offset;
    switch (comment.mode) {
      case DanmakuMode.top:
        final topRows = math.max(1, settings.topMaxRows);
        offset = Offset(
          (size.width - painter.width) / 2,
          (row % topRows) * lineHeight,
        );
      case DanmakuMode.bottom:
        final bottomRows = math.max(1, settings.bottomMaxRows);
        offset = Offset(
          (size.width - painter.width) / 2,
          size.height - (row % bottomRows + 1) * lineHeight,
        );
      case DanmakuMode.reverse:
        offset = Offset(
          progress * (size.width + painter.width) - painter.width,
          (row % normalRows) * lineHeight,
        );
      case DanmakuMode.scrolling || DanmakuMode.special:
        offset = Offset(
          size.width - progress * (size.width + painter.width),
          (row % normalRows) * lineHeight,
        );
    }

    painter.paint(canvas, offset);
  }

  double _durationOf(DanmakuComment comment) {
    return switch (comment.mode) {
      DanmakuMode.top || DanmakuMode.bottom => settings.topBottomDuration,
      _ => settings.regularDuration,
    };
  }

  Color _colorFor(DanmakuComment comment) {
    // Content colors are quantized to the active theme roles rather than
    // constructing arbitrary colors in app/lib. This keeps the overlay
    // readable with DynamicColor while retaining light/dark and warm/cool
    // intent from the source XML.
    final rgb = comment.colorArgb & 0x00FFFFFF;
    final red = (rgb >> 16) & 0xFF;
    final green = (rgb >> 8) & 0xFF;
    final blue = rgb & 0xFF;
    final luminance = (red * .2126 + green * .7152 + blue * .0722) / 255;
    if (luminance >= .78) return colors.onScrim;
    if (red >= green && red >= blue) return colors.tertiary;
    if (green >= blue) return colors.secondary;
    return colors.accentText;
  }

  @override
  bool shouldRepaint(DanmakuPainter oldDelegate) => true;
}
