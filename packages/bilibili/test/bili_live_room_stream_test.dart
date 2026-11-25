import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:model/model.dart';

/// 只实现直播流解析所需方法的桩，其余方法直接抛。
class MockLiveRoomNetwork({required final Map<String, dynamic> playInfoJson})
    implements NetworkLiveDataSource {
  @override
  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    required List<int> roomIds,
  }) => throw UnimplementedError();

  @override
  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    required List<int> uids,
  }) => throw UnimplementedError();

  @override
  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    int pageSize = 30,
  }) => throw UnimplementedError();

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
        // 探测不联网：默认全部可用，候选选择另由 fallback 组验证。
        probe: (url, headers) async => true,
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
        // fixture 里房间没给原画：最高可用档是 250（超清），它在 FLV 上是
        // hevc，150（高清）才是 avc。档位高低先于封装与编码，所以选 250 的
        // FLV 流——请求的档没给时退回最高可用档，而不是协议排序第一的档。
        expect(stream.videoUrl, contains('.flv'));
        expect(stream.videoUrl, contains('qn=250'));
        expect(stream.streamId, 250);
        expect(stream.qualityLabel, '超清');
        // acceptQn [10000,400,250] ∩ gQnDesc 去掉当前档，保持 gQnDesc 顺序。
        expect(stream.alternatives, hasLength(2));
        expect(stream.alternatives.map((option) => option.streamId), [
          10000,
          400,
        ]);
        expect(stream.alternatives.map((option) => option.label), ['原画', '蓝光']);
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

  group('candidate fallback', () {
    /// FLV 与 HLS 并存：两种协议各一路，url_info 可给多个 host。
    Map<String, dynamic> playInfoWithBoth({List<String> flvHosts = const []}) =>
        <String, dynamic>{
          'room_id': 1918661467,
          'playurl_info': <String, dynamic>{
            'playurl': <String, dynamic>{
              'cid': 1918661467,
              'g_qn_desc': <dynamic>[
                <String, dynamic>{'qn': 10000, 'desc': '原画'},
                <String, dynamic>{'qn': 250, 'desc': '超清'},
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
                          'current_qn': 250,
                          'accept_qn': [10000, 250],
                          'base_url': '/live-bvc/hls/live.m3u8?',
                          'url_info': <dynamic>[
                            <String, dynamic>{
                              'host': 'https://hls.example.com',
                              'extra': 'qn=250',
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
                <String, dynamic>{
                  'protocol_name': 'http_stream',
                  'format': <dynamic>[
                    <String, dynamic>{
                      'format_name': 'flv',
                      'codec': <dynamic>[
                        <String, dynamic>{
                          'codec_name': 'avc',
                          'current_qn': 250,
                          'accept_qn': [10000, 250],
                          'base_url': '/live-bvc/flv/live.flv?',
                          'url_info':
                              (flvHosts.isEmpty
                                      ? <String>['https://flv.example.com']
                                      : flvHosts)
                                  .map(
                                    (host) => <String, dynamic>{
                                      'host': host,
                                      'extra': 'qn=250',
                                    },
                                  )
                                  .toList(),
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        };

    test('probes FLV before HLS and returns the FLV address', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(playInfoJson: playInfoWithBoth()),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return true;
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(stream.videoUrl, contains('.flv'));
      expect(stream.streamId, 250);
      expect(stream.qualityLabel, '超清');
      expect(probed, hasLength(1));
    });

    test('falls back to HLS when the FLV address never responds', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(playInfoJson: playInfoWithBoth()),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return url.contains('.m3u8');
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(stream.videoUrl, contains('.m3u8'));
      expect(probed, hasLength(2));
      expect(probed.first, contains('.flv'));
      expect(probed.last, contains('.m3u8'));
    });

    test('tries the next CDN host when the first one is dead', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoWithBoth(
            flvHosts: const [
              'https://dead.example.com',
              'https://live.example.com',
            ],
          ),
        ),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return url.contains('live.example.com');
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(stream.videoUrl, contains('live.example.com'));
      expect(probed, hasLength(2));
      expect(probed.first, contains('dead.example.com'));
    });

    test(
      'reports every candidate as unavailable when all probes fail',
      () async {
        final source = BiliLiveRoomDetailRemoteDataSource(
          network: MockLiveRoomNetwork(playInfoJson: playInfoWithBoth()),
          browserUserAgent: 'test-agent',
          probe: (url, headers) async => false,
        );

        final result = await source.getLiveRoomStream(1918661467);

        expect(result.isError(), isTrue);
        expect(switch (result) {
          Error(:final error) => error.toString(),
          _ => '',
        }, contains('所有候选地址均不可用'));
      },
    );

    test(
      'picks the codec matching the requested qn instead of the first',
      () async {
        final probed = <String>[];
        final playInfo = <String, dynamic>{
          'room_id': 21144080,
          'playurl_info': <String, dynamic>{
            'playurl': <String, dynamic>{
              'cid': 21144080,
              'g_qn_desc': <dynamic>[
                <String, dynamic>{'qn': 10000, 'desc': '原画'},
                <String, dynamic>{'qn': 400, 'desc': '蓝光'},
                <String, dynamic>{'qn': 150, 'desc': '高清'},
              ],
              'stream': <dynamic>[
                <String, dynamic>{
                  'protocol_name': 'http_stream',
                  'format': <dynamic>[
                    <String, dynamic>{
                      'format_name': 'flv',
                      'codec': <dynamic>[
                        for (final qn in [150, 400])
                          <String, dynamic>{
                            'codec_name': 'avc',
                            'current_qn': qn,
                            'accept_qn': [10000, 400, 150],
                            'base_url': '/live-bvc/flv/live_$qn.flv?',
                            'url_info': <dynamic>[
                              <String, dynamic>{
                                'host': 'https://flv.example.com',
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
        final source = BiliLiveRoomDetailRemoteDataSource(
          network: MockLiveRoomNetwork(playInfoJson: playInfo),
          browserUserAgent: 'test-agent',
          probe: (url, headers) async {
            probed.add(url);
            return true;
          },
        );

        final stream = expectOk(
          await source.getLiveRoomStream(21144080, preferQn: 400),
        );

        expect(stream.videoUrl, contains('qn=400'));
        expect(stream.streamId, 400);
        expect(stream.qualityLabel, '蓝光');
        expect(probed.single, contains('qn=400'));
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

  group('candidate ordering', () {
    Map<String, dynamic> codecJson(
      String name,
      int qn, {
      required String baseUrl,
      List<String> hosts = const ['https://cdn.example.com'],
    }) => <String, dynamic>{
      'codec_name': name,
      'current_qn': qn,
      'accept_qn': [10000, qn],
      'base_url': baseUrl,
      'url_info': hosts
          .map((host) => <String, dynamic>{'host': host, 'extra': 'qn=$qn'})
          .toList(),
    };

    Map<String, dynamic> streamJson(
      String protocol,
      String formatName,
      List<Map<String, dynamic>> codecs,
    ) => <String, dynamic>{
      'protocol_name': protocol,
      'format': <dynamic>[
        <String, dynamic>{'format_name': formatName, 'codec': codecs},
      ],
    };

    Map<String, dynamic> playInfoJson(List<Map<String, dynamic>> streams) =>
        <String, dynamic>{
          'room_id': 1918661467,
          'playurl_info': <String, dynamic>{
            'playurl': <String, dynamic>{
              'cid': 1918661467,
              'g_qn_desc': <dynamic>[
                <String, dynamic>{'qn': 10000, 'desc': '原画'},
                <String, dynamic>{'qn': 250, 'desc': '超清'},
              ],
              'stream': streams,
            },
          },
        };

    test('probes the requested quality before the FLV default', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson('avc', 250, baseUrl: '/live/flv/live.flv?'),
            ]),
            streamJson('http_hls', 'ts', [
              codecJson('avc', 10000, baseUrl: '/live/hls/live.m3u8?'),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return true;
        },
      );

      final stream = expectOk(
        await source.getLiveRoomStream(1918661467, preferQn: 10000),
      );

      expect(probed, hasLength(1));
      expect(probed.single, contains('.m3u8'));
      expect(stream.streamId, 10000);
      expect(stream.qualityLabel, '原画');
    });

    test('honours the default quality when no qn is requested', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson('avc', 150, baseUrl: '/live/flv/live.flv?'),
            ]),
            streamJson('http_hls', 'ts', [
              codecJson('avc', 10000, baseUrl: '/live/hls/live.m3u8?'),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return true;
        },
      );

      // 默认请求的是原画（qn 10000）：即使 FLV 排在协议前面，也不能选 150。
      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(probed, hasLength(1));
      expect(stream.videoUrl, contains('.m3u8'));
      expect(stream.streamId, 10000);
    });

    test(
      'falls back to the highest available quality, not the first codec',
      () async {
        final probed = <String>[];
        final source = BiliLiveRoomDetailRemoteDataSource(
          network: MockLiveRoomNetwork(
            playInfoJson: playInfoJson([
              // FLV 排在协议前面，但只有 150；请求的原画只在 HLS 上给到 250。
              streamJson('http_stream', 'flv', [
                codecJson('avc', 150, baseUrl: '/live/flv/live.flv?'),
              ]),
              streamJson('http_hls', 'ts', [
                codecJson('avc', 250, baseUrl: '/live/hls/live.m3u8?'),
              ]),
            ]),
          ),
          browserUserAgent: 'test-agent',
          probe: (url, headers) async {
            probed.add(url);
            return true;
          },
        );

        final stream = expectOk(await source.getLiveRoomStream(1918661467));

        // 请求的 10000 房间没提供：退回最高可用档 250，而不是协议排序第一的 150。
        expect(probed, hasLength(1));
        expect(stream.streamId, 250);
      },
    );

    test('probes HLS before FLV when the player runs in a browser', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson('avc', 250, baseUrl: '/live/flv/live.flv?'),
            ]),
            streamJson('http_hls', 'ts', [
              codecJson('avc', 250, baseUrl: '/live/hls/live.m3u8?'),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        browserPlayer: true,
        probe: (url, headers) async {
          probed.add(url);
          return true;
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(probed, hasLength(1));
      expect(probed.single, contains('.m3u8'));
      expect(stream.videoUrl, contains('.m3u8'));
    });

    test('falls back to another codec of the same format', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson(
                'avc',
                250,
                baseUrl: '/live/flv/avc.flv?',
                hosts: const ['https://dead.example.com'],
              ),
              codecJson(
                'hevc',
                250,
                baseUrl: '/live/flv/hevc.flv?',
                hosts: const ['https://live.example.com'],
              ),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          return url.contains('live.example.com');
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(probed, hasLength(2));
      expect(probed.first, contains('dead.example.com'));
      expect(stream.videoUrl, contains('hevc.flv'));
      expect(stream.streamId, 250);
    });

    test('probes through the injected HTTP client', () async {
      final requested = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson('avc', 250, baseUrl: '/live/flv/live.flv?'),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        // 不注入 probe：默认探测必须用这条客户端，而不是自建裸客户端。
        clientFactory: () => MockClient.streaming((request, bodyStream) async {
          requested.add(request.url.toString());
          return http.StreamedResponse(Stream.value(<int>[35]), 200);
        }),
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(requested, [stream.videoUrl]);
      expect(stream.videoUrl, contains('.flv'));
    });

    test('keeps probing when a probe itself throws', () async {
      final probed = <String>[];
      final source = BiliLiveRoomDetailRemoteDataSource(
        network: MockLiveRoomNetwork(
          playInfoJson: playInfoJson([
            streamJson('http_stream', 'flv', [
              codecJson('avc', 250, baseUrl: '/live/flv/live.flv?'),
            ]),
            streamJson('http_hls', 'ts', [
              codecJson('avc', 250, baseUrl: '/live/hls/live.m3u8?'),
            ]),
          ]),
        ),
        browserUserAgent: 'test-agent',
        probe: (url, headers) async {
          probed.add(url);
          if (probed.length == 1) throw const FormatException('bad url');
          return true;
        },
      );

      final stream = expectOk(await source.getLiveRoomStream(1918661467));

      expect(probed, hasLength(2));
      expect(stream.videoUrl, contains('.m3u8'));
    });
  });

  group('probeLiveStreamUrl', () {
    const headers = <String, String>{'User-Agent': 'test-agent'};

    http.Client Function() clientReturning(
      http.StreamedResponse Function(http.BaseRequest request) respond,
    ) =>
        () => MockClient.streaming(
          (request, bodyStream) async => respond(request),
        );

    test('treats a response that yields bytes as reachable', () async {
      final reachable = await probeLiveStreamUrl(
        'https://cdn.example.com/live.m3u8',
        headers,
        clientFactory: clientReturning(
          (_) => http.StreamedResponse(Stream.value(<int>[35]), 200),
        ),
      );

      expect(reachable, isTrue);
    });

    test('gives up when the body never yields a byte', () async {
      final silent = StreamController<List<int>>();
      addTearDown(silent.close);
      final stopwatch = Stopwatch()..start();

      final reachable = await probeLiveStreamUrl(
        'https://cdn.example.com/live.flv',
        headers,
        clientFactory: clientReturning(
          (_) => http.StreamedResponse(silent.stream, 200),
        ),
        timeout: const Duration(milliseconds: 50),
      );

      expect(reachable, isFalse);
      // 响应头与首字节共用同一个预算：两段各自计时会等满两倍超时。
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('rejects an error status even with a body', () async {
      final reachable = await probeLiveStreamUrl(
        'https://cdn.example.com/live.flv',
        headers,
        clientFactory: clientReturning(
          (_) => http.StreamedResponse(Stream.value(<int>[35]), 404),
        ),
      );

      expect(reachable, isFalse);
    });

    test('returns false instead of throwing on a malformed URL', () async {
      final reachable = await probeLiveStreamUrl(
        'not a url',
        headers,
        clientFactory: clientReturning(
          (_) => http.StreamedResponse(Stream.value(<int>[35]), 200),
        ),
      );

      expect(reachable, isFalse);
    });
  });
}
