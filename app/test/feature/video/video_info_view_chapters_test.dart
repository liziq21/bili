import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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

class _RecordingPlaybackController implements MediaPlaybackController {
  Duration? seekedTo;
  final MediaPlaybackState _state = const MediaPlaybackState(
    duration: Duration(seconds: 300),
  );

  @override
  MediaPlaybackState get state => _state;

  @override
  Future<void> seek(Duration position) async {
    seekedTo = position;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

void main() {
  late VideoDetail detail;

  setUp(() {
    detail = VideoDetail(
      video: VideoModel(
        id: 'BV1main',
        url: 'https://example.com/main',
        title: '测试视频',
      ),
      chapters: [
        VideoChapter(title: '开场介绍', startSeconds: 0),
        VideoChapter(title: '核心架构拆解', startSeconds: 83),
      ],
    );
  });

  testWidgets(
    'renders chapter items with Tooltip and Semantics accessibility button label',
    (tester) async {
      final mockBloc = _MockVideoBloc(
        VideoState(isLoading: false, videoDetail: detail),
      );
      addTearDown(mockBloc.close);
      final controller = _RecordingPlaybackController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                BlocProvider<VideoBloc>.value(value: mockBloc),
                Provider<MediaPlaybackController>.value(value: controller),
              ],
              child: const VideoInfoView(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('章节'), findsOneWidget);
      expect(find.text('开场介绍'), findsOneWidget);
      expect(find.text('核心架构拆解'), findsOneWidget);

      // Verify Tooltip widget exists
      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(of: find.text('核心架构拆解'), matching: find.byType(Tooltip))
            .first,
      );
      expect(tooltip.message, '01:23 核心架构拆解');

      // Verify Semantics widget with button: true and excludeSemantics: true
      final semanticsFinder = find
          .ancestor(of: find.text('核心架构拆解'), matching: find.byType(Semantics))
          .first;
      final semantics = tester.widget<Semantics>(semanticsFinder);
      expect(semantics.button, isTrue);
      expect(semantics.properties.label, '01:23 核心架构拆解');
      expect(semantics.excludeSemantics, isTrue);
    },
  );

  testWidgets(
    'tapping chapter item triggers playback seek to target position',
    (tester) async {
      final mockBloc = _MockVideoBloc(
        VideoState(isLoading: false, videoDetail: detail),
      );
      addTearDown(mockBloc.close);
      final controller = _RecordingPlaybackController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                BlocProvider<VideoBloc>.value(value: mockBloc),
                Provider<MediaPlaybackController>.value(value: controller),
              ],
              child: const VideoInfoView(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('核心架构拆解'));
      await tester.pump();

      expect(controller.seekedTo, const Duration(seconds: 83));
    },
  );
}
