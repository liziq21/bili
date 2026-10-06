import 'package:app/data/repository/video_comment_repository.dart';
import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/bloc/video_comment_bloc.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class FakeVideoDetailRemoteDataSource() extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  final List<(String, bool)> likeCalls = [];
  final List<(String, bool)> favoriteCalls = [];
  final List<(String, bool)> subscribeCalls = [];

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    final video = VideoModel(
      id: id,
      title: 'Test Video Title $id',
      url: 'https://example.com/$id',
    );
    final creator = CreatorProfile(id: 'creator_1', name: 'Creator 1');
    final detail = VideoDetail(
      video: video,
      creator: creator,
      likeCount: 10,
      favoriteCount: 5,
      isLiked: false,
      isFavorited: false,
      isSubscribed: false,
    );
    return Result.ok(detail);
  }

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async {
    likeCalls.add((id, isLiked));
    return Result.ok(isLiked);
  }

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async {
    favoriteCalls.add((id, isFavorited));
    return Result.ok(isFavorited);
  }

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async {
    subscribeCalls.add((creatorId, isSubscribed));
    return Result.ok(isSubscribed);
  }
}

/// Loads a normal detail but reports every write as rejected, which is the
/// case the toggle handlers currently swallow.
class _RejectingVideoDetailRemoteDataSource()
    extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'rejecting';

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async {
    final video = VideoModel(
      id: id,
      title: 'Test Video Title $id',
      url: 'https://example.com/$id',
    );
    final creator = CreatorProfile(id: 'creator_1', name: 'Creator 1');
    return Result.ok(
      VideoDetail(
        video: video,
        creator: creator,
        likeCount: 10,
        favoriteCount: 5,
        isLiked: false,
        isFavorited: false,
        isSubscribed: false,
      ),
    );
  }

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('rejected'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('rejected'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('rejected'));
}

class FakeVideoCommentRemoteDataSource() extends VideoCommentRemoteDataSource {
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
      Page<VideoComment>(number: page, totalPages: 2, data: [comment]),
    );
  }
}

