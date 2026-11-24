import 'package:app/feature/video/danmaku/danmaku_painter.dart';
import 'package:app/feature/video/danmaku/danmaku_settings.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(800, 600);

DanmakuComment scrolling(
  double start, {
  String content = 'hello world',
  int? rowId,
  DanmakuMode mode = DanmakuMode.scrolling,
}) => DanmakuComment(
  startTime: Duration(milliseconds: (start * 1000).round()),
  mode: mode,
  fontSize: 25,
  colorArgb: 0xFFFFFF,
  content: content,
  rowId: rowId,
);

List<DanmakuSlot> plan(
  List<DanmakuComment> comments,
  double positionSeconds, {
  DanmakuSettings settings = const DanmakuSettings(),
}) => planDanmakuSlots(
  comments: comments,
  positionSeconds: positionSeconds,
  size: _size,
  settings: settings,
);

int laneOf(List<DanmakuSlot> slots, String content) =>
    slots.singleWhere((slot) => slot.comment.content == content).lane;

void main() {
  group('planDanmakuSlots', () {
    test('gives simultaneous comments separate lanes', () {
      // Given 三条同一秒开始的弹幕。
      final comments = [
        scrolling(10, content: 'first'),
        scrolling(10, content: 'second'),
        scrolling(10, content: 'third'),
      ];

      // When 规划 10.5 秒这一帧。
      final slots = plan(comments, 10.5);

      // Then 三条都在画面上，且各占一条轨道。
      expect(slots, hasLength(3));
      expect(slots.map((slot) => slot.lane).toSet(), hasLength(3));
    });

    test('reuses a lane only after the previous comment left the screen', () {
      // Given 同一轨道偏好上前后两条弹幕，间隔远小于滚动时长。
      final comments = [
        scrolling(0, content: 'leading', rowId: 0),
        scrolling(0.2, content: 'following', rowId: 0),
      ];

      // When 两条都还在画面上。
      final slots = plan(comments, 0.5);

      // Then 后一条换到另一条轨道，不会叠在前一条上。
      expect(slots, hasLength(2));
      expect(slots.first.lane, isNot(slots.last.lane));
    });

    test('drops comments when every lane is still occupied', () {
      // Given 画面只有 8 条滚动轨道（600 / 27 向下取整）。
      final comments = [
        for (var i = 0; i < 12; i++)
          scrolling(0, content: 'crowded $i', rowId: i),
      ];

      // When 十二个弹幕挤在同一秒。
      final slots = plan(comments, 0.2);

      // Then 只保留能分到轨道的那些，多出来的直接丢弃而不是叠字。
      expect(slots, hasLength(8));
      expect(slots.map((slot) => slot.lane).toSet(), hasLength(8));
    });

    test('ignores comments that have not started yet', () {
      // Given 一条已经开始、一条还没开始。
      final comments = [scrolling(1), scrolling(9)];

      // When 规划 2 秒这一帧。
      final slots = plan(comments, 2);

      // Then 只有已经开始的那条参与绘制。
      expect(slots, hasLength(1));
    });

    test('ignores comments older than the scrolling duration', () {
      // Given 一条早已滚出画面的弹幕。
      final comments = [scrolling(0)];

      // When 规划 30 秒这一帧。
      final slots = plan(comments, 30);

      // Then 不再绘制它。
      expect(slots, isEmpty);
    });

    test('keeps a comment on its lane as the playback advances', () {
      // Given 后一条弹幕的偏好轨道被前一条占着，只能顺延。
      final comments = [
        scrolling(0, content: 'leading', rowId: 0),
        scrolling(0.5, content: 'following', rowId: 0),
      ];

      // When 先看它刚出现时的轨道，再看前一条已经滚出画面后的轨道。
      final early = plan(comments, 1);
      final late = plan(comments, 8.3);

      // Then 后一条仍在同一条轨道上，不会因为前一条被移出规划窗口而跳行。
      expect(laneOf(early, 'following'), isNot(0));
      expect(laneOf(late, 'following'), laneOf(early, 'following'));
    });

    test('renders every source mode as a scrolling comment', () {
      // Given 五种来源模式在同一秒出现。
      final comments = [
        for (final (index, mode) in DanmakuMode.values.indexed)
          scrolling(0, content: 'mode $index', rowId: index, mode: mode),
      ];

      // When 规划 0.5 秒这一帧。
      final slots = plan(comments, 0.5);

      // Then 五种模式都参与滚动排版，没有为顶/底弹幕单独保留轨道。
      expect(slots, hasLength(DanmakuMode.values.length));
      expect(
        slots.map((slot) => slot.lane).toSet(),
        hasLength(DanmakuMode.values.length),
      );
    });
  });
}
