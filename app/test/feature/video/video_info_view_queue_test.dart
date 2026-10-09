import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

/// 「加入播放队列」按钮路径的 widget 测试。
///
/// 该路径在 65fc58d 落地但无测试覆盖：卡片按钮调用
/// [QueueAddController.addVideoToQueue]，由 [VideoScreen] 提供的闭包把
/// videoId 解析为 [MediaStream] 再追加到 [MediaPlaybackController]。
/// 此处覆盖解析成功 / 解析失败 / 无 QueueAddController 三条分支。
/// 供本测试使用的假 bloc：构造即给出含 relatedVideos 的详情状态。
class _MockVideoBloc extends Cubit<VideoState> implements VideoBloc {
  _MockVideoBloc(super.initialState);

  @override
  void add(VideoEvent event) {}

  @override
  void on<E extends VideoEvent>(
    EventHandler<E, VideoState> handler, {
    EventTransformer<E>? transformer,
  }) {}

  @override
  void onDone(VideoEvent event, [Object? error, StackTrace? stackTrace]) {}

  @override
  void onEvent(VideoEvent event) {}

  @override
  void onTransition(Transition<VideoEvent, VideoState> transition) {}
}

void main() {
  late MediaStream queueStream;
  late VideoDetail detail;

  setUp(() {
    queueStream = MediaStream(
      videoUrl: 'https://cdn.example.com/related.m4s',
      headers: {'Referer': 'https://www.bilibili.com'},
    );

    detail = VideoDetail(
      video: VideoModel(
        id: 'BV1main',
        url: 'https://example.com/main',
        title: '当前视频',
      ),
      relatedVideos: [
        VideoModel(
          id: 'BV1related',
          url: 'https://example.com/related',
          title: '关联视频',
          creatorProfileName: '测试 UP 主',
          viewCount: 10000,
          duration: 754,
        ),
      ],
    );
  });

  /// pump 出带 QueueAddController 与 MediaPlaybackController 的页面。
  /// addVideoToQueue 的实现照搬 video_screen.dart 的闭包，使测试穿过
  /// 真实的解析→追加链路，而不是另写一份逻辑。
  Future<void> pumpWithQueue(
    WidgetTester tester, {
    required Result<MediaStream> streamResult,
    required _RecordingPlaybackController controller,
  }) async {
    final mockBloc = _MockVideoBloc(
      VideoState(isLoading: false, videoDetail: detail),
    );
    addTearDown(mockBloc.close);

    // 假 repository 只实现 getMediaStream，闭包照搬 video_screen.dart 的写法，
    // 使测试穿过真实的「解析 → 追加 → 反馈」链路。生产代码里
    // RepositoryProvider<VideoDetailRepository> 由 service_source_providers
    // 在页面之上提供，此处对齐该层级。
    final repository = _QueueTestRepository(streamResult: streamResult);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              BlocProvider<VideoBloc>.value(value: mockBloc),
              RepositoryProvider<VideoDetailRepository>.value(
                value: repository,
              ),
              Provider<MediaPlaybackController>.value(value: controller),
            ],
            child: QueueAddController(
              addVideoToQueue: (videoId, repo, playback) async {
                final result = await repo.getMediaStream(videoId);
                switch (result) {
                  case Ok(:final value):
                    await playback.addToQueue(value);
                    return true;
                  case Error():
                    return false;
                }
              },
              child: const VideoInfoView(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders one add button per related video', (tester) async {
    await pumpWithQueue(
      tester,
      streamResult: Result.ok(queueStream),
      controller: _RecordingPlaybackController(),
    );

    expect(find.text('关联视频'), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
  });

  testWidgets('the button resolves and appends the stream on tap', (
    tester,
  ) async {
    final controller = _RecordingPlaybackController();

    await pumpWithQueue(
      tester,
      streamResult: Result.ok(queueStream),
      controller: controller,
    );

    await tester.tap(find.byIcon(Icons.playlist_add));
    // 只推进到 SnackBar 出现。$styles.times.fast 在禁用动画的测试环境下是 1ms，
    // pumpAndSettle 会跨过整个显示窗口，反馈一闪即逝无法断言。
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.added, hasLength(1));
    expect(controller.added.single.videoUrl, queueStream.videoUrl);
    expect(find.text('已加入播放队列'), findsOneWidget);
  });

  testWidgets('a resolution failure surfaces as a failure message', (
    tester,
  ) async {
    final controller = _RecordingPlaybackController();

    await pumpWithQueue(
      tester,
      streamResult: Result.error(Exception('地址解析失败')),
      controller: controller,
    );

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.added, isEmpty);
    expect(find.text('加入队列失败'), findsOneWidget);
  });

  testWidgets('the add button stays hidden without a QueueAddController', (
    tester,
  ) async {
    final mockBloc = _MockVideoBloc(
      VideoState(isLoading: false, videoDetail: detail),
    );
    addTearDown(mockBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: mockBloc,
            child: const VideoInfoView(),
          ),
        ),
      ),
    );
    await tester.pump();

    // 关联卡片仍渲染，但没有可点的加入入口。
    expect(find.text('关联视频'), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add), findsNothing);
  });
}

class _QueueTestRepository implements VideoDetailRepository {
  _QueueTestRepository({required this.streamResult});

  final Result<MediaStream> streamResult;

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
  }) async {
    return streamResult;
  }

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => throw UnimplementedError();
}

/// 记录追加动作，不触碰原生播放库。
class _RecordingPlaybackController implements MediaPlaybackController {
  final List<MediaStream> added = [];

  @override
  Future<void> addToQueue(MediaStream stream) async => added.add(stream);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
