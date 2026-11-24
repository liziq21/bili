import 'dart:async';

import 'package:app/app_bloc.dart';
import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/data/repository/user_data/user_data_repository.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/datastore/preferences_key_set.dart';
import 'package:app/data/repository/app_search_suggest_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/not_found/no_media_source_screen.dart';
import 'package:app/feature/search/bloc/search_bloc.dart';
import 'package:app/feature/search/search_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:app/providers/service_source_providers.dart';
import 'package:app/routing/router.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// 单订阅的 UserData 流：被订阅时先发当前值，随后转发 [emit] 推送的值。
///
/// 用单订阅的 [StreamController] 而不是 `Stream.multi`，是因为后者的
/// `MultiStreamController.close()` 与订阅者的取消回调在 teardown 阶段会与
/// 事件派发交错，触发 `Bad state: Cannot add event while adding stream`。
class FakeUserDataRepository({UserData initial = const UserData()})
    implements UserDataRepository {
  this : _current = initial {
    // 挂上监听后立即补发当前值：单订阅流不会为新订阅者重放。
    _controller.onListen = () => _controller.add(_current);
  }

  final _controller = StreamController<UserData>(sync: true);
  UserData _current;

  @override
  Stream<UserData> get data => _controller.stream;

  void emit(UserData userData) {
    _current = userData;
    if (_controller.isClosed || !_controller.hasListener) return;
    _controller.add(userData);
  }

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async {
    emit(_current.copyWith(sourceId: sourceId));
    return const Result.success(null);
  }

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(bool value) async =>
      const Result.success(null);

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setFontScale(double fontScale) async =>
      const Result.success(null);

  Future<void> dispose() => _controller.close();
}

/// 一次性返回 [UserData] 后保持打开的仓库，不给测试留下需关闭的 broadcast 流。
class _EmptyUserDataRepository() implements UserDataRepository {
  @override
  Stream<UserData> get data => Stream<UserData>.value(const UserData());

  @override
  Future<Result<void, Exception>> setSourceId(String sourceId) async =>
      const Result.success(null);

  @override
  Future<Result<void, Exception>> setDynamicColorPreference(bool value) async =>
      const Result.success(null);

  @override
  Future<Result<void, Exception>> setThemeConfig(
    ThemeConfig themeConfig,
  ) async => const Result.success(null);

  @override
  Future<Result<void, Exception>> setFontScale(double fontScale) async =>
      const Result.success(null);
}

/// 最小可用的 [PreferencesDataSource]：[SearchBloc] 构造器要求它，但本组测试
/// 不触碰偏好读写，全部返回默认值。
class _FakePreferencesDataSource() implements PreferencesDataSource {
  @override
  Future<Result<T, Exception>> get<T>(PreferencesKey<T> key) async =>
      Result.success(key.defaultValue);

  @override
  Future<Result<void, Exception>> set<T>(
    PreferencesKey<T> prefKey,
    T? value,
  ) async => const Result.success(null);

  @override
  Stream<UserData> get data => const Stream<UserData>.empty();

  @override
  void dispose() {}

  @override
  Stream<T> streamOf<T>(PreferencesKey<T> key) => Stream<T>.empty();

  @override
  Stream<T> streamOfSet<T>(PreferencesKeySet<T> keySet) => Stream<T>.empty();
}

/// 最小可用的 [MediaSource]：只声明 id/name，不提供任何可选能力。
class FakeMediaSource(final String _id) extends MediaSource {
  @override
  String get id => _id;

  @override
  String get name => _id;
}

/// 提供 suggest 能力的 [MediaSource]。
class SuggestCapableMediaSource(final String _id) extends MediaSource {
  final _suggest = _RecordingSuggestDataSource(_id);

  @override
  String get id => _id;

  @override
  String get name => _id;

  @override
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => _suggest;
}

class _RecordingSuggestDataSource(final String _sourceId)
    extends SearchSuggestRemoteDataSource {
  @override
  String get sourceId => _sourceId;

  @override
  Future<Result<List<String>, Exception>> getSuggests(String query) async =>
      Result.success(const <String>[]);
}

/// 记录 [getRecentSearchQueries] 被订阅的次数，用于验证 `MonitorRecentSearches`
/// 是否被下发。
///
/// 用单订阅 [StreamController] 避免 teardown 时的 broadcast double-close 问题。
class RecordingRecentSearchRepository() implements RecentSearchQueryRepository {
  this {
    _controller.onListen = () => _controller.add(const []);
  }

