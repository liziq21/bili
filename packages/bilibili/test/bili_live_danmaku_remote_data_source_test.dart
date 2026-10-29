import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
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