void main() {
  group('VideoBloc Tests', () {
    late FakeVideoDetailRemoteDataSource fakeDataSource;
    late AppVideoDetailRepository detailRepo;
    late VideoBloc videoBloc;

    setUp(() {
      fakeDataSource = FakeVideoDetailRemoteDataSource();
      detailRepo = AppVideoDetailRepository(fakeDataSource);
      videoBloc = VideoBloc(repository: detailRepo);
    });

    tearDown(() {
      videoBloc.close();
    });

    test('Initial state is correct', () {
      expect(videoBloc.state, const VideoState());
    });

    test('actionError participates in equality', () {
      // Equatable 按 props 去重：actionError 若不在 props 里，两次相同的失败
      // 会被判为同一个状态，BlocListener 的 listenWhen 收不到第二次变化，
      // 用户连点两次点赞只会看到第一次的提示。
      const base = VideoState();

      expect(base, const VideoState());
      expect(base, isNot(const VideoState(actionError: '点赞失败')));
      // copyWith 对 actionError 是「无条件赋值」而非「null 保留」：不传即清空。
      // 这是既有 error 字段的同一形态，bloc 的回滚 emit 每次都显式带上消息，
      // 所以这里记录下来，避免后来者以为它是保留语义。
      expect(base.copyWith(isLoading: true).actionError, isNull);
      expect(base.copyWith(actionError: '点赞失败').actionError, '点赞失败');
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

    test(
      'ToggleVideoLike passes updated isLiked value to repository',
      () async {
        videoBloc.add(const LoadVideoDetail('test_id'));
        await videoBloc.stream.firstWhere((s) => !s.isLoading);

        final initialLikeCount = videoBloc.state.videoDetail!.likeCount;
        videoBloc.add(const ToggleVideoLike());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isLiked == true &&
                  state.videoDetail!.likeCount == initialLikeCount + 1;
            }),
          ),
        );

        expect(fakeDataSource.likeCalls, equals([('test_id', true)]));

        videoBloc.add(const ToggleVideoLike());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isLiked == false &&
                  state.videoDetail!.likeCount == initialLikeCount;
            }),
          ),
        );

        expect(
          fakeDataSource.likeCalls,
          equals([('test_id', true), ('test_id', false)]),
        );
      },
    );

    test(
      'ToggleVideoFavorite passes updated isFavorited value to repository',
      () async {
        videoBloc.add(const LoadVideoDetail('test_id'));
        await videoBloc.stream.firstWhere((s) => !s.isLoading);

        final initialFavCount = videoBloc.state.videoDetail!.favoriteCount;
        videoBloc.add(const ToggleVideoFavorite());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isFavorited == true &&
                  state.videoDetail!.favoriteCount == initialFavCount + 1;
            }),
          ),
        );

        expect(fakeDataSource.favoriteCalls, equals([('test_id', true)]));

        videoBloc.add(const ToggleVideoFavorite());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isFavorited == false &&
                  state.videoDetail!.favoriteCount == initialFavCount;
            }),
          ),
        );

        expect(
          fakeDataSource.favoriteCalls,
          equals([('test_id', true), ('test_id', false)]),
        );
      },
    );

    test(
      'ToggleCreatorSubscribe passes updated isSubscribed value to repository',
      () async {
        videoBloc.add(const LoadVideoDetail('test_id'));
        await videoBloc.stream.firstWhere((s) => !s.isLoading);

        videoBloc.add(const ToggleCreatorSubscribe());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isSubscribed == true;
            }),
          ),
        );

        expect(fakeDataSource.subscribeCalls, equals([('creator_1', true)]));

        videoBloc.add(const ToggleCreatorSubscribe());

        await expectLater(
          videoBloc.stream,
          emits(
            predicate<VideoState>((state) {
              return state.videoDetail!.isSubscribed == false;
            }),
          ),
        );

        expect(
          fakeDataSource.subscribeCalls,
          equals([('creator_1', true), ('creator_1', false)]),
        );
      },
    );

    test(
      'AppVideoDetailRepository returns error when no remote data source',
      () async {
        final repoWithoutSource = AppVideoDetailRepository();
        final result = await repoWithoutSource.getVideoDetail('test_id');
        expect(result.isError, isTrue);
      },
    );

    // A failed write must roll the optimistic update back. These handlers used
    // to discard the `Result` the repository returned, so a rejected like left
    // the button lit and the count inflated with nothing persisted and no
    // message shown. They also used to report the failure through `error`, but
    // that field drives the full-page "load failed" replacement in
    // VideoInfoView; a write failure has to use `actionError` instead or the
    // user is shown a load error for an action that succeeded in loading.
    test(
      'a failed ToggleVideoLike rolls back and reports actionError',
      () async {
        final rejecting = _RejectingVideoDetailRemoteDataSource();
        final bloc = VideoBloc(repository: AppVideoDetailRepository(rejecting));
        addTearDown(bloc.close);

        bloc.add(const LoadVideoDetail('test_id'));
        await bloc.stream.firstWhere((s) => !s.isLoading);
        final loaded = bloc.state.videoDetail!;

        bloc.add(const ToggleVideoLike());
        // The optimistic state does land first, so a listener can react instantly.
        await expectLater(
          bloc.stream,
          emits(predicate<VideoState>((s) => s.videoDetail!.isLiked == true)),
        );

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.videoDetail!.isLiked, isFalse);
        expect(bloc.state.videoDetail!.likeCount, loaded.likeCount);
        expect(bloc.state.actionError, isNotNull);
        // The load-failure channel must stay clean, or the whole detail page is
        // replaced by "视频加载失败" for a failed like.
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'a failed ToggleVideoFavorite rolls back and reports actionError',
      () async {
        final rejecting = _RejectingVideoDetailRemoteDataSource();
        final bloc = VideoBloc(repository: AppVideoDetailRepository(rejecting));
        addTearDown(bloc.close);

        bloc.add(const LoadVideoDetail('test_id'));
        await bloc.stream.firstWhere((s) => !s.isLoading);
        final loaded = bloc.state.videoDetail!;

        bloc.add(const ToggleVideoFavorite());
        await expectLater(
          bloc.stream,
          emits(
            predicate<VideoState>((s) => s.videoDetail!.isFavorited == true),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.videoDetail!.isFavorited, isFalse);
        expect(bloc.state.videoDetail!.favoriteCount, loaded.favoriteCount);
        expect(bloc.state.actionError, isNotNull);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'a failed ToggleCreatorSubscribe rolls back and reports actionError',
      () async {
        final rejecting = _RejectingVideoDetailRemoteDataSource();
        final bloc = VideoBloc(repository: AppVideoDetailRepository(rejecting));
        addTearDown(bloc.close);

        bloc.add(const LoadVideoDetail('test_id'));
        await bloc.stream.firstWhere((s) => !s.isLoading);

        bloc.add(const ToggleCreatorSubscribe());
        await expectLater(
          bloc.stream,
          emits(
            predicate<VideoState>((s) => s.videoDetail!.isSubscribed == true),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.videoDetail!.isSubscribed, isFalse);
        expect(bloc.state.actionError, isNotNull);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'a rejected write clears the previous actionError on the next toggle',
      () async {
        final rejecting = _RejectingVideoDetailRemoteDataSource();
        final bloc = VideoBloc(repository: AppVideoDetailRepository(rejecting));
        addTearDown(bloc.close);

        bloc.add(const LoadVideoDetail('test_id'));
        await bloc.stream.firstWhere((s) => !s.isLoading);

        bloc.add(const ToggleVideoLike());
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.actionError, isNotNull);

        // The next optimistic emit must not carry the stale message forward,
        // otherwise a later successful toggle still shows the old failure.
        bloc.add(const ToggleVideoLike());
        await expectLater(
          bloc.stream,
          emits(
            predicate<VideoState>(
              (s) => s.videoDetail!.isLiked == true && s.actionError == null,
            ),
          ),
        );
      },
    );
  });

  group('VideoCommentBloc Tests', () {
    late AppVideoCommentRepository commentRepo;
    late VideoCommentBloc commentBloc;

    setUp(() {
      commentRepo = AppVideoCommentRepository(
        FakeVideoCommentRemoteDataSource(),
      );
      commentBloc = VideoCommentBloc(repository: commentRepo);
    });

    tearDown(() {
      commentBloc.close();
    });

    test('Initial state is correct', () {
      expect(commentBloc.state, const VideoCommentState());
    });

    test('copyWith preserves error unless explicitly cleared', () {
      const state = VideoCommentState(error: 'old error');

      expect(state.copyWith(isLoading: true).error, 'old error');
      expect(state.copyWith(error: null).error, isNull);
      expect(
        () => state.copyWith(error: const Object()),
        throwsA(isA<TypeError>()),
      );
    });

    test('LoadVideoComments fetches first page of comments', () async {
      commentBloc.add(const LoadVideoComments('test_id'));

      await expectLater(
        commentBloc.stream,
        emitsInOrder([
          predicate<VideoCommentState>(
            (s) => s.isLoading && s.videoId == 'test_id',
          ),
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
        emits(
          predicate<VideoCommentState>((s) {
            final target = s.comments.firstWhere(
              (c) => c.id == targetCommentId,
            );
            return target.isLiked == true;
          }),
        ),
      );
    });

    test(
      'AppVideoCommentRepository returns error when no remote data source',
      () async {
        final repoWithoutSource = AppVideoCommentRepository();
        final result = await repoWithoutSource.getVideoComments('test_id');
        expect(result.isError, isTrue);
      },
    );
  });
}
