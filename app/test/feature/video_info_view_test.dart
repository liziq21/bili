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

      // Check Like button semantics & tooltip: label '点赞 3.8万', tooltip '点赞', selected false
      final likeSemanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '点赞 3.8万',
      );
      final likeSemantics = tester.widget<Semantics>(likeSemanticsFinder);
      expect(likeSemantics.properties.label, '点赞 3.8万');
      expect(likeSemantics.properties.tooltip, '点赞');
      expect(likeSemantics.properties.selected, false);
      expect(
        find.ancestor(
          of: likeSemanticsFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == '点赞',
          ),
        ),
        findsOneWidget,
      );

      // Check Favorite button semantics & tooltip: label '收藏 1.2万', tooltip '取消收藏', selected true
      final favoriteSemanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '收藏 1.2万',
      );
      final favoriteSemantics = tester.widget<Semantics>(
        favoriteSemanticsFinder,
      );
      expect(favoriteSemantics.properties.label, '收藏 1.2万');
      expect(favoriteSemantics.properties.tooltip, '取消收藏');
      expect(favoriteSemantics.properties.selected, true);
      expect(
        find.ancestor(
          of: favoriteSemanticsFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == '取消收藏',
          ),
        ),
        findsOneWidget,
      );

      // Check Creator Subscribe button semantics: label '关注创作者 测试UP主', tooltip '关注创作者', selected false
      final subSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '关注创作者 测试UP主',
        ),
      );
      expect(subSemantics.properties.label, '关注创作者 测试UP主');
      expect(subSemantics.properties.tooltip, '关注创作者');
      expect(subSemantics.properties.selected, false);
      // excludeSemantics: true 会吞掉子节点语义动作，必须显式验证
      // 外层节点自身携带 tap 动作（CodeRabbit Major：屏读用户须能触发订阅）
      expect(subSemantics.properties.onTap, isNotNull);

      await mockBloc.close();
    });

    testWidgets(
      'subscribed creator profile exposes updated semantics and tooltip',
      (tester) async {
        final mockDetail = VideoDetail(
          video: const VideoModel(
            id: 'BV1sub',
            url: 'https://example.com/video',
            title: '已关注创作者视频',
            viewCount: 10000,
          ),
          isSubscribed: true,
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

        final subSemantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == '已关注创作者 测试UP主',
          ),
        );
        expect(subSemantics.properties.label, '已关注创作者 测试UP主');
        expect(subSemantics.properties.tooltip, '取消关注创作者');
        expect(subSemantics.properties.selected, true);

        await mockBloc.close();
      },
    );
  });

  group('VideoInfoView list recycling', () {
    testWidgets(
      'the danmaku toggle and the synopsis survive scrolling out of the '
      'cache extent and back',
      (tester) async {
        // A 100px-tall viewport is what makes the test meaningful: the
        // recommendations list then extends far enough that scrolling to the
        // bottom pushes both sections past the ListView's default 250px cache
        // extent. At the default 600px test viewport maxScrollExtent is 226,
        // so the sections are never disposed and the test cannot fail.
        tester.view.physicalSize = const Size(360, 100);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final mockDetail = VideoDetail(
          video: const VideoModel(
            id: 'BV1recycle',
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

        // Put both sections into their non-default state.
        await tester.ensureVisible(find.text('弹幕开', skipOffstage: false));
        await tester.pumpAndSettle();
        await tester.tap(find.text('弹幕开', skipOffstage: false));
        await tester.pumpAndSettle();
        expect(find.text('弹幕关'), findsOneWidget);

        await tester.ensureVisible(find.text('展开完整大纲', skipOffstage: false));
        await tester.pumpAndSettle();
        await tester.tap(find.text('展开完整大纲', skipOffstage: false));
        await tester.pumpAndSettle();
        expect(find.text('收起'), findsOneWidget);

        // Scroll to the bottom. Two drags, because a single one does not
        // always reach maxScrollExtent from wherever the taps left the list.
        await tester.drag(find.byType(ListView), const Offset(0, 5000));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -5000));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -5000));
        await tester.pumpAndSettle();

        // Scroll back. Both sections are rebuilt here; their State must still
        // hold the toggles.
        await tester.drag(find.byType(ListView), const Offset(0, 5000));
        await tester.pumpAndSettle();

        expect(find.text('弹幕关', skipOffstage: false), findsOneWidget);
        expect(find.text('收起', skipOffstage: false), findsOneWidget);

        await mockBloc.close();
      },
    );
  });
}
