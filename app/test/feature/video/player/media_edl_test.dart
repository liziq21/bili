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
    test('a single-file stream yields the prefix and the address', () {
      final uri = MediaEdl.uriOf(
        MediaStream(videoUrl: 'https://cdn.example.com/v.mp4'),
      );

      expect(uri, 'edl://https://cdn.example.com/v.mp4');
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
        'edl://https://cdn.example.com/v.m4s'
        ';!new_stream'
        ';https://cdn.example.com/a.m4s',
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
        'edl://https://cdn.example.com/1.m4s'
        ';https://cdn.example.com/2.m4s'
        ';https://cdn.example.com/3.m4s',
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
        'edl://https://cdn.example.com/1.m4s'
        ';https://cdn.example.com/2.m4s'
        ';!new_stream'
        ';https://cdn.example.com/a.m4s',
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

  group('MediaEdl single-line output', () {
    // 播放器库把地址逐条写进临时播放列表文件交给 mpv 的 loadlist，每条
    // 后追加一个换行。地址内含换行会被播放列表按行切开：实测
    // EDL parsing failed，且 !new_stream 被当成文件名去找。
    test('no output form contains a line break', () {
      final streams = [
        MediaStream(videoUrl: 'https://cdn.example.com/v.mp4'),
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          audioUrl: 'https://cdn.example.com/a.m4s',
        ),
        MediaStream(
          videoUrl: 'https://cdn.example.com/1.m4s',
          audioUrl: 'https://cdn.example.com/a.m4s',
          segments: [
            MediaSegment(url: 'https://cdn.example.com/1.m4s'),
            MediaSegment(url: 'https://cdn.example.com/2.m4s'),
          ],
        ),
      ];

      for (final stream in streams) {
        expect(MediaEdl.uriOf(stream), isNot(contains('\n')));
      }
    });

    test('the EDL header line is omitted', () {
      // 首行 # mpv EDL v0 必须独占一行，而换行无法穿过播放列表，
      // 故整体省略——该行在规范中是可选注释。
      expect(
        MediaEdl.uriOf(
          MediaStream(videoUrl: 'https://cdn.example.com/v.mp4'),
        ),
        isNot(contains('mpv EDL v0')),
      );
    });
  });

  group('MediaEdl escaping', () {
    test('a comma-bearing address is escaped by byte length', () {
      final uri = MediaEdl.uriOf(
        MediaStream(videoUrl: _urlWithCommas),
      );

      expect(uri, 'edl://%${_urlWithCommas.length}%$_urlWithCommas');
    });

    test('the length prefix counts bytes, not characters', () {
      // 地址须同时含结构符号（触发转义）与非 ASCII 字符（暴露按字符
      // 还是按字节计数）。非 ASCII 字符在 UTF-8 下多占字节，长度前缀
      // 按字符算会让 mpv 截断超出的部分。
      const url = 'https://cdn.example.com/中文,a.m4s';
      final uri = MediaEdl.uriOf(MediaStream(videoUrl: url));

      final escaped = uri.substring('edl://'.length);
      final declared = int.parse(escaped.split('%').elementAt(1));
      expect(declared, greaterThan(url.length));
      expect(declared, url.length + 4);
    });

    test('the separator and the remaining structural marks are escaped', () {
      for (final url in [
        'https://cdn.example.com/a;b.m4s',
        'https://cdn.example.com/a!b.m4s',
        'https://cdn.example.com/a%b.m4s',
      ]) {
        final escaped = MediaEdl.uriOf(
          MediaStream(videoUrl: url),
        ).substring('edl://'.length);

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
        MediaEdl.uriOf(MediaStream(videoUrl: url)).substring('edl://'.length),
        url,
      );
    });

    test('an escaped separator does not split the EDL', () {
      // 逗号与分号都进了转义字符集，含逗号的地址不能让分号分隔语义
      // 多出条目。
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          audioUrl: _urlWithCommas,
        ),
      );

      expect(uri.split(';').length, 3);
    });

    test('the audio address is escaped by the same rules', () {
      final uri = MediaEdl.uriOf(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          audioUrl: _urlWithCommas,
        ),
      );

      // edl:// 前缀留在首段里，故视频地址是 parts[0] 去掉前缀。
      final parts = uri.split(';');
      expect(parts[0], 'edl://https://cdn.example.com/v.m4s');
      expect(parts[1], '!new_stream');
      expect(parts.last, '%${_urlWithCommas.length}%$_urlWithCommas');
    });
  });
}
