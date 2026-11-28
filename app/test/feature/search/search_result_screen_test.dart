import 'package:app/data/repository/local_library_repository.dart';
import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:app/feature/search/search_result_screen.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';
import 'package:app/design/design.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_en.dart';
import 'package:app/ui/common/rate_limit_retry.dart';
import 'package:app/ui/video_card.dart';
import 'package:bilibili/bilibili.dart';
import 'package:flutter/semantics.dart';
import 'package:youtube/youtube.dart';

class const FakeVideoSearchRepository({final List<VideoModel> items = const []})
    implements SearchContentsRepository<VideoModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<VideoModel>(data: items, number: 1, totalPages: 1),
    );
  }
}

class TrackingFailingVideoSearchRepository()
    implements SearchContentsRepository<VideoModel> {
  int searchCallCount = 0;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    searchCallCount++;
    return Result.error(Exception('Search error'));
  }
}

class const _RateLimited() implements RateLimitedFailure;

/// 每次搜索都返回一个新的限流失败对象，模拟平台每次拒绝都构造新实例。
class TrackingRateLimitedVideoSearchRepository()
    implements SearchContentsRepository<VideoModel> {
  int searchCallCount = 0;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    searchCallCount++;
    return Result.error(_RateLimited());
  }
}

class _RefreshRateLimitedVideoSearchRepository()
    implements SearchContentsRepository<VideoModel> {
  int searchCallCount = 0;

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    searchCallCount++;
    if (searchCallCount > 1) return Result.error(const _RateLimited());
    return Result.success(
      Page<VideoModel>(
        data: const [
          VideoModel(id: 'old', title: 'old result', url: 'https://old'),
        ],
        number: 1,
        totalPages: 1,
      ),
    );
  }
}

class const FakeCreatorProfileSearchRepository({
  final List<CreatorProfile> items = const [],
}) implements SearchContentsRepository<CreatorProfile> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<CreatorProfile>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<CreatorProfile>(data: items, number: 1, totalPages: 1),
    );
  }
}

class const FakeLiveRoomSearchRepository({
  final List<LiveRoomModel> items = const [],
}) implements SearchContentsRepository<LiveRoomModel> {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<PagedResult<LiveRoomModel>> search(SearchQuery searchQuery) async {
    return Result.success(
      Page<LiveRoomModel>(data: items, number: 1, totalPages: 1),
    );
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  fail('condition not satisfied after 2 seconds');
}

Future<void> _waitForSubscription(
  WidgetTester tester,
  LocalLibraryRepository library, {
  required bool subscribed,
}) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final actual = await tester.runAsync(
      () => library.isSubscribed('test', 'creator-1'),
    );
    if (actual == subscribed) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  fail('subscription did not become $subscribed');
}

