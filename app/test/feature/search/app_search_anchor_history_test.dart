import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/datastore/preferences_key_set.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/search/app_search_anchor.dart';
import 'package:app/feature/search/bloc/search_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// SearchAnchor 内部查找的是 material_ui 自己的 MaterialLocalizations 类型，
// flutter 的 MaterialApp 提供的是另一个 fork 的类型，查找会失败。
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

class FakePreferencesDataSource() implements PreferencesDataSource {
  @override
  Future<Result<T, Exception>> get<T>(PreferencesKey<T> key) async =>
      Result.success(key.defaultValue);

  @override
  Future<Result<void, Exception>> set<T>(
    PreferencesKey<T> prefKey,
    T? value,
  ) async => Result.success(null);

  @override
  Stream<UserData> get data => const Stream.empty();

  @override
  void dispose() {}

  @override
  Stream<T> streamOf<T>(PreferencesKey<T> key) => const Stream.empty();

  @override
  Stream<T> streamOfSet<T>(PreferencesKeySet<T> keySet) => const Stream.empty();
}

class FakeSuggestRepository(final List<String> suggests)
    implements SearchSuggestRepository {
  final List<String> receivedQueries = [];

  @override
  Future<Result<List<String>, Exception>> getSuggests(String query) async {
    receivedQueries.add(query);
    return Result.success(suggests);
  }
}

class const FakeRecentSearchQueryRepository()
    implements RecentSearchQueryRepository {
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

/// [SearchBloc] 必须在 `testWidgets` 函数体内构造，不能放在 `setUp` 里：
/// 构造时 `SearchQueryChanged` 的 debounce 定时器绑定在构造所在的 zone 上。
SearchBloc buildBloc(SearchSuggestRepository suggest) {
  final recent = FakeRecentSearchQueryRepository();
  return SearchBloc(
    searchSuggestRepository: suggest,
    recentSearchQueryRepository: recent,
    getRentSearchQueriesUseCase: GetRecentSearchQueriesUseCase(
      recentSearchQueryRepository: recent,
    ),
    preferences: FakePreferencesDataSource(),
  );
}

Widget buildAnchor({
  required SearchBloc bloc,
  required void Function(String) onSearch,
  bool useBar = false,
  List<RecentSearchQuery> recentSearchQuery = const [],
  void Function(String)? onDeleteRecentSearch,
  void Function()? onClearRecentSearch,
}) {
  return MaterialApp(
    home: BlocProvider<SearchBloc>.value(
      value: bloc,
      child: Scaffold(
        body: AppSearchAnchor(
          onSearch: onSearch,
          recentSearchQuery: recentSearchQuery,
          onDeleteRecentSearch: onDeleteRecentSearch,
          onClearRecentSearch: onClearRecentSearch,
          builder: useBar
              ? null
              : (context, controller) => IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: controller.openView,
                ),
        ),
      ),
    ),
  );
}

/// 不带 [SearchBloc] 的 anchor：验证数据源不支持建议时历史仍然可用。
Widget buildAnchorWithoutBloc({
  required void Function(String) onSearch,
  List<RecentSearchQuery> recentSearchQuery = const [],
  void Function(String)? onDeleteRecentSearch,
  void Function()? onClearRecentSearch,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AppSearchAnchor(
        onSearch: onSearch,
        recentSearchQuery: recentSearchQuery,
        onDeleteRecentSearch: onDeleteRecentSearch,
        onClearRecentSearch: onClearRecentSearch,
        builder: (context, controller) => IconButton(
          icon: const Icon(Icons.search),
          onPressed: controller.openView,
        ),
      ),
    ),
  );
}

