import 'dart:async';

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

  /// 置为 true 时 [getVideoDetail] 返回失败，用于覆盖加载失败态。
  bool failDetail = false;

  final List<(String, bool)> likeCalls = [];
  final List<(String, bool)> favoriteCalls = [];
  final List<(String, bool)> subscribeCalls = [];

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async {
    if (failDetail) {
      return Result.error(Exception('offline'));
    }
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
    return Result.success(detail);
  }

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async {
    likeCalls.add((id, isLiked));
    return Result.success(isLiked);
  }

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async {
    favoriteCalls.add((id, isFavorited));
    return Result.success(isFavorited);
  }

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async {
    subscribeCalls.add((creatorId, isSubscribed));
    return Result.success(isSubscribed);
  }
}

class _FailingStreamDataSource() extends MediaStreamRemoteDataSource {
  @override
  String get sourceId => 'failing-stream';

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.error(Exception('stream offline'));
}

/// 按 id 分别挂起的详情数据源：让测试决定哪个请求先返回。
class _PendingDetailDataSource() extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'pending';

  final pending = <String, Completer<Result<VideoDetail, Exception>>>{};

  /// 永不完成的数据源，用于覆盖超时。
  bool hang = false;

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) {
    if (hang) return Completer<Result<VideoDetail, Exception>>().future;
    final completer = Completer<Result<VideoDetail, Exception>>();
    pending[id] = completer;
    return completer.future;
  }

  void complete(String id) {
    pending[id]!.complete(
      Result.success(
        VideoDetail(
          video: VideoModel(
            id: id,
            title: 'Detail $id',
            url: 'https://example.com/$id',
          ),
        ),
      ),
    );
  }
}

/// Loads a normal detail but reports every write as rejected, which is the
/// case the toggle handlers currently swallow.
class _RejectingVideoDetailRemoteDataSource()
    extends VideoDetailRemoteDataSource {
  @override
  String get sourceId => 'rejecting';

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async {
    final video = VideoModel(
      id: id,
      title: 'Test Video Title $id',
      url: 'https://example.com/$id',
    );
    final creator = CreatorProfile(id: 'creator_1', name: 'Creator 1');
    return Result.success(
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
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('rejected'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('rejected'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('rejected'));
}

class FakeVideoCommentRemoteDataSource() extends VideoCommentRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final comment = VideoComment(
      id: 'c1',
      authorName: 'User 1',
      content: 'Comment 1',
      replies: [
        VideoComment(id: 'r1', authorName: 'Reply 1', content: 'Preview reply'),
      ],
      replyCount: 3,
    );
    return Result.success(
      Page<VideoComment>(number: page, totalPages: 2, data: [comment]),
    );
  }
}

/// 首屏评论永不返回，用于覆盖超时。
class _HangingVideoCommentRemoteDataSource()
    extends VideoCommentRemoteDataSource {
  @override
  String get sourceId => 'hanging';

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) => Completer<Result<Page<VideoComment>, Exception>>().future;
}

class FakeVideoCommentRepliesRemoteDataSource()
    extends VideoCommentRepliesRemoteDataSource {
  @override
  String get sourceId => 'fake';

  final calls = <(String, String, int, int)>[];

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoCommentReplies(
    String videoId,
    String rootCommentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    calls.add((videoId, rootCommentId, page, pageSize));
    return Result.success(
      Page<VideoComment>(
        number: page,
        totalPages: 2,
        data: [
          if (page == 1)
            VideoComment(
              id: 'r1',
              authorName: 'Reply 1',
              content: 'Preview reply',
            ),
          if (page == 1)
            VideoComment(id: 'r2', authorName: 'Reply 2', content: 'Reply 2')
          else
            VideoComment(id: 'r3', authorName: 'Reply 3', content: 'Reply 3'),
        ],
      ),
    );
  }
}