void main() {
  testWidgets(
    'SearchResultScreen renders fallback tab headers without raw identifier key',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab headers come from the ARB, never from the raw enum identifier.
      expect(
        find.text(AppLocalizationsEn().searchResultTypeChannel),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsEn().searchResultTypeVideo),
        findsOneWidget,
      );
      expect(find.text('creatorProfile'), findsNothing);
    },
  );

  testWidgets(
    'SearchResultScreen allows switching tabs between creator profiles and videos',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppLocalizationsEn().searchResultTypeVideo));
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().searchResultTypeVideo),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SearchResultScreen renders error icon, message, and retry button on search error',
    (tester) async {
      final videoRepo = TrackingFailingVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      // Initial fetch
      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Video tab
      await tester.tap(find.text(AppLocalizationsEn().searchResultTypeVideo));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.error), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().loadFailedRetryLater),
        findsOneWidget,
      );
      expect(find.text(AppLocalizationsEn().retry), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text(AppLocalizationsEn().retry));
      await tester.pumpAndSettle();

      // Verify search repository was called again for retry
      expect(videoRepo.searchCallCount, 2);
    },
  );

  testWidgets(
    'SearchResultScreen escalates the cooldown after a rejected retry',
    (tester) async {
      resetAllRateLimitCooldowns();
      final videoRepo = TrackingRateLimitedVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().searchResultTypeVideo));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsEn();
      final base = rateLimitRetryBaseCooldown.inSeconds;
      expect(find.text(l10n.retryInSeconds(base)), findsOneWidget);

      // 冷却结束后重试，又被拒：错误视图原地重建，冷却应翻倍，而不是重置回
      // 基础时长——否则「重试」永远等不到真正的冷却结束。
      await tester.pump(rateLimitRetryBaseCooldown);
      final retry = find.byType(FilledButton);
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(videoRepo.searchCallCount, 2);
      expect(find.text(l10n.retryInSeconds(base * 2)), findsOneWidget);
    },
  );

  testWidgets(
    'SearchResultScreen exposes the retry button tap action to screen readers',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final videoRepo = TrackingFailingVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().searchResultTypeVideo));
      await tester.pumpAndSettle();

      // Given the error state is on screen.
      final retry = find.ancestor(
        of: find.text(AppLocalizationsEn().retry),
        matching: find.byType(FilledButton),
      );
      expect(retry, findsOneWidget);

      // Then the button carries a tap action, so a screen reader can activate it.
      final node = tester.getSemantics(retry);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(videoRepo.searchCallCount, 2);
      semantics.dispose();
    },
  );

  testWidgets(
    'SearchResultScreen renders empty indicator when search returns no items',
    (tester) async {
      final videoRepo = const FakeVideoSearchRepository(items: []);
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      videoBloc.add(const FetchNextPage());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(query: 'Flutter', onBackClick: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppLocalizationsEn().searchResultTypeVideo));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.searchOff), findsOneWidget);
      expect(find.text(AppLocalizationsEn().nothingFound), findsOneWidget);
    },
  );

  testWidgets(
    'SearchResultScreen renders back button with tooltip and handles tap',
    (tester) async {
      var backClicked = false;
      final videoRepo = const FakeVideoSearchRepository();
      final creatorRepo = const FakeCreatorProfileSearchRepository();

      final videoBloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: videoRepo,
        query: 'keyword',
      );
      final creatorBloc = SearchResultBloc<CreatorProfile>(
        searchContentsRepository: creatorRepo,
        query: 'keyword',
      );

      addTearDown(videoBloc.close);
      addTearDown(creatorBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<VideoModel>>.value(
                value: videoBloc,
              ),
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: SearchResultScreen(
              query: 'Flutter',
              onBackClick: () {
                backClicked = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.widgetWithIcon(IconButton, AppIcons.back);
      expect(backButton, findsOneWidget);

      final iconBtn = tester.widget<IconButton>(backButton);
      expect(iconBtn.tooltip, 'Back');

      await tester.tap(backButton);
      await tester.pump();

      expect(backClicked, isTrue);
    },
  );

  testWidgets('a video result saves itself to watch later from the card menu', (
    tester,
  ) async {
    const video = VideoModel(
      id: 'video-1',
      title: 'Video title',
      url: 'https://example.com/video-1',
    );
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: const FakeVideoSearchRepository(items: [video]),
      query: 'keyword',
    );
    addTearDown(videoBloc.close);

    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final library = LocalLibraryRepository(dao: database.localLibraryDao);

    await tester.pumpWidget(
      RepositoryProvider<LocalLibraryRepository>.value(
        value: library,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: BlocProvider<SearchResultBloc<VideoModel>>.value(
            value: videoBloc,
            child: const SearchResultScreen(query: 'keyword', source: 'test'),
          ),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.text(video.title).evaluate().isNotEmpty,
    );

    final l10n = AppLocalizations.of(tester.element(find.text(video.title)))!;
    await tester.tap(find.byTooltip(l10n.moreOptions));
    await _pumpUntil(
      tester,
      () => find.text(l10n.saveToWatchLater).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.saveToWatchLater));
    for (var attempt = 0; attempt < 200; attempt++) {
      final saved = await tester.runAsync(
        () => library.isInWatchLater('test', video.id),
      );
      if (saved ?? false) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    fail('the video was not saved to watch later');
  });

  testWidgets('SearchResultScreen toggles local subscriptions', (tester) async {
    const creator = CreatorProfile(id: 'creator-1', name: 'CodeCraft');
    final creatorRepo = const FakeCreatorProfileSearchRepository(
      items: [creator],
    );
    final creatorBloc = SearchResultBloc<CreatorProfile>(
      searchContentsRepository: creatorRepo,
      query: 'keyword',
    );
    addTearDown(creatorBloc.close);

    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(database.close);
    final library = LocalLibraryRepository(dao: database.localLibraryDao);

    await tester.pumpWidget(
      RepositoryProvider<LocalLibraryRepository>.value(
        value: library,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SearchResultBloc<CreatorProfile>>.value(
                value: creatorBloc,
              ),
            ],
            child: const SearchResultScreen(query: 'keyword', source: 'test'),
          ),
        ),
      ),
    );
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.text('Subscribe').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('Subscribe'));
    await _waitForSubscription(tester, library, subscribed: true);
    await _pumpUntil(
      tester,
      () => find.text('Unsubscribe').evaluate().isNotEmpty,
    );
    expect(find.text('Unsubscribe'), findsOneWidget);

    await tester.tap(find.text('Unsubscribe'));
    await _waitForSubscription(tester, library, subscribed: false);
    await _pumpUntil(
      tester,
      () => find.text('Subscribe').evaluate().isNotEmpty,
    );
    expect(find.text('Subscribe'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('a live room result card carries a screen-reader tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final liveBloc = SearchResultBloc<LiveRoomModel>(
      searchContentsRepository: const FakeLiveRoomSearchRepository(
        items: [
          LiveRoomModel(
            id: 42,
            title: 'Live room title',
            url: 'https://example.com/live/42',
            isLive: true,
            creatorProfileName: 'Streamer',
          ),
        ],
      ),
      query: 'live',
    );
    addTearDown(liveBloc.close);
    liveBloc.add(const FetchNextPage());
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<SearchResultBloc<LiveRoomModel>>.value(
          value: liveBloc,
          child: SearchResultScreen(
            query: 'live',
            onBackClick: () {},
            onLive: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Live room title')),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(opened, ['42']);
    semantics.dispose();
  });

  testWidgets('a rejected sort refresh keeps the previous results on screen', (
    tester,
  ) async {
    resetAllRateLimitCooldowns();
    final videoRepo = _RefreshRateLimitedVideoSearchRepository();
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: videoRepo,
      query: 'keyword',
    );
    addTearDown(videoBloc.close);
    videoBloc.add(const FetchNextPage());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          YoutubeLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<SearchResultBloc<VideoModel>>.value(
          value: videoBloc,
          child: const SearchResultScreen(query: 'keyword'),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.text('old result').evaluate().isNotEmpty,
    );

    videoBloc.add(
      ApplySearchOptions(
        filters: [
          const VideoDurationFilter().copyWith(
            selection: VideoDurationFilterOption.tenTo30Minutes,
          ),
        ],
        sortOption: PhotoOrVideoSearchSort.pubdate,
      ),
    );
    await tester.pumpAndSettle();

    // 旧结果仍在，排序选择保留；页面没有被换成首屏错误视图。
    expect(find.text('old result'), findsOneWidget);
    expect(find.byIcon(AppIcons.error), findsNothing);
    expect(videoBloc.state.currentSort, PhotoOrVideoSearchSort.pubdate);
    expect(videoBloc.state.pendingRefresh, isTrue);
    expect(videoBloc.state.pagingState.error, isNotNull);
  });
  testWidgets('wide search results cap the grid at five columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final videos = [
      for (var i = 0; i < 14; i++)
        VideoModel(
          id: 'video-$i',
          title: 'Video $i',
          url: 'https://example.com/$i',
        ),
    ];
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: FakeVideoSearchRepository(items: videos),
      query: 'keyword',
    );
    addTearDown(videoBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          YoutubeLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<SearchResultBloc<VideoModel>>.value(
          value: videoBloc,
          child: const SearchResultScreen(query: 'keyword'),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byType(VideoCard).evaluate().isNotEmpty,
    );

    // 1280 宽下以前按 200px 上限排出 7 列、每列约 168px，创作者与时长
    // 都会被挤掉；限制列数后每张卡片应明显更宽。
    final cards = find.byType(VideoCard);
    final firstTop = tester.getTopLeft(cards.first).dy;
    var firstRowCount = 0;
    for (var i = 0; i < cards.evaluate().length; i++) {
      if ((tester.getTopLeft(cards.at(i)).dy - firstTop).abs() < 1) {
        firstRowCount++;
      }
    }
    expect(firstRowCount, 5);
    expect(tester.getSize(cards.first).width, greaterThan(230));
  });

  testWidgets('the result-page search bar fills the title area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: const FakeVideoSearchRepository(),
      query: 'keyword',
    );
    addTearDown(videoBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          YoutubeLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<SearchResultBloc<VideoModel>>.value(
          value: videoBloc,
          child: const SearchResultScreen(query: 'keyword'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchBar = tester.getRect(find.byType(SearchBar));
    // SearchBar 默认最大宽度 800，与右侧内容之间会空出近 400px。
    expect(searchBar.width, greaterThan(1000));
    // 搜索框右缘与结果网格右缘对齐（body 有 8px 内边距）。
    expect(searchBar.right, closeTo(1280 - 8, 1));
  });

  testWidgets('the result-page search bar clears its text with the X button', (
    tester,
  ) async {
    final videoBloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: const FakeVideoSearchRepository(),
      query: 'keyword',
    );
    addTearDown(videoBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          YoutubeLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<SearchResultBloc<VideoModel>>.value(
          value: videoBloc,
          child: const SearchResultScreen(query: 'keyword'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'keyword',
    );

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      isEmpty,
    );
    expect(find.byTooltip('Clear'), findsNothing);
  });
}