  final _controller = StreamController<List<RecentSearchQuery>>();
  int watchCount = 0;

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {}

  @override
  Future<void> clearRecentSearchQueries() async {}

  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) {
    watchCount++;
    return _controller.stream;
  }

  @override
  Future<void> deleteOldSearchQueries(int retentionDays) async {}

  @override
  Future<void> deleteRecentSearchQuery(String query) async {}

  Future<void> dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Test doubles mirroring router.dart private assembly
// ---------------------------------------------------------------------------

/// 与 router.dart 私有 `_ScopedSourceBuilder` 语义相同：从 [AppBloc] 取
/// `userData.sourceId`，经目录解析后注入 [ServiceSourceProviders]；无源时渲染
/// [NoMediaSourceScreen]。`keyPrefix` 决定 ValueKey，切换数据源时按分支重建。
class const TestScopedSource({
  super.key,
  required final String keyPrefix,
  required final WidgetBuilder builder,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, String?>(
      selector: (state) => switch (state) {
        LoadSuccess(:final userData) => userData.sourceId,
        _ => null,
      },
      builder: (context, persistedSourceId) {
        final definition = context.read<MediaSourceCatalog>().resolvePersisted(
          persistedSourceId,
        );
        if (definition == null) return const NoMediaSourceScreen();
        return ServiceSourceProviders(
          key: ValueKey('$keyPrefix:${definition.id}'),
          source: definition.id,
          child: Builder(builder: builder),
        );
      },
    );
  }
}

/// 与 router.dart 私有 `_withSearchBloc` 语义相同：无 suggest 能力时直接返回
/// child，有则建 [SearchBloc] 并下发 [MonitorRecentSearches]。
Widget testWithSearchBloc(BuildContext context, Widget child) {
  if (context.read<SearchSuggestRepository?>() == null) return child;
  return BlocProvider<SearchBloc>(
    create: (context) => SearchBloc(
      searchSuggestRepository: context.read(),
      recentSearchQueryRepository: context.read(),
      getRentSearchQueriesUseCase: context.read(),
      preferences: context.read(),
    )..add(MonitorRecentSearches()),
    child: child,
  );
}

