import 'dart:ui' show SemanticsAction;

import 'package:app/design/design.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class MockVideoBloc(super.initialState)
    extends Cubit<VideoState>
    implements VideoBloc {
  @override
  final Duration detailTimeout = const Duration(seconds: 30);

  /// Events the UI dispatched, so retry buttons can be asserted end to end.
  final List<VideoEvent> dispatched = [];

  @override
  void add(VideoEvent event) => dispatched.add(event);

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
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
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
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
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
            (widget) =>
                widget is Tooltip &&
                widget.message == '点赞' &&
                widget.excludeFromSemantics == true,
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
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
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
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
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

  group('VideoInfoView action error surface', () {
    // A failed like used to be reported through `error`, which drives the
    // full-page "视频加载失败" replacement. The page was already showing the
    // video, so that message was both wrong and destructive. These cases pin
    // the split: `actionError` prompts, it does not replace the page.
    Widget mountWith(VideoBloc bloc) {
      return MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: const VideoInfoView(),
          ),
        ),
      );
    }

    // The like button's visible text is the formatted count, so locate it by
    // its tooltip instead of by label text.
    Finder likeButton() => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.tooltip == '点赞',
    );
    VideoDetail sampleDetail() => VideoDetail(
      video: const VideoModel(
        id: 'BV1test',
        url: 'https://example.com/video',
        title: '测试视频标题',
      ),
      creator: const CreatorProfile(id: 'c1', name: '测试UP主'),
      likeCount: 10,
    );

    testWidgets('actionError shows a prompt without replacing the page', (
      tester,
    ) async {
      final bloc = MockVideoBloc(VideoState(videoDetail: sampleDetail()));
      addTearDown(bloc.close);

      await tester.pumpWidget(mountWith(bloc));
      await tester.pumpAndSettle();

      // A bloc only notifies listeners on a state *transition*: mounting with
      // actionError already set produces no prompt, which is correct (nothing
      // failed during this mount). Drive the failure the way the bloc does.
      bloc.emit(bloc.state.copyWith(actionError: '点赞失败'));
      await tester.pumpAndSettle();

      expect(find.text('点赞失败'), findsOneWidget);
      // The detail is still on screen: the action buttons are still there and
      // the load-failure copy is absent.
      expect(likeButton(), findsOneWidget);
      expect(find.text('视频加载失败，请重试'), findsNothing);
    });

    testWidgets('a repeated identical message still prompts', (tester) async {
      // Two consecutive failures carry the same text. If actionError were not
      // in props, Equatable would collapse the second state into the first and
      // the user would only ever see one prompt.
      final bloc = MockVideoBloc(VideoState(videoDetail: sampleDetail()));
      addTearDown(bloc.close);

      await tester.pumpWidget(mountWith(bloc));
      await tester.pumpAndSettle();

      bloc.emit(bloc.state.copyWith(actionError: '点赞失败'));
      await tester.pumpAndSettle();
      expect(find.text('点赞失败'), findsOneWidget);

      // Clear it, and let the first SnackBar's auto-dismiss timer run out so
      // the second prompt is distinguishable from the first.
      bloc.emit(bloc.state.copyWith(actionError: null));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('点赞失败'), findsNothing);

      bloc.emit(bloc.state.copyWith(actionError: '点赞失败'));
      await tester.pumpAndSettle();
      expect(find.text('点赞失败'), findsOneWidget);
    });

    testWidgets('a null actionError shows no prompt', (tester) async {
      final bloc = MockVideoBloc(VideoState(videoDetail: sampleDetail()));
      addTearDown(bloc.close);

      await tester.pumpWidget(mountWith(bloc));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(likeButton(), findsOneWidget);
    });

    testWidgets('a load error still replaces the page', (tester) async {
      // The load-failure channel keeps its original behaviour; only the write
      // channel was split out.
      final bloc = MockVideoBloc(const VideoState(error: 'boom'));
      addTearDown(bloc.close);

      await tester.pumpWidget(mountWith(bloc));
      await tester.pumpAndSettle();

      expect(find.text('视频加载失败，请重试'), findsOneWidget);
      expect(likeButton(), findsNothing);
      // Without a video id there is nothing to retry, so no dead button.
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('load error retry reloads the same video', (tester) async {
      final bloc = MockVideoBloc(
        const VideoState(error: 'boom', videoId: 'BV1retry'),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(mountWith(bloc));
      await tester.pumpAndSettle();

      // The copy says "try again", so a retry control must exist.
      final retry = find.widgetWithText(OutlinedButton, '重试');
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pump();

      expect(bloc.dispatched, [const LoadVideoDetail('BV1retry')]);
    });
  });

  group('VideoInfoView creator navigation', () {
    testWidgets('tapping the creator block navigates to the space route', (
      tester,
    ) async {
      final detail = VideoDetail(
        video: const VideoModel(
          id: 'BV1nav',
          url: 'https://example.com/nav',
          title: 'UP 主跳转测试',
          viewCount: 100,
        ),
        creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
      );
      final bloc = MockVideoBloc(
        VideoState(isLoading: false, videoDetail: detail),
      );
      addTearDown(bloc.close);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: BlocProvider<VideoBloc>.value(
                value: bloc,
                child: const VideoInfoView(),
              ),
            ),
          ),
          GoRoute(
            path: '/space/:mid',
            builder: (context, state) =>
                Scaffold(body: Text('space:${state.pathParameters['mid']}')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('测试UP主'));
      await tester.pumpAndSettle();

      expect(find.text('space:test_creator'), findsOneWidget);
    });

    testWidgets(
      'renders the collection entry with its title and count when the video has a playlist',
      (tester) async {
        final detail = VideoDetail(
          video: const VideoModel(
            id: 'BV1playlist',
            url: 'https://example.com/video',
            title: '带列表的视频',
          ),
          creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
          playlist: const VideoPlaylistRef(
            id: '42:777',
            title: 'Flutter 播放列表',
            totalCount: 12,
          ),
        );
        final bloc = MockVideoBloc(
          VideoState(isLoading: false, videoDetail: detail),
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: Scaffold(
              body: BlocProvider<VideoBloc>.value(
                value: bloc,
                child: const VideoInfoView(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Flutter 播放列表'), findsOneWidget);
        expect(find.text('12 个视频'), findsOneWidget);
      },
    );

    testWidgets('hides the collection entry when the video has no playlist', (
      tester,
    ) async {
      final detail = VideoDetail(
        video: const VideoModel(
          id: 'BV1noplaylist',
          url: 'https://example.com/video',
          title: '无列表视频',
        ),
        creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
      );
      final bloc = MockVideoBloc(
        VideoState(isLoading: false, videoDetail: detail),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: const VideoInfoView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.playlistPlay), findsNothing);
    });

    testWidgets(
      'tapping the collection entry navigates to the playlist route',
      (tester) async {
        final detail = VideoDetail(
          video: const VideoModel(
            id: 'BV1playlist',
            url: 'https://example.com/video',
            title: '带列表的视频',
          ),
          creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
          playlist: const VideoPlaylistRef(
            id: '42:777',
            title: 'Flutter 播放列表',
            totalCount: 3,
          ),
        );
        final bloc = MockVideoBloc(
          VideoState(isLoading: false, videoDetail: detail),
        );
        addTearDown(bloc.close);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: BlocProvider<VideoBloc>.value(
                  value: bloc,
                  child: const VideoInfoView(),
                ),
              ),
            ),
            GoRoute(
              path: '/playlist/:playlistId',
              builder: (context, state) => Scaffold(
                body: Text('playlist:${state.pathParameters['playlistId']}'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
          ),
        );
        await tester.pumpAndSettle();

        final entry = find.text('Flutter 播放列表');
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();

        expect(find.text('playlist:42:777'), findsOneWidget);
      },
    );

    testWidgets(
      'collection entry exposes a screen-reader tap action that navigates',
      (tester) async {
        final semantics = tester.ensureSemantics();

        final detail = VideoDetail(
          video: const VideoModel(
            id: 'BV1playlist',
            url: 'https://example.com/video',
            title: '带列表的视频',
          ),
          creator: const CreatorProfile(id: 'test_creator', name: '测试UP主'),
          playlist: const VideoPlaylistRef(
            id: '42:777',
            title: 'Flutter 播放列表',
            totalCount: 3,
          ),
        );
        final bloc = MockVideoBloc(
          VideoState(isLoading: false, videoDetail: detail),
        );
        addTearDown(bloc.close);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: BlocProvider<VideoBloc>.value(
                  value: bloc,
                  child: const VideoInfoView(),
                ),
              ),
            ),
            GoRoute(
              path: '/playlist/:playlistId',
              builder: (context, state) => Scaffold(
                body: Text('playlist:${state.pathParameters['playlistId']}'),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
          ),
        );
        await tester.pumpAndSettle();

        final node = tester.getSemantics(
          find.bySemanticsLabel('播放列表: Flutter 播放列表'),
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();

        expect(find.text('playlist:42:777'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('VideoInfoView header stats', () {
    Future<void> pumpHeader(WidgetTester tester, VideoDetail detail) async {
      final bloc = MockVideoBloc(
        VideoState(isLoading: false, videoDetail: detail),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: const VideoInfoView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the counts, date and copyright the API returned', (
      tester,
    ) async {
      // given: a detail carrying every header field
      await pumpHeader(
        tester,
        VideoDetail(
          video: VideoModel(
            id: 'BV1realStats',
            url: 'https://example.com/video',
            title: '统计行绑定真实数据',
            viewCount: 123456,
            danmakuCount: 24000,
            uploadDate: DateTime.now().subtract(const Duration(days: 3)),
          ),
          creator: const CreatorProfile(
            id: 'creator_real',
            name: '真实UP主',
            subscribers: 4940,
          ),
          copyright: VideoCopyright.original,
        ),
      );

      // then: every segment shows the API value, not sample copy
      expect(find.text('12.3万 播放'), findsOneWidget);
      expect(find.text('2.4万 弹幕'), findsOneWidget);
      expect(find.text('3 天前'), findsOneWidget);
      expect(find.text('原创'), findsOneWidget);
      expect(find.text('4940 关注'), findsOneWidget);
    });

    testWidgets('hides header segments the API did not provide', (
      tester,
    ) async {
      // given: a detail with only a title, id and view count
      await pumpHeader(
        tester,
        VideoDetail(
          video: const VideoModel(
            id: 'BV1sparse',
            url: 'https://example.com/video',
            title: '缺失字段的视频',
            viewCount: 100,
          ),
          creator: const CreatorProfile(id: 'creator_sparse', name: '无关注数UP主'),
        ),
      );

      // then: nothing is invented for the missing fields
      expect(find.text('100 播放'), findsOneWidget);
      expect(find.text('原创'), findsNothing);
      expect(find.text('转载'), findsNothing);
      expect(find.text('2.4万 弹幕'), findsNothing);
      expect(find.text('1天前'), findsNothing);
      expect(find.text('4940 关注'), findsNothing);
      // the id chip still renders, and no separator is left dangling
      expect(find.text('BV1sparse'), findsOneWidget);
      // 两段之间恰好一个分隔符，且它位于两者之间：挂在最后一段之后的分隔符
      // 数量相同，只数个数拦不住。
      expect(find.text('·'), findsOneWidget);
      final separator = tester.getRect(find.text('·'));
      final viewLabel = tester.getRect(find.text('100 播放'));
      final idChip = tester.getRect(find.text('BV1sparse'));
      expect(separator.left, greaterThan(viewLabel.right));
      expect(separator.right, lessThan(idChip.left));
    });
  });
}