Future<void> pumpPastDebounce(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  group('mergeSuggestions', () {
    test('returns suggestions first, then history, deduped', () {
      final result = mergeSuggestions(
        query: 'flutter',
        suggests: ['flutter tutorial', 'flutter test', 'flutter web'],
        history: [
          RecentSearchQuery(query: 'flutter web', queriedDate: DateTime.now()),
          RecentSearchQuery(
            query: 'dart tutorial',
            queriedDate: DateTime.now(),
          ),
        ],
      );

      expect(result, [
        'flutter tutorial',
        'flutter test',
        'flutter web',
        'dart tutorial',
      ]);
    });

    test('does not include the current query itself', () {
      final result = mergeSuggestions(
        query: 'flutter',
        suggests: ['flutter', 'flutter tutorial'],
        history: [
          RecentSearchQuery(query: 'flutter', queriedDate: DateTime.now()),
        ],
      );

      expect(result, ['flutter tutorial']);
    });

    test('dedupes case-insensitively, keeps first occurrence casing', () {
      final result = mergeSuggestions(
        query: 'flutter',
        suggests: ['FlUtTeR tutorial'],
        history: [
          RecentSearchQuery(
            query: 'FLUTTER TUTORIAL',
            queriedDate: DateTime.now(),
          ),
        ],
      );

      // 输入给的是同一个词的大小写变体，去重后只保留建议词那一份原文。
      expect(result, ['FlUtTeR tutorial']);
    });

    test('trims whitespace before dedup', () {
      final result = mergeSuggestions(
        query: 'flutter',
        suggests: ['  flutter tutorial  '],
        history: [
          RecentSearchQuery(
            query: 'flutter tutorial',
            queriedDate: DateTime.now(),
          ),
        ],
      );

      expect(result, ['flutter tutorial']);
    });

    test('trims the query before filtering it out', () {
      final result = mergeSuggestions(
        query: '  flutter  ',
        suggests: ['flutter', 'flutter tutorial'],
        history: const [],
      );

      expect(result, ['flutter tutorial']);
    });

    test('handles empty inputs gracefully', () {
      final result = mergeSuggestions(query: '', suggests: [], history: []);
      expect(result, []);
    });

    test('preserves order: suggests first, then history', () {
      final result = mergeSuggestions(
        query: 'flutter',
        suggests: ['a', 'b'],
        history: [
          RecentSearchQuery(query: 'c', queriedDate: DateTime.now()),
          RecentSearchQuery(query: 'a', queriedDate: DateTime.now()),
          RecentSearchQuery(query: 'd', queriedDate: DateTime.now()),
        ],
      );

      expect(result, ['a', 'b', 'c', 'd']);
    });
  });

  group('AppSearchAnchor history interactions', () {
    late List<String> deletedQueries;
    late bool cleared;
    late List<RecentSearchQuery> history;

    setUp(() {
      deletedQueries = [];
      cleared = false;
      history = [
        RecentSearchQuery(query: 'flutter', queriedDate: DateTime.now()),
        RecentSearchQuery(query: 'dart', queriedDate: DateTime.now()),
        RecentSearchQuery(query: 'widget testing', queriedDate: DateTime.now()),
      ];
    });

    testWidgets('empty query shows history list with clear button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Recent searches'), findsOneWidget);
      expect(find.text('Clear all search history'), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('widget testing'), findsOneWidget);
    });

    testWidgets('empty query with no history shows empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('No search history yet'), findsOneWidget);
      expect(find.text('Clear all search history'), findsNothing);
    });

    testWidgets('tap history item searches', (tester) async {
      final searches = <String>[];

      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: searches.add,
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.tap(find.text('dart'));
      await tester.pumpAndSettle();

      expect(searches, ['dart']);
    });

    testWidgets('long press history item deletes it', (tester) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('dart'));
      await tester.pumpAndSettle();

      expect(deletedQueries, ['dart']);
    });

    testWidgets('clear button clears all history', (tester) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all search history'));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    testWidgets('fill button puts the item into the controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 第二行的填入按钮（第一行对应 flutter）
      final fillButtons = find.widgetWithIcon(IconButton, Icons.north_west);
      expect(fillButtons, findsNWidgets(3));

      await tester.tap(fillButtons.at(1));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'dart');
      // 填入不等于搜索
      expect(deletedQueries, isEmpty);
    });

    testWidgets('no delete when onDeleteRecentSearch is null', (tester) async {
      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: (_) {},
          recentSearchQuery: history,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('dart'));
      await tester.pumpAndSettle();

      expect(deletedQueries, isEmpty);
    });

    testWidgets('non-empty query merges suggestions with history, deduped', (
      tester,
    ) async {
      final suggestRepo = FakeSuggestRepository(const [
        'flutter tutorial',
        'flutter test',
        'dart async',
      ]);
      final bloc = buildBloc(suggestRepo);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        buildAnchor(
          bloc: bloc,
          onSearch: (_) {},
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 'flutter' 是历史项且等于当前输入，被过滤；'dart' 与建议词的
      // 'dart async' 不重复，应保留在尾部。
      await tester.enterText(find.byType(TextField), 'flutter');
      await pumpPastDebounce(tester);

      expect(find.text('flutter tutorial'), findsOneWidget);
      expect(find.text('flutter test'), findsOneWidget);
      expect(find.text('dart async'), findsOneWidget);
      // 当前输入本身不重复出现
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(
        tiles.where((tile) => (tile.title as Text).data == 'flutter').length,
        0,
      );
    });

    testWidgets('history items remain tappable when there is no SearchBloc', (
      tester,
    ) async {
      final searches = <String>[];

      await tester.pumpWidget(
        buildAnchorWithoutBloc(
          onSearch: searches.add,
          recentSearchQuery: history,
          onDeleteRecentSearch: deletedQueries.add,
          onClearRecentSearch: () => cleared = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'flut');
      await pumpPastDebounce(tester);

      // 没有 bloc 也要把历史列出来，且能点开搜索
      expect(find.text('flutter'), findsOneWidget);
      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();

      expect(searches, ['flutter']);
    });
  });
}