class _SwitchingVideoCommentRepository() implements VideoCommentRepository {
  final staleResult = Completer<Result<Page<VideoComment>, Exception>>();

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  }) {
    if (videoId == 'old') return staleResult.future;
    return Future.value(
      Result.success(
        Page<VideoComment>(
          number: page,
          totalPages: 1,
          data: [
            VideoComment(id: 'new-comment', authorName: 'New', content: 'new'),
          ],
        ),
      ),
    );
  }

  @override
  Future<Result<Page<VideoComment>, Exception>> getVideoCommentReplies(
    String videoId,
    String rootCommentId, {
    int page = 1,
    int pageSize = 20,
  }) async => Result.error(Exception('unused'));
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
      // copyWith 对三个错误字段都是「不传即保留，传 null 才清空」：详情、
      // 播放地址与写操作各自 emit，任何一次 emit 都不该顺手清掉别人的失败原因。
      expect(base.copyWith(isLoading: true).actionError, isNull);
      expect(base.copyWith(actionError: '点赞失败').actionError, '点赞失败');
      expect(
        base
            .copyWith(actionError: '点赞失败')
            .copyWith(isLoading: true)
            .actionError,
        '点赞失败',
      );
      expect(
        base
            .copyWith(actionError: '点赞失败')
            .copyWith(actionError: null)
            .actionError,
        isNull,
      );
    });

    test('LoadVideoDetail loads video detail successfully', () async {
      videoBloc.add(const LoadVideoDetail('test_id'));

      await expectLater(
        videoBloc.stream,
        emitsInOrder([
          const VideoState(isLoading: true, videoId: 'test_id'),
          predicate<VideoState>((state) {
            return !state.isLoading &&
                state.videoDetail != null &&
                state.videoDetail!.video.id == 'test_id';
          }),
        ]),
      );
    });

    test(
      'a detail retry keeps the stream error so the player keeps its retry',
      () async {
        // 详情与播放地址是两个独立请求。详情重试若把 streamError 清掉，
        // 播放器既没有地址也没有错误，只会一直转圈且没有重试入口。
        final bloc = VideoBloc(
          repository: AppVideoDetailRepository(
            fakeDataSource,
            _FailingStreamDataSource(),
          ),
        );
        addTearDown(bloc.close);

        bloc.add(const LoadMediaStream('BV1stream'));
        await bloc.stream.firstWhere((s) => s.streamError != null);

        fakeDataSource.failDetail = true;
        bloc.add(const LoadVideoDetail('BV1stream'));
        await bloc.stream.firstWhere((s) => s.error != null);

        fakeDataSource.failDetail = false;
        bloc.add(const LoadVideoDetail('BV1stream'));
        final recovered = await bloc.stream.firstWhere(
          (s) => s.videoDetail != null,
        );

        expect(recovered.error, isNull);
        expect(recovered.streamError, isNotNull);
      },
    );

    test(
      'a failed load keeps the video id so the error state can retry',
      () async {
        fakeDataSource.failDetail = true;

        videoBloc.add(const LoadVideoDetail('BV1retry'));

        await expectLater(
          videoBloc.stream,
          emitsInOrder([
            const VideoState(isLoading: true, videoId: 'BV1retry'),
            predicate<VideoState>(
              (state) =>
                  !state.isLoading &&
                  state.error != null &&
                  state.videoId == 'BV1retry',
            ),
          ]),
        );
      },
    );

    test('an older detail response never overwrites a newer one', () async {
      final source = _PendingDetailDataSource();
      final bloc = VideoBloc(repository: AppVideoDetailRepository(source));
      addTearDown(bloc.close);

      bloc.add(const LoadVideoDetail('BV1old'));
      await pumpEventQueue();
      bloc.add(const LoadVideoDetail('BV1new'));
      await pumpEventQueue();

      // 新请求先返回，旧请求后返回：旧结果必须被丢弃。
      source.complete('BV1new');
      await pumpEventQueue();
      source.complete('BV1old');
      await pumpEventQueue();

      expect(bloc.state.videoId, 'BV1new');
      expect(bloc.state.videoDetail?.video.id, 'BV1new');
      expect(bloc.state.error, isNull);
    });

    test(
      'a detail request that never completes ends in a retryable error',
      () async {
        final source = _PendingDetailDataSource()..hang = true;
        final bloc = VideoBloc(
          repository: AppVideoDetailRepository(source),
          detailTimeout: const Duration(milliseconds: 20),
        );
        addTearDown(bloc.close);

        bloc.add(const LoadVideoDetail('BV1hang'));

        final failed = await bloc.stream.firstWhere((s) => s.error != null);
        expect(failed.isLoading, isFalse);
        // 保留 videoId，错误态才有可用的重试目标。
        expect(failed.videoId, 'BV1hang');
      },
    );

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
        expect(result.isError(), isTrue);
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
    late FakeVideoCommentRepliesRemoteDataSource repliesDataSource;

    setUp(() {
      repliesDataSource = FakeVideoCommentRepliesRemoteDataSource();
      commentRepo = AppVideoCommentRepository(
        FakeVideoCommentRemoteDataSource(),
        repliesDataSource,
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

    test('a comment request that never completes ends in an error', () async {
      final bloc = VideoCommentBloc(
        repository: AppVideoCommentRepository(
          _HangingVideoCommentRemoteDataSource(),
        ),
        loadTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(bloc.close);

      bloc.add(const LoadVideoComments('BV1hang'));

      final failed = await bloc.stream.firstWhere((s) => s.error != null);
      expect(failed.isLoading, isFalse);
      expect(failed.videoId, 'BV1hang');
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

    test('ignores a comment response from a previous video', () async {
      final repository = _SwitchingVideoCommentRepository();
      final bloc = VideoCommentBloc(repository: repository);
      addTearDown(bloc.close);

      bloc.add(const LoadVideoComments('old'));
      await bloc.stream.firstWhere(
        (state) => state.isLoading && state.videoId == 'old',
      );

      bloc.add(const LoadVideoComments('new'));
      await bloc.stream.firstWhere(
        (state) => !state.isLoading && state.videoId == 'new',
      );

      repository.staleResult.complete(
        Result.success(
          Page<VideoComment>(
            number: 1,
            totalPages: 1,
            data: [
              VideoComment(id: 'stale', authorName: 'Old', content: 'old'),
            ],
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.videoId, 'new');
      expect(bloc.state.comments.single.id, 'new-comment');
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
      'expanding replies keeps the preview and loads the first page',
      () async {
        commentBloc.add(const LoadVideoComments('test_id'));
        await commentBloc.stream.firstWhere((s) => !s.isLoading);

        commentBloc.add(const ToggleCommentReplies('c1'));
        await commentBloc.stream.firstWhere(
          (s) => s.replyStates['c1']?.hasLoaded == true,
        );

        final replies = commentBloc.state.replyStates['c1']!;
        expect(replies.isExpanded, isTrue);
        expect(replies.replies.map((reply) => reply.id), ['r1', 'r2']);
        expect(repliesDataSource.calls, [('test_id', 'c1', 1, 20)]);
      },
    );

    test(
      'reply pagination is keyed by root comment and deduplicates previews',
      () async {
        commentBloc.add(const LoadVideoComments('test_id'));
        await commentBloc.stream.firstWhere((s) => !s.isLoading);
        commentBloc.add(const ToggleCommentReplies('c1'));
        await commentBloc.stream.firstWhere(
          (s) => s.replyStates['c1']?.hasLoaded == true,
        );

        commentBloc.add(const FetchNextCommentRepliesPage('c1'));
        await commentBloc.stream.firstWhere(
          (s) => s.replyStates['c1']?.currentPage == 2,
        );

        final replies = commentBloc.state.replyStates['c1']!;
        expect(replies.replies.map((reply) => reply.id), ['r1', 'r2', 'r3']);
        expect(repliesDataSource.calls, [
          ('test_id', 'c1', 1, 20),
          ('test_id', 'c1', 2, 20),
        ]);
      },
    );

    test(
      'collapsing replies keeps the loaded state for the next expansion',
      () async {
        commentBloc.add(const LoadVideoComments('test_id'));
        await commentBloc.stream.firstWhere((s) => !s.isLoading);
        commentBloc.add(const ToggleCommentReplies('c1'));
        await commentBloc.stream.firstWhere(
          (s) => s.replyStates['c1']?.hasLoaded == true,
        );

        commentBloc.add(const ToggleCommentReplies('c1'));
        await commentBloc.stream.firstWhere(
          (s) => s.replyStates['c1']?.isExpanded == false,
        );

        final replies = commentBloc.state.replyStates['c1']!;
        expect(replies.replies, hasLength(2));
        expect(replies.hasLoaded, isTrue);
        expect(repliesDataSource.calls, [('test_id', 'c1', 1, 20)]);
      },
    );

    test(
      'AppVideoCommentRepository returns error when no remote data source',
      () async {
        final repoWithoutSource = AppVideoCommentRepository();
        final result = await repoWithoutSource.getVideoComments('test_id');
        expect(result.isError(), isTrue);
      },
    );
  });
}
