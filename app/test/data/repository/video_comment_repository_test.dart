import 'package:app/data/repository/video_comment_repository.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class _RecordingVideoCommentRemoteDataSource
    extends VideoCommentRemoteDataSource {
  @override
  String get sourceId => 'recording';

  final calls = <(String, int, int)>[];

  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    calls.add((videoId, page, pageSize));
    return Result.ok(
      Page<VideoComment>(
        number: page,
        totalPages: 5,
        data: [VideoComment(id: 'c1', authorName: 'A', content: 'text')],
      ),
    );
  }
}

/// `AppVideoCommentRepository` takes an optional data source and is constructed
/// without one in `lib/feature/video/bloc/providers.dart`, so both the
/// delegating branch and the unsupported-source branch run in the app.
void main() {
  group('AppVideoCommentRepository with a remote data source', () {
    test('forwards videoId and the default paging values', () async {
      final remote = _RecordingVideoCommentRemoteDataSource();
      final repository = AppVideoCommentRepository(remote);

      await repository.getVideoComments('BV1');

      expect(remote.calls, [('BV1', 1, 20)]);
    });

    test('forwards an explicit page and pageSize', () async {
      final remote = _RecordingVideoCommentRemoteDataSource();
      final repository = AppVideoCommentRepository(remote);

      await repository.getVideoComments('BV1', page: 4, pageSize: 5);

      expect(remote.calls, [('BV1', 4, 5)]);
    });

    test(
      'returns the page the remote produced, paging fields intact',
      () async {
        final remote = _RecordingVideoCommentRemoteDataSource();
        final repository = AppVideoCommentRepository(remote);

        final result = await repository.getVideoComments('BV1', page: 3);

        final page = (result as Ok<Page<VideoComment>>).value;
        expect(page.number, 3);
        expect(page.totalPages, 5);
        expect(page.data, hasLength(1));
      },
    );

    test(
      'does not overwrite the caller-supplied pageSize with the default',
      () async {
        final remote = _RecordingVideoCommentRemoteDataSource();
        final repository = AppVideoCommentRepository(remote);

        // A dropped pageSize would silently fetch 20 rows per page forever and
        // break the infinite-scroll paging contract.
        await repository.getVideoComments('BV1', pageSize: 50);

        expect(remote.calls.single.$3, 50);
      },
    );
  });

  group('AppVideoCommentRepository without a remote data source', () {
    late VideoCommentRepository repository;

    setUp(() {
      repository = AppVideoCommentRepository();
    });

    test('reports the capability as missing instead of an empty page', () async {
      // Returning an empty page here would render as "no comments" rather than
      // an error, so the empty-versus-error distinction has to survive.
      final result = await repository.getVideoComments('BV1');

      expect(result.isError, isTrue);
      expect(
        (result as Error<Page<VideoComment>>).error.toString(),
        contains('不支持'),
      );
    });

    test('reports the same failure on later pages', () async {
      final result = await repository.getVideoComments('BV1', page: 9);

      expect(result.isError, isTrue);
    });
  });
}
