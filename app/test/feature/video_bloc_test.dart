import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/bloc/video_comment_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoBloc Tests', () {
    late AppVideoDetailRepository detailRepo;
    late VideoBloc videoBloc;

    setUp(() {
      detailRepo = AppVideoDetailRepository();
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
  });

  group('VideoCommentBloc Tests', () {
    late AppVideoCommentRepository commentRepo;
    late VideoCommentBloc commentBloc;

    setUp(() {
      commentRepo = AppVideoCommentRepository();
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
          predicate<VideoCommentState>((s) => s.isLoading && s.videoId == 'test_id'),
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
  });
}
