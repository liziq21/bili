import 'package:data/data.dart';
// `isError` / `Ok` / `Error` 来自 package:model，data 包没有 re-export 它。
// app 侧同名测试用同样的 import 形态。
import 'package:model/model.dart';
import 'package:test/test.dart';

/// 覆盖 [VideoDetailRemoteDataSource] 互动能力的默认实现。
///
/// 这些默认值就是生产路径：bilibili 与 youtube 都只覆写了 getVideoDetail，
/// 点赞/收藏/关注三处仍走基类默认。默认实现早先返回 `Result.ok(!当前值)`，
/// 即「对没发生的操作报成功」；调用方（app 侧 VideoBloc）据此回滚乐观更新，
/// 所以基类必须自己报失败。
class const _DetailSource() extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'stub';

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      throw UnimplementedError();
}

void main() {
  group('VideoDetailRemoteDataSource toggle defaults', () {
    late VideoDetailRemoteDataSource source;

    setUp(() {
      source = _DetailSource();
    });

    test('toggleLike reports the capability as missing', () async {
      // Not `Result.ok(!isLiked)`: a data source that never performed the write
      // must not hand back a value that reads like a persisted new state.
      final result = await source.toggleLike('BV1', true);

      expect(result.isError, isTrue);
    });

    test('toggleFavorite reports the capability as missing', () async {
      final result = await source.toggleFavorite('BV1', false);

      expect(result.isError, isTrue);
    });

    test('toggleSubscribe reports the capability as missing', () async {
      final result = await source.toggleSubscribe('c1', true);

      expect(result.isError, isTrue);
    });

    test(
      'the requested value cannot turn a missing capability into a success',
      () async {
        // The old implementation derived its answer from the argument, so both
        // `true` and `false` produced an `Ok`. Neither may now.
        for (final requested in [true, false]) {
          expect((await source.toggleLike('BV1', requested)).isError, isTrue);
          expect(
            (await source.toggleFavorite('BV1', requested)).isError,
            isTrue,
          );
          expect(
            (await source.toggleSubscribe('c1', requested)).isError,
            isTrue,
          );
        }
      },
    );

    test('the error explains which capability is missing', () async {
      // The message is surfaced to the user through the bloc's actionError
      // path, so it has to say what is unavailable rather than just fail.
      final message = ((await source.toggleLike('BV1', true)) as Error<bool>)
          .error
          .toString();

      expect(message, contains('点赞'));
    });
  });
}
