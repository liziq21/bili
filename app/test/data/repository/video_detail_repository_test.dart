import 'package:app/data/repository/video_detail_repository.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// A data source whose reads always fail.
class _FailingVideoDetailRemoteDataSource extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'failing';

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('boom'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.ok(isLiked);

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.ok(isFavorited);

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.ok(isSubscribed);
}

/// A data source whose toggles succeed but can be told to report `false`,
/// which is how a "the server rejected this" outcome reaches the repository.
class _ControllableVideoDetailRemoteDataSource
    extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'controllable';

  bool likeResult = true;

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async => Result.ok(
    VideoDetail(
      video: VideoModel(id: id, title: 'title', url: 'https://example.com'),
      creator: CreatorProfile(id: 'c1', name: 'Creator'),
      likeCount: 0,
      favoriteCount: 0,
      isLiked: false,
      isFavorited: false,
      isSubscribed: false,
    ),
  );

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.ok(likeResult);

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.ok(isFavorited);

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.ok(isSubscribed);
}

/// `AppVideoDetailRepository` is the fallback used when the surrounding tree
/// supplies no `RepositoryProvider<VideoDetailRepository>` -- see
/// `lib/feature/video/bloc/providers.dart`, which constructs it with no
/// argument, so the no-source branch runs in the app.
///
/// The delegating branch is already covered end to end by
/// `test/feature/video_bloc_test.dart`, which asserts the arguments reaching the
/// remote data source. What is not covered there is what this repository does
/// when the source is missing, fails, or reports a negative outcome -- the
/// cases where it could substitute a value of its own.
void main() {
  group('AppVideoDetailRepository error handling', () {
    test('a remote failure is passed through, not replaced by a default', () {
      // Substituting a default detail here would render the screen as if the
      // video loaded, which is why this has to stay an error.
      final repository = AppVideoDetailRepository(
        _FailingVideoDetailRemoteDataSource(),
      );

      final result = repository.getVideoDetail('BV1');

      expect(result, isA<Future<Result<VideoDetail>>>());
      return result.then((value) {
        expect(value.isError, isTrue);
        expect(
          (value as Error<VideoDetail>).error.toString(),
          contains('boom'),
        );
      });
    });

    test('a false outcome from the remote stays false', () async {
      // The repository must not coerce `false` into `true` on its way through.
      final remote = _ControllableVideoDetailRemoteDataSource();
      remote.likeResult = false;
      final repository = AppVideoDetailRepository(remote);

      final result = await repository.toggleLike('BV1', true);

      expect((result as Ok<bool>).value, isFalse);
    });
  });

  group('AppVideoDetailRepository without a remote data source', () {
    // Constructed exactly as `lib/feature/video/bloc/providers.dart` does when
    // no provider is found in context.
    late VideoDetailRepository repository;

    setUp(() {
      repository = AppVideoDetailRepository();
    });

    test('getVideoDetail reports the capability as missing', () async {
      final result = await repository.getVideoDetail('BV123');

      expect(result.isError, isTrue);
      expect((result as Error<VideoDetail>).error.toString(), contains('不支持'));
    });

    // The three writes below used to return `Result.ok(!current)`, i.e. success
    // for an action that never happened, while the read above reported the same
    // missing capability as an error. The bloc now reads the Result and rolls
    // back on failure, so a fictional success would leave the UI showing a like
    // that was never persisted -- and no longer be inert.
    test('toggleLike reports the capability as missing', () async {
      final result = await repository.toggleLike('BV1', false);

      expect(result.isError, isTrue);
      expect((result as Error<bool>).error.toString(), contains('不支持'));
    });

    test('toggleFavorite reports the capability as missing', () async {
      final result = await repository.toggleFavorite('BV1', false);

      expect(result.isError, isTrue);
      expect((result as Error<bool>).error.toString(), contains('不支持'));
    });

    test('toggleSubscribe reports the capability as missing', () async {
      final result = await repository.toggleSubscribe('c1', false);

      expect(result.isError, isTrue);
      expect((result as Error<bool>).error.toString(), contains('不支持'));
    });

    test('the requested value cannot change a missing capability', () async {
      // The old implementation derived its answer from the argument
      // (`Result.ok(!isLiked)`), so asking for `true` yielded `false`. There is
      // no longer any value for the argument to produce.
      expect((await repository.toggleLike('BV1', true)).isError, isTrue);
      expect((await repository.toggleFavorite('BV1', true)).isError, isTrue);
      expect((await repository.toggleSubscribe('c1', true)).isError, isTrue);
    });
  });
}
