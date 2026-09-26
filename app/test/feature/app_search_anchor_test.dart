import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:app/feature/search/app_search_anchor.dart';
import 'package:app/feature/search/bloc/search_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// 必须用 material_ui 而不是 flutter/material：SearchAnchor 内部查找的是
// material_ui 自己的 MaterialLocalizations 类型，flutter 的 MaterialApp 提供的
// 是另一个 fork 的类型，查找会失败。
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

class FakeSuggestRepository implements SearchSuggestRepository {
  FakeSuggestRepository(this.suggests);

  final List<String> suggests;
  final List<String> receivedQueries = [];

  @override
  Future<Result<List<String>>> getSuggests(String query) async {
    receivedQueries.add(query);
    return Result.ok(suggests);
  }
}

class FakeRecentSearchQueryRepository implements RecentSearchQueryRepository {
  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
      const Stream.empty();

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {}

  @override
  Future<void> clearRecentSearchQueries() async {}
}

/// [SearchBloc] 必须在 `testWidgets` 函数体内构造，不能放在 `setUp` 里。
/// bloc 构造时 `SearchQueryChanged` 的 `debounce(300ms)` 定时器就绑定在构造
/// 所在的 zone 上；`setUp` 跑在 fake-async zone 之外，于是定时器落在真实时钟
/// 上，`tester.pump` 推不动它，bloc 永远不 emit。
SearchBloc buildBloc(SearchSuggestRepository suggest) {
  final recent = FakeRecentSearchQueryRepository();
  return SearchBloc(
    searchSuggestRepository: suggest,
    recentSearchQueryRepository: recent,
    getRentSearchQueriesUseCase: GetRecentSearchQueriesUseCase(
      recentSearchQueryRepository: recent,
    ),
  );
}

/// 打开浮层后浮层是一条挂在 Navigator overlay 上的路由，位于 [SearchBloc]
/// 所在子树之外。曾经的实现在浮层 context 里 `read<SearchBloc>()`，真机上直接
/// `ProviderNotFoundException` + 空白浮层，而 widget test 全绿。
Widget buildAnchor({
  required SearchBloc bloc,
  required void Function(String) onSearch,
}) {
  // BlocProvider 必须放在 MaterialApp 内部、Navigator 之下，才和线上一致：
  // SearchAnchor 打开的浮层是一条推到 Navigator overlay 上的路由，位于这个
  // 子树之外。把 provider 提到 MaterialApp 外面会掩盖 bug，浮层照样能读到 bloc。
  return MaterialApp(
    home: BlocProvider<SearchBloc>.value(
      value: bloc,
      child: Scaffold(
        body: AppSearchAnchor(
          onSearch: onSearch,
          builder: (context, controller) => IconButton(
            icon: const Icon(Icons.search),
            onPressed: controller.openView,
          ),
        ),
      ),
    ),
  );
}

/// 推进过 `SearchBloc` 的 300ms debounce。`pumpAndSettle` 只在有排帧时继续
/// 循环，debounce 触发后的 async 链尚未排帧就会被断言抢跑，所以必须显式
/// pump 一次空帧再推进时间。
Future<void> pumpPastDebounce(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('icon builder opens a view that shows suggestions', (
    tester,
  ) async {
    final suggest = FakeSuggestRepository(const ['Flutter 教程', 'Flutter 测试']);
    final bloc = buildBloc(suggest);
    addTearDown(bloc.close);

    await tester.pumpWidget(buildAnchor(bloc: bloc, onSearch: (_) {}));
    await tester.pumpAndSettle();

    // anchor 渲染成图标，而不是整条搜索栏
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // 浮层必须能拿到 SearchBloc 并把输入送到 suggest repository
    await tester.enterText(find.byType(TextField), 'Flutter');
    await pumpPastDebounce(tester);

    expect(suggest.receivedQueries, contains('Flutter'));
    expect(find.text('Flutter 教程'), findsOneWidget);
  });

  testWidgets('submitting a suggestion reports it to onSearch', (tester) async {
    final suggest = FakeSuggestRepository(const ['Flutter 教程', 'Flutter 测试']);
    final bloc = buildBloc(suggest);
    addTearDown(bloc.close);
    final submitted = <String>[];

    await tester.pumpWidget(buildAnchor(bloc: bloc, onSearch: submitted.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Flutter');
    await pumpPastDebounce(tester);

    await tester.tap(find.text('Flutter 教程'));
    await tester.pumpAndSettle();

    expect(submitted, ['Flutter 教程']);
  });

  testWidgets('input is truncated to maxQueryLength', (tester) async {
    final suggest = FakeSuggestRepository(const ['Flutter 教程']);
    final bloc = buildBloc(suggest);
    addTearDown(bloc.close);

    await tester.pumpWidget(buildAnchor(bloc: bloc, onSearch: (_) {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final tooLong = 'a' * 250;
    await tester.enterText(find.byType(TextField), tooLong);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 200);
  });
}
