import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class MockVideoBloc(super.initialState)
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
          creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
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
        expect(
          find.ancestor(
            of: expandFinder,
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );

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

    testWidgets('action buttons expose semantic action names and tooltips', (
      tester,
    ) async {
      final mockDetail = VideoDetail(
        video: const VideoModel(
          id: 'BV1action',
          url: 'https://example.com/video',
          title: '测试动作条视频',
          viewCount: 10000,
        ),
        likeCount: 38000,
        favoriteCount: 12000,
        shareCount: 520,
        isLiked: false,
        isFavorited: true,
        creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
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

      // Check Like button semantics: label '点赞 3.8万', tooltip '点赞', selected false
      final likeSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '点赞 3.8万',
        ),
      );
      expect(likeSemantics.properties.label, '点赞 3.8万');
      expect(likeSemantics.properties.tooltip, '点赞');
      expect(likeSemantics.properties.selected, false);

      // Check Favorite button semantics: label '收藏 1.2万', tooltip '取消收藏', selected true
      final favoriteSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '收藏 1.2万',
        ),
      );
      expect(favoriteSemantics.properties.label, '收藏 1.2万');
      expect(favoriteSemantics.properties.tooltip, '取消收藏');
      expect(favoriteSemantics.properties.selected, true);

      await mockBloc.close();
    });
  });
}
