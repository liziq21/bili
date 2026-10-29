import 'dart:convert';

import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  group('DanmakuMessage', () {
    test('parse scrolling danmaku message', () {
      final json = jsonEncode({
        'cmd': 'DANMU_MSG',
        'info': [
          [0, 1, 25, 16777215, 1735877407, 0, 'hash', 12345],
          'hello world',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message, isNotNull);
      expect(message!.mode, 1);
      expect(message.fontSize, 25);
      expect(message.colorArgb, 16777215);
      expect(message.content, 'hello world');
      expect(message.rowId, 12345);
    });

    test('parse top-mode danmaku (mode 5)', () {
      final json = jsonEncode({
        'info': [
          [0, 5, 25, 0xFF0000, 0, 0, 'h', 1],
          'top danmaku',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.mode, 5);
    });

    test('parse bottom-mode danmaku (mode 4)', () {
      final json = jsonEncode({
        'info': [
          [0, 4, 25, 0x00FF00, 0, 0, 'h', 2],
          'bottom danmaku',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.mode, 4);
    });

    test('parse reverse-mode danmaku (mode 6)', () {
      final json = jsonEncode({
        'info': [
          [0, 6, 25, 0x0000FF, 0, 0, 'h', 3],
          'reverse danmaku',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.mode, 6);
    });

    test('parse special-mode danmaku (mode 7)', () {
      final json = jsonEncode({
        'info': [
          [0, 7, 25, 0xFFFFFF, 0, 0, 'h', 4],
          'special danmaku',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.mode, 7);
    });

    test('parse special-mode danmaku (mode 8)', () {
      final json = jsonEncode({
        'info': [
          [0, 8, 25, 0xFFFFFF, 0, 0, 'h', 5],
          'special danmaku 2',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.mode, 8);
    });

    test('parse malformed JSON returns null', () {
      final message = DanmakuMessage.parse(utf8.encode('not json'));
      expect(message, isNull);
    });

    test('parse missing info returns null', () {
      final json = jsonEncode({'cmd': 'OTHER'});
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message, isNull);
    });

    test('parse info with too few params returns null', () {
      final json = jsonEncode({
        'info': [
          [0, 1, 25],
          'content',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message, isNull);
    });

    test('parse info with non-string content returns null', () {
      final json = jsonEncode({
        'info': [
          [0, 1, 25, 0xFFFFFF, 0, 0, 'h', 1],
          12345, // not a string
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message, isNull);
    });

    test('parse empty body returns null', () {
      final message = DanmakuMessage.parse([]);
      expect(message, isNull);
    });

    test('parse with Chinese content preserves content', () {
      final json = jsonEncode({
        'info': [
          [0, 1, 25, 16777215, 0, 0, 'h', 99],
          '你好世界',
        ],
      });
      final message = DanmakuMessage.parse(utf8.encode(json));
      expect(message!.content, '你好世界');
    });
  });
}
