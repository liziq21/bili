import 'dart:async';

import 'package:app/app.dart';
import 'package:app/app_bloc.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:app/feature/notification/feed_update_notifier.dart';
import 'package:app/feature/setting/advanced_settings_screen.dart';
import 'package:app/feature/setting/appearance_settings_screen.dart';
import 'package:app/feature/setting/history_settings_screen.dart';
import 'package:app/feature/setting/library_settings_screen.dart';
import 'package:app/feature/setting/notification_settings_screen.dart';
import 'package:app/feature/setting/player_settings_screen.dart';
import 'package:app/feature/setting/setting_screen.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:app/routing/router.dart';
import 'package:app/routing/routes.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/src/model/paged_result.dart' show Page;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:app/design/design.dart';

/// A fake AppBloc that doesn't use emit.forEach on a stream.
/// The real AppBloc uses emit.forEach in _onStarted which creates a subscription
/// that the test framework can't clean up properly during teardown.
///
/// This fake uses a repository with Stream.value that emits once and completes
/// synchronously, so emit.forEach completes immediately and no subscription
/// remains active during test teardown.
class FakeAppBloc() extends AppBloc {
  this : super(userDataRepository: _FakeUserDataRepository());

  @override
  Future<void> close() {
    // Stream.value completes synchronously, emit.forEach subscription is done.
    return super.close();
  }
}

class _FakeUserDataRepository() implements UserDataRepository {
  @override
  Stream<UserData> get data =>
      Stream.value(const UserData(sourceId: 'bilibili'));

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async =>
      const Result.success(null);

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(
    bool useDynamicColor,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setFontScale(double fontScale) async =>
      const Result.success(null);
}

/// FakeUserDataRepository is kept for the second test if needed.
/// The smoke test uses FakeAppBloc with _FakeUserDataRepository.
class FakeUserDataRepository() implements UserDataRepository {
  UserData _currentData = const UserData(sourceId: 'bilibili');

  @override
  Stream<UserData> get data => Stream.value(_currentData);

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async {
    _currentData = _currentData.copyWith(sourceId: sourceId);
    return const Result.success(null);
  }

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(
    bool useDynamicColor,
  ) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void, Exception>> setFontScale(double fontScale) async {
    return const Result.success(null);
  }
}

/// 首页搜索入口（`HomeRouteData` 里的 `_withSearchBloc`）会 `read` 这个仓库来
/// 构造 `SearchBloc`。生产环境由 `main.dart` 的 `repoProviders` 提供，本测试
/// 之前没提供，于是 `SearchBloc` 一旦真的被创建就会抛
/// `ProviderNotFoundException`。
class FakeRecentSearchQueryRepository() implements RecentSearchQueryRepository {
  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
      const Stream.empty();

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {}

  @override
  Future<void> clearRecentSearchQueries() async {}

  @override
  Future<void> deleteOldSearchQueries(int retentionDays) async {}

  @override
  Future<void> deleteRecentSearchQuery(String query) async {}
}

/// 通知设置页的真实实现走 `flutter_local_notifications` 平台通道，测试里没有
/// Android host，所以用一个只报告能力的 fake 替换。
final class _FakeFeedUpdateNotifier() implements FeedUpdateNotifier {
  @override
  bool get isSupported => true;

  // 这条冒烟测试不验证点击跳转，给一个空流即可（真实链路见
  // feed_notification_listener_test.dart）。
  @override
  Stream<void> get feedOpened => const Stream.empty();

  @override
  Future<Result<void, Exception>> initialize() async =>
      const Result.success(null);

  @override
  Future<Result<bool, Exception>> requestPermission() async =>
      const Result.success(true);

  @override
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  }) async => Result.success(lastNotifiedCount);

  @override
  Future<void> dispose() async {}
}

class _FakeVideoFeed() extends VideoFeedRemoteDataSource {
  @override
  String get id => 'fake_video_feed';

  @override
  String get title => 'Fake Video Feed';

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<Page<VideoModel>, Exception>> fetchFeed({int? pageKey}) async {
    return Result.success(
      Page<VideoModel>(number: pageKey ?? 1, totalPages: 1, data: const []),
    );
  }
}

class _FakeLiveFeed() extends LiveRoomFeedRemoteDataSource {
  @override
  String get id => 'fake_live_feed';

  @override
  String get title => 'Fake Live Feed';

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<Page<LiveRoomModel>, Exception>> fetchFeed({
    int? pageKey,
  }) async {
    return Result.success(
      Page<LiveRoomModel>(number: pageKey ?? 1, totalPages: 1, data: const []),
    );
  }
}

