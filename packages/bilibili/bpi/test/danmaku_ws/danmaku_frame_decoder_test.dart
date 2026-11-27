import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bpi/src/danmaku_ws/danmaku_frame_decoder.dart';
import 'package:bpi/src/danmaku_ws/packet.dart';
import 'package:test/test.dart';

List<int> _messageFrame(String text) {
  final body = utf8.encode(
    jsonEncode({
      'cmd': 'DANMU_MSG',
      'info': [
        [0, 1, 25, 16777215, 0, 0, 'h', 1],
        text,
      ],
    }),
  );
  return WsPacket(
    packetLen: 16 + body.length,
    headerLen: 16,
    protocolVersion: 0,
    operation: WsOperation.message.code,
    sequence: 1,
    body: body,
  ).encode();
}

List<int> _zlibFrame(List<int> payload) {
  final compressed = ZLibCodec().encode(payload);
  return WsPacket(
    packetLen: 16 + compressed.length,
    headerLen: 16,
    protocolVersion: 2,
    operation: WsOperation.message.code,
    sequence: 1,
    body: compressed,
  ).encode();
}

void main() {
  group('DanmakuFrameDecoder', () {
    test('parses a plain message frame', () {
      final messages = DanmakuFrameDecoder().add(_messageFrame('plain'));
      expect(messages, hasLength(1));
      expect(messages.single.content, 'plain');
    });

    test('parses a zlib-compressed message frame', () {
      final messages = DanmakuFrameDecoder().add(
        _zlibFrame(_messageFrame('compressed')),
      );
      expect(messages, hasLength(1));
      expect(messages.single.content, 'compressed');
    });

    test('parses sibling compressed frames in one chunk', () {
      final chunk = [
        ..._zlibFrame(_messageFrame('first')),
        ..._zlibFrame(_messageFrame('second')),
        ..._zlibFrame(_messageFrame('third')),
        ..._zlibFrame(_messageFrame('fourth')),
      ];
      final messages = DanmakuFrameDecoder().add(chunk);
      expect(messages.map((message) => message.content), [
        'first',
        'second',
        'third',
        'fourth',
      ]);
    });

    test(
      'drops a malformed packet length instead of blocking later frames',
      () {
        final decoder = DanmakuFrameDecoder();
        final malformed = List<int>.filled(16, 0);
        expect(decoder.add([...malformed, ..._messageFrame('lost')]), isEmpty);
        expect(
          decoder.add(_messageFrame('after reset')).single.content,
          'after reset',
        );
      },
    );

    test('rejects an oversized chunk without reading its elements', () {
      final messages = DanmakuFrameDecoder().add(_OversizedProbe());
      expect(messages, isEmpty);
    });

    test('buffers a frame split across two chunks', () {
      final decoder = DanmakuFrameDecoder();
      final frame = _messageFrame('split across chunks');
      final cut = frame.length ~/ 2;
      expect(decoder.add(frame.sublist(0, cut)), isEmpty);
      final messages = decoder.add(frame.sublist(cut));
      expect(messages, hasLength(1));
      expect(messages.single.content, 'split across chunks');
    });

    test('allows nesting up to the depth limit', () {
      var frame = _messageFrame('three levels');
      for (var i = 0; i < 3; i++) {
        frame = _zlibFrame(frame);
      }
      final messages = DanmakuFrameDecoder().add(frame);
      expect(messages, hasLength(1));
      expect(messages.single.content, 'three levels');
    });

    test('drops a frame nested deeper than the limit without throwing', () {
      var frame = _messageFrame('too deep');
      for (var i = 0; i < 5; i++) {
        frame = _zlibFrame(frame);
      }
      final decoder = DanmakuFrameDecoder();
      expect(decoder.add(frame), isEmpty);
      expect(
        decoder.add(_zlibFrame(_messageFrame('after'))).single.content,
        'after',
      );
    });

    test('drops a decompression bomb instead of materialising it', () {
      final bomb = _zlibFrame(List.filled(256 * 1024, 0x20));
      final decoder = DanmakuFrameDecoder();
      expect(decoder.add(bomb), isEmpty);
      expect(
        decoder.add(_zlibFrame(_messageFrame('after bomb'))).single.content,
        'after bomb',
      );
    });

    test('drops an oversized raw chunk before buffering it', () {
      final decoder = DanmakuFrameDecoder(maxBuffer: 512);
      expect(decoder.add(List.filled(1024, 0)), isEmpty);
      expect(decoder.add(_messageFrame('after')).single.content, 'after');
    });
  });
}

class _OversizedProbe extends ListBase<int> {
  @override
  int get length => 64 * 1024 + 1;

  @override
  set length(int value) => throw StateError('length must not be set');

  @override
  int operator [](int index) => throw StateError('elements must not be read');

  @override
  void operator []=(int index, int value) =>
      throw StateError('elements must not be written');
}
