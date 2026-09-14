import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/bloc/video_comment_bloc.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class FakeVideoDetailRemoteDataSource extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    final video = VideoModel(
      id: id,
      title: 'Test Video Title $id',
      url: 'https://example.com/$id',
    );
    final detail = VideoDetail(
      video: video,
      likeCount: 10,
    );
    return Result.ok(detail);
  }
}

class FakeVideoCommentRemoteDataSource extends VideoCommentRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final comment = VideoComment(
      id: 'c1',
      authorName: 'User 1',
      content: 'Comment 1',
    );
    return Result.ok(
      Page<VideoComment>(
        number: page,
        totalPages: 2,
        data: [comment],
      ),
    );
  }
}

void main() {
  group('VideoBloc Tests', () {
    late AppVideoDetailRepository detailRepo;
    late VideoBloc videoBloc;

    setUp(() {
      detailRepo =
          AppVideoDetailRepository(FakeVideoDetailRemoteDataSource());
      videoBloc = VideoBloc(repository: detailRepo);
    });

    tearDown(() {
      videoBloc.close();
    });

    test('Initial state is correct', () {
      expect(videoBloc.state, const VideoState());
    });

    test('LoadVideoDetail loads video detail successfully', () async {
      videoBloc.add(const LoadVideoDetail('test_id'));

      await expectLater(
        videoBloc.stream,
        emitsInOrder([
          const VideoState(isLoading: true),
          predicate<VideoState>((state) {
            return !state.isLoading &&
                state.videoDetail != null &&
                state.videoDetail!.video.id == 'test_id';
          }),
        ]),
      );
    });

    test('ToggleVideoLike updates like state and count', () async {
      videoBloc.add(const LoadVideoDetail('test_id'));
      await videoBloc.stream.firstWhere((s) => !s.isLoading);

      final initialLikeCount = videoBloc.state.videoDetail!.likeCount;
      videoBloc.add(const ToggleVideoLike());

      await expectLater(
        videoBloc.stream,
        emits(predicate<VideoState>((state) {
          return state.videoDetail!.isLiked == true &&
              state.videoDetail!.likeCount == initialLikeCount + 1;
        })),
      );
    });

    test('AppVideoDetailRepository returns error when no remote data source',
        () async {
      final repoWithoutSource = AppVideoDetailRepository();
      final result = await repoWithoutSource.getVideoDetail('test_id');
      expect(result.isError, isTrue);
    });
  });

  group('VideoCommentBloc Tests', () {
    late AppVideoCommentRepository commentRepo;
    late VideoCommentBloc commentBloc;

    setUp(() {
      commentRepo =
          AppVideoCommentRepository(FakeVideoCommentRemoteDataSource());
      commentBloc = VideoCommentBloc(repository: commentRepo);
    });

    tearDown(() {
      commentBloc.close();
    });

    test('Initial state is correct', () {
      expect(commentBloc.state, const VideoCommentState());
    });

    test('LoadVideoComments fetches first page of comments', () async {
      commentBloc.add(const LoadVideoComments('test_id'));

      await expectLater(
        commentBloc.stream,
        emitsInOrder([
          predicate<VideoCommentState>(
              (s) => s.isLoading && s.videoId == 'test_id'),
          predicate<VideoCommentState>((s) {
            return !s.isLoading &&
                s.comments.isNotEmpty &&
                s.currentPage == 1 &&
                s.hasMore == true;
          }),
        ]),
      );
    });

    test('ToggleCommentLike updates comment like status', () async {
      commentBloc.add(const LoadVideoComments('test_id'));
      await commentBloc.stream.firstWhere((s) => !s.isLoading);

      final targetCommentId = commentBloc.state.comments.first.id;
      commentBloc.add(ToggleCommentLike(targetCommentId));

      await expectLater(
        commentBloc.stream,
        emits(predicate<VideoCommentState>((s) {
          final target = s.comments.firstWhere((c) => c.id == targetCommentId);
          return target.isLiked == true;
        })),
      );
    });

    test('AppVideoCommentRepository returns error when no remote data source',
        () async {
      final repoWithoutSource = AppVideoCommentRepository();
      final result = await repoWithoutSource.getVideoComments('test_id');
      expect(result.isError, isTrue);
    });
  });
}
