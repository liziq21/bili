import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// 只实现直播流解析所需方法的桩，其余方法直接抛。
class MockLiveRoomNetwork({required final Map<String, dynamic> playInfoJson})
    implements NetworkLiveDataSource {
  /// 记录最近一次 getLiveRoomPlayInfo 收到的 qn，用于验证切清晰度走 qn 参数。
  int? lastQn;

  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) =>
      throw UnimplementedError();

  @override
  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  }) async {
    lastQn = qn;
    return NetworkLiveRoomPlayInfo.fromJson(playInfoJson);
  }

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) =>
      throw UnimplementedError();
}

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

Map<String, dynamic> loadFixturePlayInfo() {
  final file = findFile('live_room_play_info.json');
  expect(file.existsSync(), isTrue);
  final envelope = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return envelope['data'] as Map<String, dynamic>;
}

/// 构造指定 qn 的直播播放信息：HLS ts avc codec 的 current_qn 与流地址
/// 均按请求的 qn 生成，用于验证「带 qn 请求 → 拿到该档流地址」。
Map<String, dynamic> playInfoForQn(int qn) => <String, dynamic>{
  'room_id': 21144080,
  'playurl_info': <String, dynamic>{
    'playurl': <String, dynamic>{
      'cid': 21144080,
      'g_qn_desc': <dynamic>[
        <String, dynamic>{'qn': 10000, 'desc': '原画'},
        <String, dynamic>{'qn': 400, 'desc': '蓝光'},
        <String, dynamic>{'qn': 250, 'desc': '超清'},
        <String, dynamic>{'qn': 150, 'desc': '高清'},
      ],
      'stream': <dynamic>[
        <String, dynamic>{
          'protocol_name': 'http_hls',
          'format': <dynamic>[
            <String, dynamic>{
              'format_name': 'ts',
              'codec': <dynamic>[
                <String, dynamic>{
                  'codec_name': 'avc',
                  'current_qn': qn,
                  'accept_qn': [10000, 400, 250, 150],
                  'base_url': '/live-bvc/1/live_x_$qn.m3u8?',
                  'url_info': <dynamic>[
                    <String, dynamic>{
                      'host': 'https://example.com',
                      'extra': 'qn=$qn',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  },
};

/// Result 没有取值方法，按 Success 的模式匹配取出成功值。
MediaStream expectOk(Result<MediaStream, Exception> result) {
  expect(result.isSuccess(), isTrue, reason: '期望成功，实际 $result');
  return switch (result) {
    Success(:final success) => success,
    _ => throw StateError('unreachable'),
  };
}

void main() {
  BiliLiveRoomDetailRemoteDataSource sourceFor(MockLiveRoomNetwork network) =>
      BiliLiveRoomDetailRemoteDataSource(
        network: network,
        browserUserAgent: 'test-agent',
      );

  group('default stream', () {
    test(
      'parses the real fixture into a MediaStream with quality list',
      () async {
        final network = MockLiveRoomNetwork(
          playInfoJson: loadFixturePlayInfo(),
        );
        final source = sourceFor(network);

        final result = await source.getLiveRoomStream(21144080);

        // 默认请求走客户端默认档 10000。
        expect(network.lastQn, 10000);
        final stream = expectOk(result);
        // 优先 HLS：ts avc codec 的流地址（fixture 捕获时 current_qn=150）。
        expect(stream.videoUrl, contains('.m3u8'));
        expect(stream.videoUrl, contains('qn=150'));
        expect(stream.streamId, 150);
        expect(stream.qualityLabel, '高清');
        // acceptQn [10000,400,250,150] ∩ gQnDesc 去掉当前档，保持 gQnDesc 顺序。
        expect(stream.alternatives, hasLength(3));
        expect(stream.alternatives.map((option) => option.streamId), [
          10000,
          400,
          250,
        ]);
        expect(stream.alternatives.map((option) => option.label), [
          '原画',
          '蓝光',
          '超清',
        ]);
      },
    );
  });

  group('preferQn', () {
    test(
      'requests the target qn and returns that quality stream URL',
      () async {
        final network = MockLiveRoomNetwork(playInfoJson: playInfoForQn(250));
        final source = sourceFor(network);

        final result = await source.getLiveRoomStream(21144080, preferQn: 250);

        expect(network.lastQn, 250);
        final stream = expectOk(result);
        expect(stream.videoUrl, contains('qn=250'));
        expect(stream.streamId, 250);
        expect(stream.qualityLabel, '超清');
        expect(stream.alternatives.map((option) => option.streamId), [
          10000,
          400,
          150,
        ]);
      },
    );
  });

  group('error paths', () {
    test('returns an error when the playinfo has no streams', () async {
      final playInfo = <String, dynamic>{
        'room_id': 21144080,
        'playurl_info': <String, dynamic>{
          'playurl': <String, dynamic>{'cid': 21144080, 'stream': <dynamic>[]},
        },
      };
      final network = MockLiveRoomNetwork(playInfoJson: playInfo);
      final source = sourceFor(network);

      final result = await source.getLiveRoomStream(21144080);

      expect(result.isError(), isTrue);
    });

    test('returns an error when the codec has no stream URL', () async {
      final playInfo = <String, dynamic>{
        'room_id': 21144080,
        'playurl_info': <String, dynamic>{
          'playurl': <String, dynamic>{
            'cid': 21144080,
            'stream': <dynamic>[
              <String, dynamic>{
                'protocol_name': 'http_hls',
                'format': <dynamic>[
                  <String, dynamic>{
                    'format_name': 'ts',
                    'codec': <dynamic>[
                      <String, dynamic>{
                        'codec_name': 'avc',
                        'url_info': <dynamic>[],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        },
      };
      final network = MockLiveRoomNetwork(playInfoJson: playInfo);
      final source = sourceFor(network);

      final result = await source.getLiveRoomStream(21144080);

      expect(result.isError(), isTrue);
    });
  });
}
