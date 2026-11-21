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

/// 同一轨道上两条弹幕之间的空档（秒），避免文字首尾相接看不出分界。
const double _laneGap = .25;

/// 一条待绘制的弹幕及其轨道号。
typedef DanmakuSlot = ({DanmakuComment comment, int lane});

/// 给当前时间点仍在画面上的弹幕分配轨道，按开始时间升序返回。
///
/// 分配规则：同一轨道的后一条必须等前一条让出画面才能进入，否则同一行会
/// 叠字。分配只依赖比它更早的弹幕，因此播放推进时已上屏的弹幕不会换行；
/// 所有轨道都被占满时该条直接丢弃——少一条弹幕比叠字好读。
///
/// 纯函数：只读输入，不碰 canvas，便于单测「同轨道不重叠」这条规则。
List<DanmakuSlot> planDanmakuSlots({
  required Iterable<DanmakuComment> comments,
  required double positionSeconds,
  required Size size,
  required DanmakuSettings settings,
}) {
  if (size.isEmpty) return const [];

  final lineHeight = settings.fontSize * 1.5;
  final scrollingRows = math.max(
    1,
    math.min(8, (size.height / lineHeight).floor()),
  );
  final longestDuration = math.max(
    settings.regularDuration,
    settings.topBottomDuration,
  );

  // 只规划「已经开始」的弹幕。窗口比最长停留时长再多一个空档：更早的
  // 弹幕此刻早已让出轨道，把它们排除在外不会影响窗口内的分配结果。
  final windowStart = positionSeconds - longestDuration - _laneGap;
  final started = comments.where((comment) {
    final start = _startSeconds(comment);
    return start >= windowStart && start <= positionSeconds;
  }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  // 顶/底弹幕与滚动弹幕共用同一片画面：顶部弹幕停在原地，滚动弹幕会经过
  // 这些行，所以顶部弹幕必须和滚动弹幕抢同一组轨道，否则两行字会叠在一起。
  // 底部弹幕贴底排列，单独一组。
  final scrollingFreeAt = List<double>.filled(
    scrollingRows,
    double.negativeInfinity,
  );
  final bottomFreeAt = List<double>.filled(
    math.max(1, settings.bottomMaxRows),
    double.negativeInfinity,
  );
  final topLaneCount = math.min(
    scrollingRows,
    math.max(1, settings.topMaxRows),
  );

  final slots = <DanmakuSlot>[];
  for (final comment in started) {
    final start = _startSeconds(comment);
    final duration = _durationOf(comment, settings);
    final (lanes, laneCount) = switch (comment.mode) {
      DanmakuMode.top => (scrollingFreeAt, topLaneCount),
      DanmakuMode.bottom => (bottomFreeAt, bottomFreeAt.length),
      _ => (scrollingFreeAt, scrollingFreeAt.length),
    };
    final lane = _claimLane(lanes, laneCount, comment, start);
    if (lane == null) continue;

    final width = _estimatedWidth(
      comment.content,
      _fontSizeOf(comment, settings),
    );
    lanes[lane] = switch (comment.mode) {
      // 顶/底弹幕停在原地，占满整段停留时长才让出轨道。
      DanmakuMode.top || DanmakuMode.bottom => start + duration + _laneGap,
      // 滚动弹幕的尾巴越过右边缘后轨道就可以给下一条。
      _ => start + duration * width / (size.width + width) + _laneGap,
    };

    if (positionSeconds - start > duration) continue;
    slots.add((comment: comment, lane: lane));
  }
  return slots;
}

double _startSeconds(DanmakuComment comment) =>
    comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;

double _fontSizeOf(DanmakuComment comment, DanmakuSettings settings) =>
    (settings.fontSize * (comment.fontSize / 25)).clamp(
      settings.fontSize * .75,
      settings.fontSize * 1.4,
    );

double _durationOf(DanmakuComment comment, DanmakuSettings settings) =>
    switch (comment.mode) {
      DanmakuMode.top || DanmakuMode.bottom => settings.topBottomDuration,
      _ => settings.regularDuration,
    };

/// 估算单行文字宽度：按最宽的中日韩全角字（1em/字）算。
///
/// 拉丁字母与数字实际更窄，估算只会偏大；偏大意味着轨道留得更松，不会让
/// 两条弹幕撞在一起。这里刻意不做 TextPainter 排版——已经滚出画面但仍占着
/// 轨道的弹幕也要参与估算。
double _estimatedWidth(String content, double fontSize) =>
    content.characters.length * fontSize;

/// 选一条可用轨道：先用弹幕自身指定的轨道，被占用时顺延。
///
/// 返回 null 表示所有轨道都还没空出来。
int? _claimLane(
  List<double> freeAt,
  int laneCount,
  DanmakuComment comment,
  double start,
) {
  final preferred =
      (comment.rowId ?? comment.content.hashCode).abs() % laneCount;
  for (var offset = 0; offset < laneCount; offset++) {
    final lane = (preferred + offset) % laneCount;
    if (freeAt[lane] <= start) return lane;
  }
  return null;
}

/// 共享弹幕画家：视频弹幕浮层与直播弹幕浮层复用。
///
/// [position] 是当前时间轴位置（Duration），[comments] 中的每条弹幕
/// 以 [DanmakuComment.startTime] 标记其出现时刻。可见性窗口与轨道分配
/// 见 [planDanmakuSlots]。
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
    final slots = planDanmakuSlots(
      comments: comments,
      positionSeconds: currentSeconds,
      size: size,
      settings: settings,
    );
    for (final slot in slots) {
      _paintComment(
        canvas,
        size,
        slot.comment,
        lineHeight,
        slot.lane,
        _fontSizeOf(slot.comment, settings),
        currentSeconds,
      );
    }
  }

  void _paintComment(
    Canvas canvas,
    Size size,
    DanmakuComment comment,
    double lineHeight,
    int lane,
    double fontSize,
    double currentSeconds,
  ) {
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
    final duration = _durationOf(comment, settings);
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final Offset offset;
    switch (comment.mode) {
      case DanmakuMode.top:
        offset = Offset((size.width - painter.width) / 2, lane * lineHeight);
      case DanmakuMode.bottom:
        offset = Offset(
          (size.width - painter.width) / 2,
          size.height - (lane + 1) * lineHeight,
        );
      case DanmakuMode.reverse:
        offset = Offset(
          progress * (size.width + painter.width) - painter.width,
          lane * lineHeight,
        );
      case DanmakuMode.scrolling || DanmakuMode.special:
        offset = Offset(
          size.width - progress * (size.width + painter.width),
          lane * lineHeight,
        );
    }

    painter.paint(canvas, offset);
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
