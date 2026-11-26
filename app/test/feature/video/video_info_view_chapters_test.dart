import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _MockVideoBloc(super.initialState)
    extends Cubit<VideoState>
    implements VideoBloc {
  @override
  final Duration detailTimeout = const Duration(seconds: 30);

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

class _RecordingPlaybackController([
  final Duration duration = const Duration(seconds: 300),
]) implements MediaPlaybackController {
  this
    : _state = PlaybackState(
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
        duration: duration,
      );

  Duration? seekedTo;
  final StreamController<PlaybackState> _states =
      StreamController<PlaybackState>.broadcast();
  PlaybackState _state;

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get states => _states.stream;

  /// 模拟播放器在打开媒体后把时长告诉 UI。
  void emitDuration(Duration value) {
    _state = PlaybackState(
      isPlaying: false,
      isBuffering: false,
      position: Duration.zero,
      duration: value,
    );
    _states.add(_state);
  }

  @override
  Future<void> dispose() => _states.close();

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
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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

  testWidgets('a chapter item seeks from a screen-reader tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final mockBloc = _MockVideoBloc(
      VideoState(isLoading: false, videoDetail: detail),
    );
    addTearDown(mockBloc.close);
    final controller = _RecordingPlaybackController();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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

    final node = tester.getSemantics(find.bySemanticsLabel('1:23 总结'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(controller.seekedTo, const Duration(seconds: 83));
    semantics.dispose();
  });

  testWidgets('chapters expose no tap action until the duration is known', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final mockBloc = _MockVideoBloc(
      VideoState(isLoading: false, videoDetail: detail),
    );
    addTearDown(mockBloc.close);
    final controller = _RecordingPlaybackController(Duration.zero);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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

    final node = tester.getSemantics(find.bySemanticsLabel('1:23 总结'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    await tester.tap(find.text('总结'));
    await tester.pump();

    expect(controller.seekedTo, isNull);
    semantics.dispose();
  });

  testWidgets('a chapter becomes tappable once the duration arrives', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final mockBloc = _MockVideoBloc(
      VideoState(isLoading: false, videoDetail: detail),
    );
    addTearDown(mockBloc.close);
    final controller = _RecordingPlaybackController(Duration.zero);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('1:23 总结'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );

    controller.emitDuration(const Duration(seconds: 300));
    // 流事件在下一帧才送达 StreamBuilder。
    await tester.pump();
    await tester.pump();

    final node = tester.getSemantics(find.bySemanticsLabel('1:23 总结'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(controller.seekedTo, const Duration(seconds: 83));
    semantics.dispose();
  });
}
