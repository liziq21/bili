import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeLiveDataSource({
  final NetworkLiveRoomDetail? roomDetail,
  final NetworkLiveRoomPlayInfo? playInfo,
}) implements NetworkLiveDataSource {
  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) async {
    if (roomDetail != null) return roomDetail!;
    throw StateError('roomDetail not configured');
  }

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
    if (playInfo != null) return playInfo!;
    throw StateError('playInfo not configured');
  }

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) async {
    throw UnimplementedError();
  }
}

NetworkLiveRoomDetail _createRoomDetail({String? cover}) {
  return NetworkLiveRoomDetail(
    roomInfo: NetworkLiveRoomInfo(
      roomId: 1001,
      title: 'Test Live Room',
      cover: cover,
      liveStatus: 1,
      areaName: 'Gaming',
    ),
    anchorInfo: const NetworkLiveAnchorInfo(
      baseInfo: NetworkLiveAnchorBaseInfo(uname: 'Test Streamer'),
    ),
  );
}

NetworkLiveRoomPlayInfo _createPlayInfo({required String host}) {
  return NetworkLiveRoomPlayInfo(
    roomId: 1001,
    playurlInfo: NetworkLivePlayurlInfo(
      playurl: NetworkLivePlayurlData(
        stream: [
          NetworkLiveStream(
            protocolName: 'http_hls',
            format: [
              NetworkLiveStreamFormat(
                formatName: 'ts',
                codec: [
                  NetworkLiveStreamCodec(
                    codecName: 'avc',
                    baseUrl: '/live-bvc/test.m3u8?',
                    urlInfo: [
                      NetworkLiveUrlInfo(host: host, extra: 'token=123'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('BiliLiveRoomDetailRemoteDataSource security validation', () {
    test(
      'rejects non-positive roomId before network request in getLiveRoomDetail',
      () async {
        final fakeNetwork = _FakeLiveDataSource();
        final dataSource = BiliLiveRoomDetailRemoteDataSource(
          network: fakeNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );

        final zeroResult = await dataSource.getLiveRoomDetail(0);
        expect(zeroResult.isError(), isTrue);

        final negResult = await dataSource.getLiveRoomDetail(-42);
        expect(negResult.isError(), isTrue);
      },
    );

    test(
      'rejects non-positive roomId before network request in getLiveRoomStream',
      () async {
        final fakeNetwork = _FakeLiveDataSource();
        final dataSource = BiliLiveRoomDetailRemoteDataSource(
          network: fakeNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );

        final zeroResult = await dataSource.getLiveRoomStream(0);
        expect(zeroResult.isError(), isTrue);

        final negResult = await dataSource.getLiveRoomStream(-100);
        expect(negResult.isError(), isTrue);
      },
    );

    test(
      'normalizes scheme-relative and unencrypted http cover URLs to https',
      () async {
        final schemeRelativeNetwork = _FakeLiveDataSource(
          roomDetail: _createRoomDetail(
            cover: '//i0.hdslb.com/bfs/live/cover1.jpg',
          ),
        );
        final schemeRelativeSource = BiliLiveRoomDetailRemoteDataSource(
          network: schemeRelativeNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final schemeRelativeRes = await schemeRelativeSource.getLiveRoomDetail(
          1001,
        );
        expect(schemeRelativeRes.isSuccess(), isTrue);
        expect(
          (schemeRelativeRes as dynamic).success.coverUrl,
          equals('https://i0.hdslb.com/bfs/live/cover1.jpg'),
        );

        final httpNetwork = _FakeLiveDataSource(
          roomDetail: _createRoomDetail(
            cover: 'http://i0.hdslb.com/bfs/live/cover2.jpg',
          ),
        );
        final httpSource = BiliLiveRoomDetailRemoteDataSource(
          network: httpNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final httpRes = await httpSource.getLiveRoomDetail(1001);
        expect(httpRes.isSuccess(), isTrue);
        expect(
          (httpRes as dynamic).success.coverUrl,
          equals('https://i0.hdslb.com/bfs/live/cover2.jpg'),
        );

        final httpsNetwork = _FakeLiveDataSource(
          roomDetail: _createRoomDetail(
            cover: 'https://i0.hdslb.com/bfs/live/cover3.jpg',
          ),
        );
        final httpsSource = BiliLiveRoomDetailRemoteDataSource(
          network: httpsNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final httpsRes = await httpsSource.getLiveRoomDetail(1001);
        expect(httpsRes.isSuccess(), isTrue);
        expect(
          (httpsRes as dynamic).success.coverUrl,
          equals('https://i0.hdslb.com/bfs/live/cover3.jpg'),
        );
      },
    );

    test(
      'normalizes scheme-relative and unencrypted http stream URLs to https',
      () async {
        final schemeRelativeNetwork = _FakeLiveDataSource(
          playInfo: _createPlayInfo(host: '//d1.bilivideo.com'),
        );
        final schemeRelativeSource = BiliLiveRoomDetailRemoteDataSource(
          network: schemeRelativeNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final schemeRelativeRes = await schemeRelativeSource.getLiveRoomStream(
          1001,
        );
        expect(schemeRelativeRes.isSuccess(), isTrue);
        expect(
          (schemeRelativeRes as dynamic).success.videoUrl,
          equals('https://d1.bilivideo.com/live-bvc/test.m3u8?token=123'),
        );

        final httpNetwork = _FakeLiveDataSource(
          playInfo: _createPlayInfo(host: 'http://d1.bilivideo.com'),
        );
        final httpSource = BiliLiveRoomDetailRemoteDataSource(
          network: httpNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final httpRes = await httpSource.getLiveRoomStream(1001);
        expect(httpRes.isSuccess(), isTrue);
        expect(
          (httpRes as dynamic).success.videoUrl,
          equals('https://d1.bilivideo.com/live-bvc/test.m3u8?token=123'),
        );

        final httpsNetwork = _FakeLiveDataSource(
          playInfo: _createPlayInfo(host: 'https://d1.bilivideo.com'),
        );
        final httpsSource = BiliLiveRoomDetailRemoteDataSource(
          network: httpsNetwork,
          browserUserAgent: 'BiliTest/1.0',
        );
        final httpsRes = await httpsSource.getLiveRoomStream(1001);
        expect(httpsRes.isSuccess(), isTrue);
        expect(
          (httpsRes as dynamic).success.videoUrl,
          equals('https://d1.bilivideo.com/live-bvc/test.m3u8?token=123'),
        );
      },
    );
  });
}
