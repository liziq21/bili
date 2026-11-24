import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

import 'danmaku_settings.dart';

/// 弹幕浮层颜色配置（从主题角色取值，不构造任意颜色）。
typedef DanmakuColors = ({Color onScrim, Color outline});

/// 同一轨道上两条弹幕之间的空档（秒），避免文字首尾相接看不出分界。
const double _laneGap = .25;

/// 画面最多容纳的滚动轨道数，避免一屏塞入过多弹幕。
const int _maxLanes = 8;

/// 一条待绘制的弹幕及其轨道号。
typedef DanmakuSlot = ({DanmakuComment comment, int lane});

/// 给当前时间点仍在画面上的弹幕分配轨道，按开始时间升序返回。
///
/// 所有弹幕一律按滚动处理：来源里的顶/底/逆向标记只保留在数据层，不再影响
/// 排版。同一轨道的后一条必须等前一条让出画面才能进入，否则同一行会叠字。
/// 所有轨道都被占满时该条直接丢弃——少一条弹幕比叠字好读。
///
/// 轨道分配必须从第一条已开始的弹幕算起，不能只算当前可见窗口。一条弹幕的
/// 轨道取决于它开始时刻更早的弹幕是否还占着轨道；把已经滚出画面的前序弹幕
/// 从输入里剔掉，会让还在画面上的弹幕在下一帧换到别的轨道，看起来就是突然
/// 跳行。
///
/// 纯函数：只读输入，不碰 canvas，便于单测「同轨道不重叠」与「轨道不跳变」。
List<DanmakuSlot> planDanmakuSlots({
  required Iterable<DanmakuComment> comments,
  required double positionSeconds,
  required Size size,
  required DanmakuSettings settings,
}) {
  if (size.isEmpty) return const [];

  final lineHeight = settings.fontSize * 1.5;
  final laneCount = math.max(
    1,
    math.min(_maxLanes, (size.height / lineHeight).floor()),
  );

  final started = comments
      .where((comment) => _startSeconds(comment) <= positionSeconds)
      .toList();
  if (!_isSortedByStart(started)) {
    started.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  final freeAt = List<double>.filled(laneCount, double.negativeInfinity);
  final slots = <DanmakuSlot>[];
  for (final comment in started) {
    final start = _startSeconds(comment);
    final lane = _claimLane(freeAt, laneCount, comment, start);
    if (lane == null) continue;

    final width = _estimatedWidth(
      comment.content,
      _fontSizeOf(comment, settings),
    );
    // 滚动弹幕的尾巴越过右边缘后轨道就可以给下一条。
    freeAt[lane] =
        start +
        settings.regularDuration * width / (size.width + width) +
        _laneGap;

    if (positionSeconds - start > settings.regularDuration) continue;
    slots.add((comment: comment, lane: lane));
  }
  return slots;
}

bool _isSortedByStart(List<DanmakuComment> comments) {
  for (var i = 1; i < comments.length; i++) {
    if (comments[i].startTime.compareTo(comments[i - 1].startTime) < 0) {
      return false;
    }
  }
  return true;
}

double _startSeconds(DanmakuComment comment) =>
    comment.startTime.inMicroseconds / Duration.microsecondsPerSecond;

double _fontSizeOf(DanmakuComment comment, DanmakuSettings settings) =>
    (settings.fontSize * (comment.fontSize / 25)).clamp(
      settings.fontSize * .75,
      settings.fontSize * 1.4,
    );

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

/// 单条弹幕在画面上的落点。
///
/// 所有弹幕都从右向左穿过画面；`progress` 为 0 时在右边缘外，1 时在左边缘外。
@visibleForTesting
Offset danmakuTextOffset({
  required Size size,
  required double textWidth,
  required int lane,
  required double lineHeight,
  required double progress,
}) =>
    Offset(size.width - progress * (size.width + textWidth), lane * lineHeight);

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
          color: colors.onScrim.withValues(alpha: settings.opacity),
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

    final elapsed = currentSeconds - _startSeconds(comment);
    final progress = (elapsed / settings.regularDuration).clamp(0.0, 1.0);
    final offset = danmakuTextOffset(
      size: size,
      textWidth: painter.width,
      lane: lane,
      lineHeight: lineHeight,
      progress: progress,
    );

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(DanmakuPainter oldDelegate) => true;
}
