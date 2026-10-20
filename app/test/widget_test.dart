import 'dart:async';

import 'package:app/app.dart';
import 'package:app/app_bloc.dart';
import 'package:app/app_scaffold.dart';
import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/home/home_screen.dart';
import 'package:app/feature/setting/advanced_settings_screen.dart';
import 'package:app/feature/setting/appearance_settings_screen.dart';
import 'package:app/feature/setting/history_settings_screen.dart';
import 'package:app/feature/setting/library_settings_screen.dart';
import 'package:app/feature/setting/player_settings_screen.dart';
import 'package:app/feature/setting/setting_screen.dart';
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
  Future<Result<void>> setSourceId(String sourceId) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) async =>
      const Result.ok(null);
}

/// FakeUserDataRepository is kept for the second test if needed.
/// The smoke test uses FakeAppBloc with _FakeUserDataRepository.
class FakeUserDataRepository() implements UserDataRepository {
  UserData _currentData = const UserData(sourceId: 'bilibili');

  @override
  Stream<UserData> get data => Stream.value(_currentData);

  @override
  Future<Result<void>> setSourceId(String sourceId) async {
    _currentData = _currentData.copyWith(sourceId: sourceId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setDynamicColorPreference(bool useDynamicColor) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setThemeConfig(ThemeConfig themeConfig) async {
    return const Result.ok(null);
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
}

class _FakeVideoFeed() extends VideoFeedRemoteDataSource {
  @override
  String get id => 'fake_video_feed';

  @override
  String get title => 'Fake Video Feed';

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) async {
    return Result.ok(
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
  Future<Result<Page<LiveRoomModel>>> fetchFeed({int? pageKey}) async {
    return Result.ok(
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
  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;

  @override
  CreatorProfileSearchRemoteDataSource? get creatorProfileSearchDataSource =>
      null;

  @override
  VideoSearchRemoteDataSource? get videoSearchDataSource => null;

  @override
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => null;

  @override
  VideoDetailRemoteDataSource? get videoDetailDataSource => null;

  @override
  DanmakuRemoteDataSource? get danmakuDataSource => null;

  @override
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;

  @override
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets(
    'App start smoke test: initializes core assembly and displays home screen',
    (tester) async {
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
            matching: find.byIcon(Icons.settings_outlined),
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
          expect(find.byType(ListTile), findsNWidgets(5));
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
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
