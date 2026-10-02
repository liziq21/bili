import 'package:app/feature/video/player/media_edl.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

/// 一条带真实形态查询串的地址：CDN 普遍带 `uparams=e,oi,platform,...`，
/// 其中逗号是 EDL 的参数分隔符。
const _urlWithCommas =
    'https://upos-sz-mirrorcos.bilivideo.com/upgcxcode/1.m4s'
    '?uparams=e,oi,platform,trid&deadline=1789333334';

void main() {
  group('MediaEdl.uriOf', () {
    test('a single-file stream yields the header and the address', () {
      final uri = MediaEdl.uriOf(
        MediaStream(videoUrl: 'https://cdn.example.com/v.mp4'),
      );

      expect(uri, 'edl://# mpv EDL v0\nhttps://cdn.example.com/v.mp4');
    });

    test('a separate-audio stream puts the audio track behind a new_stream', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          audioUrl: 'https://cdn.example.com/a.m4s',
        ),
      );

      expect(
        uri,
        'edl://# mpv EDL v0\n'
        'https://cdn.example.com/v.m4s\n'
        '!new_stream\n'
        'https://cdn.example.com/a.m4s',
      );
    });

    test('a segmented stream lists every segment in order without new_stream', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/1.m4s',
          segments: [
            MediaSegment(url: 'https://cdn.example.com/1.m4s'),
            MediaSegment(url: 'https://cdn.example.com/2.m4s'),
            MediaSegment(url: 'https://cdn.example.com/3.m4s'),
          ],
        ),
      );

      expect(
        uri,
        'edl://# mpv EDL v0\n'
        'https://cdn.example.com/1.m4s\n'
        'https://cdn.example.com/2.m4s\n'
        'https://cdn.example.com/3.m4s',
      );
    });

    test('a segmented stream with audio keeps all segments ahead of the audio', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/1.m4s',
          audioUrl: 'https://cdn.example.com/a.m4s',
          segments: [
            MediaSegment(url: 'https://cdn.example.com/1.m4s'),
            MediaSegment(url: 'https://cdn.example.com/2.m4s'),
          ],
        ),
      );

      expect(
        uri,
        'edl://# mpv EDL v0\n'
        'https://cdn.example.com/1.m4s\n'
        'https://cdn.example.com/2.m4s\n'
        '!new_stream\n'
        'https://cdn.example.com/a.m4s',
      );
    });

    test('an empty audio address does not add a new_stream', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.mp4',
          audioUrl: '',
        ),
      );

      expect(uri, isNot(contains('!new_stream')));
    });
  });

  group('MediaEdl escaping', () {
    test('a comma-bearing address is escaped by byte length', () {
      final uri = MediaEdl.uriOf(
        MediaStream(videoUrl: _urlWithCommas),
      );

      expect(
        uri,
        'edl://# mpv EDL v0\n'
        '%${_urlWithCommas.length}%$_urlWithCommas',
      );
    });

    test('the length prefix counts bytes, not characters', () {
      // 地址须同时含结构符号（触发转义）与非 ASCII 字符（暴露按字符
      // 还是按字节计数）。非 ASCII 字符在 UTF-8 下多占字节，长度前缀
      // 按字符算会让 mpv 截断超出的部分。
      const url = 'https://cdn.example.com/中文,a.m4s';
      final uri = MediaEdl.uriOf(MediaStream(videoUrl: url));

      final escaped = uri.split('\n').last;
      final declared = int.parse(escaped.split('%').elementAt(1));
      expect(declared, greaterThan(url.length));
      expect(declared, url.length + 4);
    });

    test('semicolon, exclamation mark and percent are escaped too', () {
      for (final url in [
        'https://cdn.example.com/a;b.m4s',
        'https://cdn.example.com/a!b.m4s',
        'https://cdn.example.com/a%b.m4s',
      ]) {
        final escaped = MediaEdl.uriOf(
          MediaStream(videoUrl: url),
        ).split('\n').last;

        expect(
          escaped.startsWith('%${url.length}%$url'),
          isTrue,
          reason: '$url should have been escaped',
        );
      }
    });

    test('an address without structural characters is left as is', () {
      const url = 'https://cdn.example.com/plain.m4s?a=1&b=2';

      expect(
        MediaEdl.uriOf(MediaStream(videoUrl: url)).split('\n').last,
        url,
      );
    });

    test('the audio address is escaped by the same rules', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          audioUrl: _urlWithCommas,
        ),
      );

      final lines = uri.split('\n');
      expect(lines[1], 'https://cdn.example.com/v.m4s');
      expect(lines.last, '%${_urlWithCommas.length}%$_urlWithCommas');
    });
  });
}