class FakeMediaSource(@override final String id, @override final String name)
    implements MediaSource {
  @override
  final List<VideoFeedRemoteDataSource> videoFeedDataSources = [
    _FakeVideoFeed(),
  ];
  @override
  final List<LiveRoomFeedRemoteDataSource> liveRoomFeedDataSources = [
    _FakeLiveFeed(),
  ];
  @override
  final LiveRoomSearchRemoteDataSource? liveRoomSearchDataSource = null;

  @override
  MediaStreamRemoteDataSource? get mediaStreamDataSource => null;
  @override
  LiveRoomDetailRemoteDataSource? get liveRoomDetailDataSource => null;

  @override
  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;

  @override
  CreatorProfileSearchRemoteDataSource? get creatorProfileSearchDataSource =>
      null;
  @override
  CreatorProfileRemoteDataSource? get creatorProfileDataSource => null;

  @override
  VideoSearchRemoteDataSource? get videoSearchDataSource => null;

  @override
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => null;

  @override
  VideoDetailRemoteDataSource? get videoDetailDataSource => null;

  @override
  DanmakuRemoteDataSource? get danmakuDataSource => null;
  @override
  LiveDanmakuRemoteDataSource? get liveDanmakuDataSource => null;

  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;
  @override
  UserVideosRemoteDataSource? get userVideosDataSource => null;
  @override
  UserArticlesRemoteDataSource? get userArticlesDataSource => null;
  @override
  PlaylistContentRemoteDataSource? get playlistContentDataSource => null;
  @override
  ChannelPlaylistsRemoteDataSource? get channelPlaylistsDataSource => null;

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets(
    'App start smoke test: initializes core assembly and displays home screen',
    (tester) async {
      // 设置索引页按分组渲染，默认 800×600 视口放不下全部展开的分组；放大视口
      // 保证循环里每个分节都已被构建、可点击。
      await tester.binding.setSurfaceSize(const Size(1000, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // Given the real app assembly with network-free source/repository fakes.
      final mediaSourceCatalog = MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'bilibili',
          name: 'Bilibili',
          create: _createFakeBilibili,
        ),
      ]);
      // 顺序对齐 `main.dart`：仓库在 bloc 和 MediaSource 之外层。
      final recentSearchQueryRepository = FakeRecentSearchQueryRepository();
      final userDataRepository = FakeUserDataRepository();
      // 通知设置子页读取 `preferences` 和 `FeedUpdateNotifier`；后者在测试里
      // 用 fake 而不是真实的平台通道实现。
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      try {
        await tester.pumpWidget(
          RepositoryProvider<UserDataRepository>.value(
            value: userDataRepository,
            child: RepositoryProvider<RecentSearchQueryRepository>.value(
              value: recentSearchQueryRepository,
              child: RepositoryProvider<GetRecentSearchQueriesUseCase>.value(
                value: GetRecentSearchQueriesUseCase(
                  recentSearchQueryRepository: recentSearchQueryRepository,
                ),
                child: RepositoryProvider<PreferencesDataSource>.value(
                  value: preferences,
                  child: RepositoryProvider<FeedUpdateNotifier>.value(
                    value: _FakeFeedUpdateNotifier(),
                    child: BlocProvider<AppBloc>(
                      create: (_) => FakeAppBloc(),
                      child: Provider<MediaSourceCatalog>.value(
                        value: mediaSourceCatalog,
                        child: const App(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Pump to trigger AppBloc state change from Loading to LoadSuccess and render MaterialApp.router
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(AppScaffold), findsOneWidget);
        expect(find.byType(HomeScreen), findsOneWidget);
        // When the actual home gear opens settings through the production router.
        await tester.tap(
          find.descendant(
            of: find.byType(HomeScreen),
            matching: find.byIcon(AppIcons.settings),
          ),
        );
        await tester.pumpAndSettle();
        // Then each group opens its own page and Back restores the index.
        expect(find.byType(SettingScreen), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);
        for (final (label, path, screenType) in [
          ('Player', Routes.settingsPlayer, PlayerSettingsScreen),
          ('Appearance', Routes.settingsAppearance, AppearanceSettingsScreen),
          ('History', Routes.settingsHistory, HistorySettingsScreen),
          ('Library', Routes.settingsLibrary, LibrarySettingsScreen),
          ('Advanced', Routes.settingsAdvanced, AdvancedSettingsScreen),
        ]) {
          await tester.tap(find.widgetWithText(ListTile, label));
          await tester.pumpAndSettle();
          expect(router.state.uri.path, path);
          expect(find.byType(screenType), findsOneWidget);
          expect(find.widgetWithText(AppBar, label), findsOneWidget);
          expect(find.byType(NavigationBar), findsNothing);
          expect(find.byType(NavigationRail), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(find.byType(SettingScreen), findsOneWidget);
          expect(find.byType(ExpansionTile), findsNWidgets(3));
        }
        // 通知子页的标题已本地化，zh locale 下用中文标签匹配。
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingScreen)),
        )!;
        await tester.tap(
          find.widgetWithText(ListTile, l10n.settingsNotifications),
        );
        await tester.pumpAndSettle();
        expect(router.state.uri.path, Routes.settingsNotifications);
        expect(find.byType(NotificationSettingsScreen), findsOneWidget);
        expect(
          find.widgetWithText(AppBar, l10n.settingsNotifications),
          findsOneWidget,
        );
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(SettingScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        preferences.dispose();
      }
    },
  );
  // LIZ-50 follow-up: the failure view renders above MaterialApp (no
  // Material/Directionality ancestor), shows selectable text, and copies the
  // full error to the clipboard on tap.
  testWidgets('AppFailureView shows selectable text and copies error', (
    tester,
  ) async {
    final error = PlatformException(
      code: 'platform',
      message: 'java.lang.NoSuchMethodError: boom',
    );
    await tester.pumpWidget(MaterialApp(home: AppFailureView(error: error)));
    final fullText = 'Failed to load the app: $error';
    expect(
      find.byWidgetPredicate((w) => w is SelectableText && w.data == fullText),
      findsOneWidget,
    );
    // Clipboard's platform channel has no real handler under the test
    // binding; provide one so `Clipboard.setData` resolves.
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (message) async {
        if (message.method == 'Clipboard.setData') {
          copiedText = message.arguments['text'] as String?;
          return null;
        }
        if (message.method == 'Clipboard.getData') {
          return copiedText;
        }
        return null;
      },
    );
    await tester.tap(find.text('Copy error'));
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsOneWidget);
    expect(copiedText, fullText);
  });
}

MediaSource _createFakeBilibili() => FakeMediaSource('bilibili', 'Bilibili');