/// 探测子树里有没有 [SearchBloc]，并渲染一个 [SearchScreen]。
///
/// [SearchScreen] 自带 Scaffold，只能作为整页渲染；把它塞进 Column 会拿到
/// 无界高度约束并溢出。这里用 [Stack] 叠在探测文字之上取样，屏幕尺寸由
/// 最外层 Scaffold 提供。
class const SearchEntryProbe({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasBloc = _probeSearchBloc(context);
    return testWithSearchBloc(
      context,
      Builder(
        builder: (inner) => Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: SearchScreen(onSearch: _noopSearch)),
              Positioned(
                top: 0,
                left: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('hasSearchBloc=$hasBloc'),
                    Text(
                      'innerHasSearchBloc='
                      '${_probeSearchBloc(inner)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 安全探测 SearchBloc：使用 context.read 会抛异常，改为手动遍历 Elementary。
  static bool _probeSearchBloc(BuildContext context) {
    try {
      return context.read<SearchBloc?>() != null;
    } on ProviderNotFoundException {
      return false;
    }
  }
}

void _noopSearch(String _) {}

/// 自带清理的测试外壳：repository 与 bloc 随树销毁，避免手动 dispose 的 teardown 竞态。
class const _TestWrapper({
  required final FakeUserDataRepository repository,
  required final AppBloc appBloc,
  required final MediaSourceCatalog catalog,
  required final Widget child,
  final List<SingleChildWidget> extraProviders = const [],
}) extends StatefulWidget {
  @override
  State<_TestWrapper> createState() => _TestWrapperState();
}

class _TestWrapperState() extends State<_TestWrapper> {
  @override
  void dispose() {
    // 按 LIFO：先关 bloc（内部 emit.forEach 订阅），再关 repository
    widget.appBloc.close();
    widget.repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AppBloc>.value(value: widget.appBloc)],
      child: MultiProvider(
        providers: [
          Provider<MediaSourceCatalog>.value(value: widget.catalog),
          ...widget.extraProviders,
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: widget.child,
        ),
      ),
    );
  }
}

/// Router 专用外壳：不需要 FakeUserDataRepository 时使用（如 _EmptyUserDataRepository）
class const _RouterTestWrapper({
  required final AppBloc appBloc,
  required final MediaSourceCatalog catalog,
  required final GoRouter router,
}) extends StatefulWidget {
  @override
  State<_RouterTestWrapper> createState() => _RouterTestWrapperState();
}

class _RouterTestWrapperState() extends State<_RouterTestWrapper> {
  @override
  void dispose() {
    widget.appBloc.close();
    widget.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AppBloc>.value(value: widget.appBloc)],
      child: MultiProvider(
        providers: [Provider<MediaSourceCatalog>.value(value: widget.catalog)],
        child: MaterialApp.router(
          routerConfig: widget.router,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
  }
}

Key? _sourceProviderKey(WidgetTester tester) {
  final providers = tester
      .widgetList<ServiceSourceProviders>(find.byType(ServiceSourceProviders))
      .toList();
  return providers.firstOrNull?.key;
}

Widget _probeBuilder(BuildContext context) => const SearchEntryProbe();

/// 两条分支的最小测试路由：builder 复用 [TestScopedSource]。
GoRouter _twoBranchRouter({required WidgetBuilder branchBuilder}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) =>
                    TestScopedSource(keyPrefix: 'home', builder: branchBuilder),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search_entry',
                builder: (_, _) => TestScopedSource(
                  keyPrefix: 'search',
                  builder: branchBuilder,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // logRoutingException 脱敏
  // -------------------------------------------------------------------------
  group('logRoutingException', () {
    GoRouterState stateFor(String location) {
      final uri = Uri.parse(location);
      return GoRouterState(
        router.configuration,
        uri: uri,
        matchedLocation: uri.path,
        fullPath: uri.path,
        pathParameters: const <String, String>{},
        pageKey: const ValueKey<String>('page'),
      );
    }

    test('keeps only the path, dropping sensitive query and fragment', () {
      final state = stateFor(
        '/unknown/video?token=secret&mid=123#fragment-secret',
      );

      final sanitized = sanitizedRoutingPath(state);

      expect(sanitized, '/unknown/video');
      for (final secret in <String>['secret', 'mid=123', 'fragment-secret']) {
        expect(sanitized, isNot(contains(secret)));
      }
    });

    test('omits the query string entirely for a root path', () {
      final sanitized = sanitizedRoutingPath(
        stateFor('/search?keyword=bob&token=secret'),
      );

      expect(sanitized, '/search');
      expect(sanitized, isNot(contains('bob')));
      expect(sanitized, isNot(contains('secret')));
    });

    test(
      'logRoutingException emits one SEVERE record on the Router logger',
      () {
        final records = <LogRecord>[];
        const expected = 'Routing exception for path: /unknown/video';
        final subscription = Logger('Router').onRecord
            .where((record) => record.message == expected)
            .listen(records.add);
        addTearDown(subscription.cancel);

        logRoutingException(
          stateFor('/unknown/video?token=secret&mid=123#fragment-secret'),
        );

        expect(records, hasLength(1));
        final record = records.single;
        expect(record.level, Level.SEVERE);
        expect(record.loggerName, 'Router');
        expect(record.error, isNull);
        expect(record.stackTrace, isNull);
        expect(record.object, isNull);
        expect(record.message, isNot(contains('secret')));
      },
    );
  });

  // -------------------------------------------------------------------------
  // 无可用数据源 → NoMediaSourceScreen
  // -------------------------------------------------------------------------
  group('no available media source', () {
    testWidgets('home and search entries both degrade to NoMediaSourceScreen', (
      tester,
    ) async {
      final appBlc = AppBloc(userDataRepository: _EmptyUserDataRepository());
      final catalog = MediaSourceCatalog(const []);
      final testRouter = _twoBranchRouter(branchBuilder: _probeBuilder);

      await tester.pumpWidget(
        _RouterTestWrapper(
          appBloc: appBlc,
          catalog: catalog,
          router: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoMediaSourceScreen), findsOneWidget);
      expect(find.textContaining('hasSearchBloc='), findsNothing);

      testRouter.go('/search_entry');
      await tester.pumpAndSettle();

      expect(find.byType(NoMediaSourceScreen), findsOneWidget);
      expect(find.textContaining('hasSearchBloc='), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 数据源切换 → 子树按 ValueKey 重建
  // -------------------------------------------------------------------------
  group('source switch rebuild', () {
    testWidgets('sourceId change swaps the ServiceSourceProviders key', (
      tester,
    ) async {
      final repository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: repository);
      final catalog = MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'source_a',
          name: 'A',
          create: () => FakeMediaSource('source_a'),
        ),
        MediaSourceDefinition(
          id: 'source_b',
          name: 'B',
          create: () => FakeMediaSource('source_b'),
        ),
      ]);

      await tester.pumpWidget(
        _TestWrapper(
          repository: repository,
          appBloc: appBloc,
          catalog: catalog,
          child: const TestScopedSource(
            keyPrefix: 'home',
            builder: _probeBuilder,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_sourceProviderKey(tester), const ValueKey('home:source_a'));

      repository.emit(const UserData(sourceId: 'source_b'));
      await tester.pumpAndSettle();

      expect(_sourceProviderKey(tester), const ValueKey('home:source_b'));
    });

    testWidgets('home and search branches carry distinct key prefixes', (
      tester,
    ) async {
      final repository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: repository);
      final catalog = MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'source_a',
          name: 'A',
          create: () => FakeMediaSource('source_a'),
        ),
      ]);
      final testRouter = _twoBranchRouter(branchBuilder: _probeBuilder);

      await tester.pumpWidget(
        _TestWrapper(
          repository: repository,
          appBloc: appBloc,
          catalog: catalog,
          child: Router.withConfig(config: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      // IndexedStack 会把非活动分支移出命中测试与 find 的可见树，所以先在有
      // 效分支上取 key，再切到另一分支取一次：两个前缀都必须各自出现一次。
      Set<Key?> activeKeys() => tester
          .widgetList<ServiceSourceProviders>(
            find.byType(ServiceSourceProviders),
          )
          .map((provider) => provider.key)
          .toSet();

      expect(activeKeys(), contains(const ValueKey('home:source_a')));

      testRouter.go('/search_entry');
      await tester.pumpAndSettle();

      expect(activeKeys(), contains(const ValueKey('search:source_a')));
    });
  });

  // -------------------------------------------------------------------------
  // 搜索建议能力降级
  // -------------------------------------------------------------------------
  group('search suggest capability degradation', () {
    testWidgets('no SearchBloc is provided without suggest capability', (
      tester,
    ) async {
      final repository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: repository);
      final catalog = MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'no_suggest',
          name: 'No suggest',
          create: () => FakeMediaSource('no_suggest'),
        ),
      ]);

      await tester.pumpWidget(
        _TestWrapper(
          repository: repository,
          appBloc: appBloc,
          catalog: catalog,
          child: const TestScopedSource(
            keyPrefix: 'search',
            builder: _probeBuilder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('hasSearchBloc=false'), findsOneWidget);
      expect(find.text('innerHasSearchBloc=false'), findsOneWidget);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SearchBloc is provided and monitors history with capability', (
      tester,
    ) async {
      final repository = FakeUserDataRepository();
      final appBloc = AppBloc(userDataRepository: repository);
      final source = SuggestCapableMediaSource('with_suggest');
      final catalog = MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'with_suggest',
          name: 'With suggest',
          create: () => source,
        ),
      ]);
      final recent = RecordingRecentSearchRepository();
      addTearDown(recent.dispose);
      final preferences = _FakePreferencesDataSource();

      await tester.pumpWidget(
        _TestWrapper(
          repository: repository,
          appBloc: appBloc,
          catalog: catalog,
          extraProviders: [
            RepositoryProvider<RecentSearchQueryRepository>.value(
              value: recent,
            ),
            RepositoryProvider<SearchSuggestRepository>.value(
              value: AppSearchSuggestRepository(
                source.searchSuggestDataSource!,
              ),
            ),
            Provider<GetRecentSearchQueriesUseCase>.value(
              value: GetRecentSearchQueriesUseCase(
                recentSearchQueryRepository: recent,
              ),
            ),
            Provider<PreferencesDataSource>.value(value: preferences),
          ],
          child: const TestScopedSource(
            keyPrefix: 'search',
            builder: _probeBuilder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('innerHasSearchBloc=true'), findsOneWidget);
      expect(recent.watchCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}
