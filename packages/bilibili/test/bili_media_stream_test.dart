import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// 只实现播放地址解析所需方法的桩，其余方法直接抛。
class MockMediaStreamNetwork({
  required final Map<String, dynamic> videoDetailJson,
  required final Map<String, dynamic> playUrlJson,

  /// 为 true 时 `getVideoDetail` 抛异常，用于验证异常收敛路径。
  final bool failDetailRequest = false,
}) implements NetworkVideoDataSource {
  /// 记录最近一次 getPlayUrl 收到的 cid，用于验证接口按分P而非 bvid 取址。
  int? lastCid;

  @override
  Future<VideoDetailData> getVideoDetail({required String bvid}) async {
    if (failDetailRequest) throw Exception('network down');
    return VideoDetailData.fromJson(
      videoDetailJson['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<NetworkPlayUrl> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) async {
    lastCid = cid;
    return NetworkPlayUrl.fromJson(playUrlJson['data'] as Map<String, dynamic>);
  }

  @override
  Future<NetworkVideoRelation> getVideoRelation({required String bvid}) =>
      throw UnimplementedError();

  @override
  Future<List<NetworkRelatedVideo>> getRelatedVideos({required String bvid}) =>
      throw UnimplementedError();

  @override
  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int page = 1,
    int sort = 1,
    String? nextOffset,
  }) => throw UnimplementedError();

  @override
  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int page = 1,
  }) => throw UnimplementedError();

  @override
  Future<NetworkBiliPlayerInfo> getPlayerInfo({
    required String bvid,
    required int cid,
  }) => throw UnimplementedError();

  @override
  Future<NetworkBangumiSeasonData> getBangumiSeason({
    int? seasonId,
    int? epId,
  }) => throw UnimplementedError();

  @override
  Future<NetworkPlayUrl> getBangumiPlayUrl({
    int? epId,
    int? cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) => throw UnimplementedError();
}

