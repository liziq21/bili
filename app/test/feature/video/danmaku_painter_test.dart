import 'dart:ui' as ui;

import 'package:app/feature/video/danmaku/danmaku_painter.dart';
import 'package:app/feature/video/danmaku/danmaku_settings.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _size = Size(800, 600);
const _lineHeight = 27.0;

const _colors = (
  onScrim: Color(0xFFFFFFFF),
  accentText: Color(0xFF00A1D6),
  secondary: Color(0xFF00B5E5),
  tertiary: Color(0xFFFF6699),
  outline: Color(0xFF000000),
);

DanmakuComment _comment(
  DanmakuMode mode, {
  double startSeconds = 0,
  String content = 'hello world',
  int? rowId,
}) => DanmakuComment(
  startTime: Duration(milliseconds: (startSeconds * 1000).round()),
  mode: mode,
  fontSize: 25,
  colorArgb: 0xFFFFFF,
  content: content,
  rowId: rowId,
);

/// Paints into a throwaway picture so a layout or paint failure surfaces as a
/// test failure instead of silently rendering nothing.
void _paint(
  List<DanmakuComment> comments, {
  Duration position = const Duration(seconds: 1),
  Size size = _size,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  DanmakuPainter(
    comments: comments,
    position: position,
    settings: const DanmakuSettings(),
    colors: _colors,
  ).paint(canvas, size);
  recorder.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('danmakuTextOffset', () {
    test('scrolling enters at the right edge and leaves on the left', () {
      // Given a scrolling comment of known width.
      const textWidth = 120.0;

      // When computing the offsets at the start and end of its life.
      final enter = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.scrolling,
        lane: 0,
        lineHeight: _lineHeight,
        progress: 0,
      );
      final leave = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.scrolling,
        lane: 0,
        lineHeight: _lineHeight,
        progress: 1,
      );

      // Then it starts just off the right edge and ends just off the left.
      expect(enter.dx, _size.width);
      expect(leave.dx, -textWidth);
      expect(enter.dy, 0);
    });

    test('reverse enters at the left edge and leaves on the right', () {
      // Given a reverse comment of known width.
      const textWidth = 120.0;

      // When computing the offsets at the start and end of its life.
      final enter = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.reverse,
        lane: 0,
        lineHeight: _lineHeight,
        progress: 0,
      );
      final leave = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.reverse,
        lane: 0,
        lineHeight: _lineHeight,
        progress: 1,
      );

      // Then it starts just off the left edge and ends just off the right.
      expect(enter.dx, -textWidth);
      expect(leave.dx, _size.width);
    });

    test('top comments stay centred on their lane', () {
      // Given a top comment on the second lane.
      const textWidth = 200.0;

      // When computing its offset at two different moments.
      final first = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.top,
        lane: 1,
        lineHeight: _lineHeight,
        progress: 0,
      );
      final later = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.top,
        lane: 1,
        lineHeight: _lineHeight,
        progress: .8,
      );

      // Then it does not move and sits horizontally centred.
      expect(first, later);
      expect(first.dx, (_size.width - textWidth) / 2);
      expect(first.dy, _lineHeight);
    });

    test('bottom comments stack upward from the bottom edge', () {
      // Given a bottom comment on the first lane.
      const textWidth = 200.0;

      // When computing its offset.
      final offset = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        mode: DanmakuMode.bottom,
        lane: 0,
        lineHeight: _lineHeight,
        progress: .5,
      );

      // Then it is centred and sits one line above the bottom edge.
      expect(offset.dx, (_size.width - textWidth) / 2);
      expect(offset.dy, _size.height - _lineHeight);
    });

    test('special comments move like scrolling comments', () {
      // Given the same geometry for both modes.
      Offset offsetFor(DanmakuMode mode) => danmakuTextOffset(
        size: _size,
        textWidth: 90,
        mode: mode,
        lane: 2,
        lineHeight: _lineHeight,
        progress: .3,
      );

      // Then special shares the scrolling path.
      expect(offsetFor(DanmakuMode.special), offsetFor(DanmakuMode.scrolling));
    });
  });

  group('DanmakuPainter.paint', () {
    test('paints every placement mode without throwing', () {
      // Given one comment per mode, all on screen at the same moment.
      final comments = [
        _comment(DanmakuMode.scrolling, rowId: 0),
        _comment(DanmakuMode.top, rowId: 1),
        _comment(DanmakuMode.bottom, rowId: 2),
        _comment(DanmakuMode.reverse, rowId: 3),
        _comment(DanmakuMode.special, rowId: 4),
      ];

      // When painting a frame.
      // Then no mode trips layout or paint.
      expect(() => _paint(comments), returnsNormally);
    });

    test('paints an empty canvas when the viewport has no size', () {
      // Given a zero-sized viewport, which happens before first layout.
      // When painting.
      // Then it returns early instead of dividing by zero.
      expect(
        () => _paint([_comment(DanmakuMode.scrolling)], size: Size.zero),
        returnsNormally,
      );
    });

    test('paints a dense frame of over one thousand comments', () {
      // Given 1200 comments crowding the same second, more than the eight
      // lanes can hold at once.
      final comments = [
        for (var i = 0; i < 1200; i++)
          _comment(DanmakuMode.scrolling, content: 'dense $i', rowId: i),
      ];

      // When planning and painting that frame.
      final slots = planDanmakuSlots(
        comments: comments,
        positionSeconds: .5,
        size: _size,
        settings: const DanmakuSettings(),
      );

      // Then only the lanes that fit are drawn, and painting them is safe.
      expect(slots.length, lessThanOrEqualTo(8));
      expect(() => _paint(comments), returnsNormally);
    });

    test('always reports that it should repaint', () {
      // Given two painters with different positions.
      final first = DanmakuPainter(
        comments: [_comment(DanmakuMode.scrolling)],
        position: Duration.zero,
        settings: const DanmakuSettings(),
        colors: _colors,
      );
      final second = DanmakuPainter(
        comments: first.comments,
        position: const Duration(seconds: 1),
        settings: first.settings,
        colors: _colors,
      );

      // Then the overlay keeps animating between frames.
      expect(second.shouldRepaint(first), isTrue);
    });
  });
}
