import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _MockVideoBloc(super.initialState)
    extends Cubit<VideoState>
    implements VideoBloc {
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

class _RecordingPlaybackController() implements MediaPlaybackController {
  Duration? seekedTo;
  final PlaybackState _state = const PlaybackState(
    isPlaying: false,
    isBuffering: false,
    position: Duration.zero,
    duration: Duration(seconds: 300),
  );

  @override
  PlaybackState get state => _state;

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
      chapters: const [
        VideoChapter(title: '第一章', startSeconds: 0),
        VideoChapter(title: '总结', startSeconds: 83),
      ],
    );
  });

  testWidgets('renders chapters with Tooltip and Semantics', (tester) async {
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
    expect(find.text('第一章'), findsOneWidget);
    expect(find.text('总结'), findsOneWidget);

    // Verify Tooltip widget exists with expected message
    final tooltipWidget = tester.widget(
      find.ancestor(of: find.text('总结'), matching: find.byType(Tooltip)),
    ) as Tooltip;
    expect(tooltipWidget.message, '1:23 总结');

    // Verify Semantics widget with button: true and label
    final semanticsWidget = tooltipWidget.child as Semantics;
    expect(semanticsWidget.properties.button, isTrue);
    expect(semanticsWidget.properties.label, '1:23 总结');
  });

  testWidgets('tapping chapter item triggers playback seek', (tester) async {
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

    await tester.tap(find.text('总结'));
    await tester.pump();

    expect(controller.seekedTo, const Duration(seconds: 83));
  });
}