void main() {
  File findFile(String fileName) {
    final candidates = [
      'packages/bilibili/bpi/testing/$fileName',
      'bpi/testing/$fileName',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return File(candidates.first);
  }

  dynamic loadJson(String fileName) =>
      jsonDecode(findFile(fileName).readAsStringSync());

  final videoDetailJson = loadJson('video_detail.json');
  final playUrlJson = loadJson('play_url.json');

  MediaStreamRemoteDataSource makeSource(Map<String, dynamic> playUrl) =>
      BiliMediaStreamRemoteDataSource(
        network: MockMediaStreamNetwork(
          videoDetailJson: videoDetailJson as Map<String, dynamic>,
          playUrlJson: playUrl,
        ),
        browserUserAgent: 'Mozilla/5.0 Test UA',
      );

  /// 造一份 play_url 响应。键名与 bpi 的解析层对齐，避免手写键名漂移。
  Map<String, dynamic> buildPlayUrl({
    List<Map<String, dynamic>> video = const [],
    List<Map<String, dynamic>>? audio,
    List<Map<String, dynamic>> durl = const [],
    int duration = 105,
  }) => <String, dynamic>{
    'code': 0,
    'data': <String, dynamic>{
      'dash': <String, dynamic>{
        'duration': duration,
        'video': video,
        // 缺省给一条可用音轨：多数用例只关心选流，显式传空列表才是
        // 「无音轨」这个待测场景。
        'audio':
            audio ??
            [
              {
                'id': 30280,
                'baseUrl': 'https://cdn.example/audio-default.m4s',
                'bandwidth': 192000,
              },
            ],
      },
      'durl': durl,
    },
  };

  /// Result 没有取值方法，按 Ok 的模式匹配取出成功值。
  MediaStream expectOk(Result<MediaStream> result) {
    expect(result.isOk, isTrue, reason: '期望成功，实际 $result');
    return switch (result) {
      Ok(:final value) => value,
      _ => throw StateError('unreachable'),
    };
  }

  group('BiliMediaStreamRemoteDataSource', () {
    test('解析 DASH 为分离流：画面进 videoUrl，声音进 audioUrl', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {
              'id': 32,
              'baseUrl': 'https://cdn.example/video-720.m4s',
              'backupUrl': ['https://backup.example/video-720.m4s'],
              'bandwidth': 1200000,
              'codecs': 'avc1.640028',
              'width': 1280,
              'height': 720,
            },
          ],
          audio: [
            {
              'id': 30280,
              'baseUrl': 'https://cdn.example/audio.m4s',
              'bandwidth': 192000,
              'codecs': 'mp4a.40.2',
            },
          ],
        ),
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');

      expect(result.isOk, isTrue, reason: '期望成功，实际 $result');
      final stream = expectOk(result);
      expect(stream.videoUrl, 'https://cdn.example/video-720.m4s');
      expect(stream.audioUrl, 'https://cdn.example/audio.m4s');
      expect(stream.hasSeparateAudio, isTrue);
      expect(stream.width, 1280);
      expect(stream.height, 720);
      expect(stream.bitrate, 1200000);
      expect(stream.codecs, 'avc1.640028');
      expect(stream.duration, const Duration(seconds: 105));
    });

    test('请求头带浏览器标识与 Referer', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {'id': 32, 'baseUrl': 'https://cdn.example/v.m4s', 'height': 720},
          ],
        ),
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');
      final stream = expectOk(result);

      expect(stream.headers['User-Agent'], 'Mozilla/5.0 Test UA');
      expect(stream.headers['Referer'], 'https://www.bilibili.com/');
    });

    test('按分P的 cid 取播放地址，而不是直接用 bvid', () async {
      final network = MockMediaStreamNetwork(
        videoDetailJson: videoDetailJson as Map<String, dynamic>,
        playUrlJson: buildPlayUrl(
          video: [
            {'id': 32, 'baseUrl': 'https://cdn.example/v.m4s', 'height': 720},
          ],
        ),
      );
      final source = BiliMediaStreamRemoteDataSource(
        network: network,
        browserUserAgent: 'Mozilla/5.0 Test UA',
      );

      await source.getMediaStream('BV1GJ411x7vy');

      expect(
        network.lastCid,
        137646676,
        reason: 'fixture 首个分P 的 cid 应原样传给 getPlayUrl',
      );
    });

    test('preferHeight 选不高于期望的最高一路', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {
              'id': 120,
              'baseUrl': 'https://cdn.example/v-4k.m4s',
              'height': 2160,
            },
            {
              'id': 80,
              'baseUrl': 'https://cdn.example/v-1080.m4s',
              'height': 1080,
            },
            {
              'id': 32,
              'baseUrl': 'https://cdn.example/v-720.m4s',
              'height': 720,
            },
          ],
        ),
      );

      final stream = expectOk(
        await source.getMediaStream('BV1GJ411x7vy', preferHeight: 1080),
      );
      expect(stream.height, 1080);
      expect(stream.videoUrl, 'https://cdn.example/v-1080.m4s');
    });

    test('preferHeight 高于所有可用档时取最高一路', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {
              'id': 32,
              'baseUrl': 'https://cdn.example/v-720.m4s',
              'height': 720,
            },
            {
              'id': 64,
              'baseUrl': 'https://cdn.example/v-480.m4s',
              'height': 480,
            },
          ],
        ),
      );

      final stream = expectOk(
        await source.getMediaStream('BV1GJ411x7vy', preferHeight: 4320),
      );
      expect(stream.height, 720);
    });

    test('preferHeight 低于所有可用档时退到最低一路', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {
              'id': 32,
              'baseUrl': 'https://cdn.example/v-720.m4s',
              'height': 720,
            },
            {
              'id': 64,
              'baseUrl': 'https://cdn.example/v-480.m4s',
              'height': 480,
            },
          ],
        ),
      );

      final stream = expectOk(
        await source.getMediaStream('BV1GJ411x7vy', preferHeight: 360),
      );
      expect(stream.height, 480);
    });

    test('不给 preferHeight 时取码率最高的一路', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {
              'id': 32,
              'baseUrl': 'https://cdn.example/v-low.m4s',
              'bandwidth': 500000,
            },
            {
              'id': 80,
              'baseUrl': 'https://cdn.example/v-high.m4s',
              'bandwidth': 3000000,
            },
          ],
        ),
      );

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.videoUrl, 'https://cdn.example/v-high.m4s');
    });

    test('durl 单段：无分离音轨，地址可直放', () async {
      final source = makeSource(<String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'durl': [
            {
              'order': 1,
              'length': 105000,
              'size': 123456,
              'url': 'https://cdn.example/muxed.mp4',
              'backupUrl': ['https://backup.example/muxed.mp4'],
            },
          ],
        },
      });

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.videoUrl, 'https://cdn.example/muxed.mp4');
      expect(stream.audioUrl, isNull);
      expect(stream.hasSeparateAudio, isFalse);
      // 备选地址是同一段的镜像，不算新片段。
      expect(stream.segments, hasLength(1));
      expect(stream.segments.first.url, 'https://cdn.example/muxed.mp4');
      expect(
        stream.segments.first.duration,
        const Duration(milliseconds: 105000),
      );
    });

    test('durl 多段：保留全部片段并按 order 排序', () async {
      final source = makeSource(<String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'durl': [
            {'order': 2, 'length': 40000, 'url': 'https://cdn.example/p2.mp4'},
            {'order': 1, 'length': 60000, 'url': 'https://cdn.example/p1.mp4'},
            {'order': 3, 'length': 30000, 'url': 'https://cdn.example/p3.mp4'},
          ],
        },
      });

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.isSegmented, isTrue);
      expect(stream.segments.map((segment) => segment.url).toList(), [
        'https://cdn.example/p1.mp4',
        'https://cdn.example/p2.mp4',
        'https://cdn.example/p3.mp4',
      ], reason: '响应乱序返回，必须按 order 升序拼，否则播放顺序错乱');
      expect(stream.videoUrl, 'https://cdn.example/p1.mp4');
    });

    test('DASH 有视频但无可用音轨时报错，不返回无声流', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {'id': 32, 'baseUrl': 'https://cdn.example/v.m4s', 'height': 720},
          ],
          audio: [
            {'id': 30280, 'bandwidth': 192000},
          ],
        ),
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');
      expect(result.isError, isTrue);
      expect('$result', contains('音轨'), reason: 'audioUrl 为空会被播放层当作自带声音，必然无声');
    });

    test('durl 中间片段无地址时报错，不返回缺片的序列', () async {
      final source = makeSource(
        buildPlayUrl(
          durl: [
            {'order': 1, 'length': 30000, 'url': 'https://cdn.example/p1.mp4'},
            // 该片段既无 url 也无 backupUrl，整段不可用。
            {'order': 2, 'length': 30000},
            {'order': 3, 'length': 30000, 'url': 'https://cdn.example/p3.mp4'},
          ],
        ),
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');
      expect(result.isError, isTrue, reason: '静默跳过会交给播放层一段残缺序列，播放中途断掉且无从察觉');
    });

    test('最高档视频缺地址时降级到可用档', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {'id': 120, 'baseUrl': '', 'height': 2160, 'bandwidth': 9000000},
            {
              'id': 80,
              'baseUrl': 'https://cdn.example/v-1080.m4s',
              'height': 1080,
              'bandwidth': 2000000,
            },
          ],
          audio: [
            {
              'id': 30280,
              'baseUrl': 'https://cdn.example/a.m4s',
              'bandwidth': 192000,
            },
          ],
        ),
      );

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.videoUrl, 'https://cdn.example/v-1080.m4s');
    });

    test('最高码率音轨缺地址时降级到可用音轨', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {'id': 32, 'baseUrl': 'https://cdn.example/v.m4s', 'height': 720},
          ],
          audio: [
            {'id': 30280, 'baseUrl': '', 'bandwidth': 999000},
            {
              'id': 30216,
              'baseUrl': 'https://cdn.example/a-low.m4s',
              'bandwidth': 67000,
            },
          ],
        ),
      );

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.audioUrl, 'https://cdn.example/a-low.m4s');
    });

    test('dash 为空时走 durl 分支', () async {
      final source = makeSource(<String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'dash': <String, dynamic>{'duration': 105, 'video': [], 'audio': []},
          'durl': [
            {'order': 1, 'length': 105, 'url': 'https://cdn.example/muxed.mp4'},
          ],
        },
      });

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));
      expect(stream.videoUrl, 'https://cdn.example/muxed.mp4');
      expect(stream.hasSeparateAudio, isFalse);
    });

    test('真实 fixture：按码率最高挑出视频与音频流', () async {
      final source = makeSource(playUrlJson);

      final stream = expectOk(await source.getMediaStream('BV1GJ411x7vy'));

      // fixture 实测两路视频（480p / 360p）、三路音频，无 durl。
      expect(stream.height, 480);
      expect(stream.videoUrl, contains('http'));
      expect(stream.audioUrl, isNotNull);
      expect(stream.hasSeparateAudio, isTrue);
      expect(stream.duration, const Duration(seconds: 105));
      // 音频取码率最高的一路（30280，321815）。
      expect(stream.codecs, 'avc1.64001F');
    });

    test('既无 dash 视频流也无 durl 时报不可播放', () async {
      final source = makeSource(<String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{},
      });

      final result = await source.getMediaStream('BV1GJ411x7vy');
      expect(result.isError, isTrue);
    });

    test('视频流缺少地址时报错而非返回空地址', () async {
      final source = makeSource(
        buildPlayUrl(
          video: [
            {'id': 32, 'height': 720},
          ],
        ),
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');
      expect(result.isError, isTrue);
    });

    test('网络异常收敛为 Result.error 而非抛出', () async {
      final source = BiliMediaStreamRemoteDataSource(
        network: MockMediaStreamNetwork(
          videoDetailJson: videoDetailJson as Map<String, dynamic>,
          playUrlJson: playUrlJson,
          failDetailRequest: true,
        ),
        browserUserAgent: 'Mozilla/5.0 Test UA',
      );

      final result = await source.getMediaStream('BV1GJ411x7vy');
      expect(result.isError, isTrue);
    });

    test('getMediaStream 清理控制字符并针对空 videoId 返回 Result.error', () async {
      final source = makeSource(playUrlJson);

      final sanitizedResult = await source.getMediaStream(
        'BV1GJ411x7vy\r\n\x00',
      );
      expect(sanitizedResult.isOk, isTrue);

      final emptyResult = await source.getMediaStream('  \r\n\x00 ');
      expect(emptyResult.isError, isTrue);
    });
  });
}
