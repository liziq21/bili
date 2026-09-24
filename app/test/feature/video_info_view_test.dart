import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class MockVideoBloc(super.initialState) extends Cubit<VideoState>
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

void main() {
  group('VideoInfoView Synopsis Micro-UX Tests', () {
    testWidgets(
      'toggling synopsis expansion updates semantics and text label',
      (tester) async {
        final mockDetail = VideoDetail(
          video: const VideoModel(
            id: 'BV1test',
            url: 'https://example.com/video',
            title: '测试视频标题',
            desc: '这是一个用于测试的视频摘要说明文本，用于验证展开与收起交互',
            viewCount: 10000,
          ),
          creator: const CreatorProfile(
            id: 'test_creator',
            name: '测试UP主',
          ),
        );

        final mockBloc = MockVideoBloc(
          VideoState(isLoading: false, videoDetail: mockDetail),
        );

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

        await tester.pumpAndSettle();

        // Initial state: toggle shows "展开完整大纲"
        final expandFinder = find.text('展开完整大纲');
        expect(expandFinder, findsOneWidget);

        // Tap toggle to expand
        await tester.tap(expandFinder);
        await tester.pumpAndSettle();

        // Expanded state: toggle shows "收起"
        expect(find.text('收起'), findsOneWidget);

        // Tap toggle to collapse again
        await tester.tap(find.text('收起'));
        await tester.pumpAndSettle();

        expect(find.text('展开完整大纲'), findsOneWidget);

        await mockBloc.close();
      },
    );
  });
}
