import 'dart:ui' as ui;

import 'package:app/feature/video/danmaku/danmaku_painter.dart';
import 'package:app/feature/video/danmaku/danmaku_settings.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _size = Size(800, 600);
const _lineHeight = 27.0;

const _colors = (onScrim: Color(0xFFFFFFFF), outline: Color(0xFF000000));

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

/// Counts pixels with a non-zero alpha so a painter that silently draws nothing
/// fails instead of merely returning without throwing.
Future<int> _paintedPixelCount(
  List<DanmakuComment> comments, {
  Duration position = const Duration(seconds: 1),
  Size size = _size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  DanmakuPainter(
    comments: comments,
    position: position,
    settings: const DanmakuSettings(),
    colors: _colors,
  ).paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  if (data == null) return 0;
  final bytes = data.buffer.asUint8List();
  var count = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] != 0) count++;
  }
  return count;
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
        lane: 0,
        lineHeight: _lineHeight,
        progress: 0,
      );
      final leave = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        lane: 0,
        lineHeight: _lineHeight,
        progress: 1,
      );

      // Then it starts just off the right edge and ends just off the left.
      expect(enter.dx, _size.width);
      expect(leave.dx, -textWidth);
      expect(enter.dy, 0);
    });

    test('every mode moves along the scrolling path', () {
      // Given a comment on the second lane.
      const textWidth = 200.0;

      // When computing its offset at two different moments.
      final first = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        lane: 2,
        lineHeight: _lineHeight,
        progress: .2,
      );
      final later = danmakuTextOffset(
        size: _size,
        textWidth: textWidth,
        lane: 2,
        lineHeight: _lineHeight,
        progress: .8,
      );

      // Then it moves left and keeps its lane.
      expect(later.dx, lessThan(first.dx));
      expect(first.dy, 2 * _lineHeight);
      expect(later.dy, first.dy);
    });
  });

  group('DanmakuPainter.paint', () {
    test('paints every source mode as a scrolling comment', () {
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

    test('draws visible pixels for an on-screen comment', () async {
      // Given a comment that should be visible one second in.
      // When rasterising the frame.
      final painted = await _paintedPixelCount([
        _comment(DanmakuMode.scrolling),
      ]);

      // Then the painter actually wrote pixels, not just returned.
      expect(painted, greaterThan(0));
    });

    test('leaves the canvas blank when there are no comments', () async {
      // Given an empty comment list.
      // When rasterising the frame.
      final painted = await _paintedPixelCount(const []);

      // Then nothing is drawn, so the positive case above is meaningful.
      expect(painted, 0);
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
