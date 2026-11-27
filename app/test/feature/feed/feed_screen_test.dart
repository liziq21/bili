import 'package:app/data/repository/feed_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/table/local_library.dart';
import 'package:app/design/design.dart';
import 'package:app/domain/feed_load_manager.dart';
import 'package:app/feature/feed/feed_cubit.dart';
import 'package:app/feature/feed/feed_screen.dart';
import 'package:app/feature/feed/widgets/feed_channel_header.dart';
import 'package:app/feature/feed/widgets/feed_entry_tile.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppDatabase db;
  late FeedCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cubit = FeedCubit(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      sourceId: 'bilibili',
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  /// Drift 的 `NativeDatabase.memory()` 仍走真实异步 I/O，widget 测试的假时钟
  /// 推不动它。任何一次读写都要放进 [WidgetTester.runAsync]，否则测试会卡在
  /// 等待 I/O 的 Future 上（实测整轮挂死到超时）。
  Future<T> io<T>(WidgetTester tester, Future<T> Function() action) async {
    final result = await tester.runAsync(action);
    return result as T;
  }

  Future<void> addSubscription(
    WidgetTester tester,
    String channelId,
    String name,
  ) => io(
    tester,
    () => db.localLibraryDao.saveSubscription(
      LocalSubscriptionCompanion.insert(
        sourceId: 'bilibili',
        originalId: channelId,
        name: name,
      ),
    ),
  );

  Future<void> addEntry(
    WidgetTester tester,
    String channelId,
    String entryId, {
    required String title,
    required DateTime publishedAt,
    bool isRead = false,
    String entryType = FeedEntry.typeVideo,
  }) => io(
    tester,
    () => db.feedDao.upsertEntries([
      FeedEntryCompanion.insert(
        sourceId: 'bilibili',
        channelId: channelId,
        entryId: entryId,
        entryType: entryType,
        title: title,
        url: 'https://example.com/$entryId',
        publishedAt: Value(publishedAt),
        isRead: Value(isRead),
      ),
    ]),
  );

  Future<void> pumpFeed(
    WidgetTester tester, {
    bool sourceSupportsFeed = true,
  }) async {
    await tester.pumpWidget(
      BlocProvider<FeedCubit>.value(
        value: cubit,
        child: MaterialApp(
          // material_ui fork 的 MaterialApp 要配 fork 的本地化代理：
          // Flutter 自身的 MaterialApp 不提供 fork 的 MaterialLocalizations。
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedScreen(sourceSupportsFeed: sourceSupportsFeed),
        ),
      ),
    );
  }

  /// 交替「让真实 I/O 落地」与「pump 一帧」直到条件成立。
  Future<void> settleUntil(
    WidgetTester tester,
    bool Function() done, {
    int maxRounds = 100,
  }) async {
    for (var round = 0; round < maxRounds; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (done()) return;
    }
    fail('feed state did not settle within $maxRounds rounds');
  }

  Future<void> settle(WidgetTester tester) =>
      settleUntil(tester, () => !cubit.state.isLoading);

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(FeedScreen)))!;

  testWidgets('renders one section per channel with its entries', (
    tester,
  ) async {
    await addSubscription(tester, 'c1', 'Channel One');
    await addSubscription(tester, 'c2', 'Channel Two');
    await addEntry(
      tester,
      'c1',
      'v1',
      title: 'First channel video',
      publishedAt: DateTime(2026, 5, 1),
    );
    await addEntry(
      tester,
      'c2',
      'v2',
      title: 'Second channel video',
      publishedAt: DateTime(2026, 5, 2),
    );

    await pumpFeed(tester);
    await settleUntil(tester, () => cubit.state.groups.length == 2);

    expect(find.text('Channel One'), findsOneWidget);
    expect(find.text('Channel Two'), findsOneWidget);
    expect(find.text('First channel video'), findsOneWidget);
    expect(find.text('Second channel video'), findsOneWidget);
  });

  testWidgets('tapping the channel header collapses and expands its entries', (
    tester,
  ) async {
    await addSubscription(tester, 'c1', 'Channel One');
    await addEntry(
      tester,
      'c1',
      'v1',
      title: 'Collapsible video',
      publishedAt: DateTime(2026, 5, 1),
    );

    await pumpFeed(tester);
    await settleUntil(tester, () => cubit.state.groups.isNotEmpty);

    expect(find.text('Collapsible video'), findsOneWidget);
    expect(cubit.state.isExpanded('c1'), isTrue);

    await tester.tap(find.text('Channel One'));
    await tester.pumpAndSettle();
    expect(cubit.state.isExpanded('c1'), isFalse);
    expect(find.text('Collapsible video'), findsNothing);

    await tester.tap(find.text('Channel One'));
    await tester.pumpAndSettle();
    expect(cubit.state.isExpanded('c1'), isTrue);
    expect(find.text('Collapsible video'), findsOneWidget);
  });

  testWidgets('collapsing one channel keeps the other channel rendered', (
    tester,
  ) async {
    await addSubscription(tester, 'c1', 'Channel One');
    await addSubscription(tester, 'c2', 'Channel Two');
    await addEntry(
      tester,
      'c1',
      'v1',
      title: 'Collapsed video',
      publishedAt: DateTime(2026, 5, 2),
    );
    await addEntry(
      tester,
      'c2',
      'v2',
      title: 'Still visible video',
      publishedAt: DateTime(2026, 5, 1),
    );

    await pumpFeed(tester);
    await settleUntil(tester, () => cubit.state.groups.length == 2);

    await tester.tap(find.text('Channel Two'));
    await tester.pumpAndSettle();

    // 扁平行列表的下标会随收起整体前移：另一组条目必须仍然渲染在正确位置。
    expect(cubit.state.isExpanded('c2'), isFalse);
    expect(find.text('Still visible video'), findsNothing);
    expect(find.text('Collapsed video'), findsOneWidget);
    expect(find.text('Channel One'), findsOneWidget);
    expect(find.text('Channel Two'), findsOneWidget);
  });

  testWidgets('tapping an entry marks it read and forwards its id', (
    tester,
  ) async {
    final opened = <String>[];
    await addSubscription(tester, 'c1', 'Channel One');
    await addEntry(
      tester,
      'c1',
      'v1',
      title: 'Playable video',
      publishedAt: DateTime(2026, 5, 1),
    );

    await tester.pumpWidget(
      BlocProvider<FeedCubit>.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedScreen(onVideo: opened.add),
        ),
      ),
    );
    await settleUntil(tester, () => cubit.state.groups.isNotEmpty);

    await tester.tap(find.text('Playable video'));
    await tester.pump();

    expect(opened, ['v1']);
    await settleUntil(tester, () => cubit.state.groups.single.unreadCount == 0);
    expect(cubit.state.groups.single.unreadCount, 0);
  });

  testWidgets('tapping an article copies its link instead of navigating', (
    tester,
  ) async {
    final opened = <String>[];
    await addSubscription(tester, 'c1', 'Channel One');
    await addEntry(
      tester,
      'c1',
      'cv1',
      title: 'Article entry',
      publishedAt: DateTime(2026, 5, 1),
      entryType: FeedEntry.typeArticle,
    );

    final clipboardCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      BlocProvider<FeedCubit>.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FeedScreen(onVideo: opened.add),
        ),
      ),
    );
    await settleUntil(tester, () => cubit.state.groups.isNotEmpty);

    await tester.tap(find.text('Article entry'));
    await tester.pump();

    // 没有应用内文章页：只复制链接，不把 cv 号当视频 id 打开。
    expect(opened, isEmpty);
    expect(clipboardCalls, hasLength(1));
    expect(
      (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
      'https://example.com/cv1',
    );
    await settleUntil(tester, () => cubit.state.groups.single.unreadCount == 0);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('shows the unread badge and drops it once the channel is read', (
    tester,
  ) async {
    await addSubscription(tester, 'c1', 'Channel One');
    await addEntry(
      tester,
      'c1',
      'v1',
      title: 'Unread video',
      publishedAt: DateTime(2026, 5, 1),
    );

    await pumpFeed(tester);
    await settleUntil(tester, () => cubit.state.groups.isNotEmpty);

    final l10n = l10nOf(tester);
    // 角标视觉上只显示数字，读屏文案由 Semantics 标签提供。
    expect(find.byType(UnreadBadge), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      tester.widget<UnreadBadge>(find.byType(UnreadBadge)).label,
      l10n.feedUnreadCount(1),
    );
    expect(find.text(l10n.feedMarkAllRead), findsOneWidget);

    await io(tester, () => cubit.markChannelRead('c1'));
    await settleUntil(tester, () => cubit.state.groups.single.unreadCount == 0);

    expect(find.byType(UnreadBadge), findsNothing);
    expect(find.text(l10n.feedMarkAllRead), findsNothing);
  });

  testWidgets('a 120-entry channel builds only the rows on screen', (
    tester,
  ) async {
    // Given one channel with 120 stored entries.
    await addSubscription(tester, 'c1', 'Channel One');
    for (var index = 0; index < 120; index++) {
      await addEntry(
        tester,
        'c1',
        'v$index',
        title: 'Entry $index',
        publishedAt: DateTime(2026, 5, 1).add(Duration(minutes: index)),
      );
    }

    // When the feed renders.
    await pumpFeed(tester);
    await settleUntil(tester, () => cubit.state.groups.isNotEmpty);

    // Then all entries are in state, but only the visible slice is in the tree.
    expect(cubit.state.groups.single.entries, hasLength(120));
    expect(tester.widgetList(find.byType(FeedEntryTile)).length, lessThan(120));
    expect(find.byType(FeedEntryTile), findsWidgets);
  });

  testWidgets('renders the empty state when nothing is stored', (tester) async {
    await pumpFeed(tester);
    await settle(tester);

    final l10n = l10nOf(tester);
    expect(find.text(l10n.feedEmptyTitle), findsOneWidget);
    expect(find.text(l10n.feedEmptyDescription), findsOneWidget);
  });

  testWidgets('renders the unsupported state without channel capability', (
    tester,
  ) async {
    await pumpFeed(tester, sourceSupportsFeed: false);
    await settle(tester);

    expect(find.text(l10nOf(tester).feedUnsupportedTitle), findsOneWidget);
    expect(find.byIcon(AppIcons.refresh), findsNothing);
  });

  testWidgets('refreshes when the retained branch becomes visible again', (
    tester,
  ) async {
    final manager = _RecordingFeedLoadManager();
    final feedCubit = FeedCubit(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      sourceId: 'bilibili',
      feedLoadManager: manager,
    );
    addTearDown(feedCubit.close);

    Widget build({required bool visible}) => TickerMode(
      enabled: visible,
      child: BlocProvider<FeedCubit>.value(
        value: feedCubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FeedScreen(),
        ),
      ),
    );

    await tester.pumpWidget(build(visible: false));
    await tester.pump();
    final loadsOnEntry = manager.loadedSourceIds.length;
    expect(loadsOnEntry, 1);

    await tester.pumpWidget(build(visible: true));
    await tester.pump();

    expect(manager.loadedSourceIds.length, loadsOnEntry + 1);
  });

  testWidgets('the app bar refresh action triggers an incremental load', (
    tester,
  ) async {
    final manager = _RecordingFeedLoadManager();
    final feedCubit = FeedCubit(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      sourceId: 'bilibili',
      feedLoadManager: manager,
    );
    addTearDown(feedCubit.close);

    await tester.pumpWidget(
      BlocProvider<FeedCubit>.value(
        value: feedCubit,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FeedScreen(),
        ),
      ),
    );
    await tester.pump();

    // 进入页面已经拉过一次；按钮再触发一次。
    final loadsBeforeTap = manager.loadedSourceIds.length;
    expect(find.byIcon(AppIcons.refresh), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.refresh));
    await tester.pump();

    expect(manager.loadedSourceIds.length, loadsBeforeTap + 1);
    expect(manager.loadedSourceIds, everyElement('bilibili'));
  });
}

final class _RecordingFeedLoadManager() implements FeedLoadManager {
  final loadedSourceIds = <String>[];

  @override
  Future<FeedLoadResult> load({required String sourceId}) async {
    loadedSourceIds.add(sourceId);
    return const FeedLoadResult();
  }
}
