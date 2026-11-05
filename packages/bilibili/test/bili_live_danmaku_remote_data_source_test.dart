import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

// ignore_for_file: use_primary_constructors

final class _TrackingLiveDataSource implements NetworkLiveDataSource {
  int getDanmuInfoCallCount = 0;

  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) async {
    getDanmuInfoCallCount++;
    throw UnimplementedError();
  }
}

void main() {
  group('BiliLiveDanmakuRemoteDataSource security validation', () {
    test(
      'terminates stream without network calls when roomId is non-positive',
      () async {
        final fakeNetwork = _TrackingLiveDataSource();
        final dataSource = BiliLiveDanmakuRemoteDataSource(
          network: fakeNetwork,
        );

        final zeroComments = await dataSource.liveDanmaku(0).toList();
        expect(zeroComments, isEmpty);
        expect(fakeNetwork.getDanmuInfoCallCount, equals(0));

        final negativeComments = await dataSource.liveDanmaku(-100).toList();
        expect(negativeComments, isEmpty);
        expect(fakeNetwork.getDanmuInfoCallCount, equals(0));
      },
    );
  });

  group('BiliLiveDanmakuRemoteDataSource.modeOf', () {
    test('mode 1 maps to scrolling', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(1), DanmakuMode.scrolling);
    });

    test('mode 0 maps to scrolling', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(0), DanmakuMode.scrolling);
    });

    test('mode 99 maps to scrolling (default)', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(99), DanmakuMode.scrolling);
    });

    test('mode 4 maps to bottom', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(4), DanmakuMode.bottom);
    });

    test('mode 5 maps to top', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(5), DanmakuMode.top);
    });

    test('mode 6 maps to reverse', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(6), DanmakuMode.reverse);
    });

    test('mode 7 maps to special', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(7), DanmakuMode.special);
    });

    test('mode 8 maps to special', () {
      expect(BiliLiveDanmakuRemoteDataSource.modeOf(8), DanmakuMode.special);
    });
  });
}
