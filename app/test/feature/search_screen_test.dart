import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/feature/search/search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// SearchAnchor 内部查找的是 material_ui 自己的 MaterialLocalizations，
// 与 app_search_anchor_test.dart 同理。
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

/// 记录写入次数与是否抛错，用于验证「只写一次」与「写失败不影响搜索」。
class RecordingRecentSearchRepository({final bool failOnWrite = false})
    implements RecentSearchQueryRepository {
  final written = <String>[];

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {
    written.add(searchQuery);
    if (failOnWrite) throw StateError('write failed');
  }

  @override
  Future<void> clearRecentSearchQueries() async {}

  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) =>
      const Stream.empty();
}

class const StubSuggestRepository() implements SearchSuggestRepository {
  @override
  Future<Result<List<String>>> getSuggests(String query) async =>
      Result.ok(const []);
}

Widget buildScreen({
  required RecentSearchQueryRepository recent,
  required void Function(String) onSearch,
  SearchSuggestRepository? suggest,
}) {
  Widget child = SearchScreen(onSearch: onSearch);
  child = RepositoryProvider<RecentSearchQueryRepository>.value(
    value: recent,
    child: child,
  );
  if (suggest != null) {
    child = RepositoryProvider<SearchSuggestRepository>.value(
      value: suggest,
      child: child,
    );
  }
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('navigates exactly once when suggestions are available', (
    tester,
  ) async {
    // AppSearchAnchor._handleSearch calls both onSearch and
    // navigateToSearchResult. Pointing either at the same function that pushes
    // the results page navigates twice: Back then reopens the results page
    // instead of returning to search.
    final recent = RecordingRecentSearchRepository();
    var navigations = 0;

    await tester.pumpWidget(
      buildScreen(
        recent: recent,
        suggest: const StubSuggestRepository(),
        onSearch: (_) => navigations++,
      ),
    );
    await tester.pumpAndSettle();

    // bar 模式自带 TextField；tap 让焦点落进去，onSubmitted 才会触发。
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'flutter');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(navigations, 1);
    expect(recent.written, ['flutter']);
  });

  testWidgets('still searches when the history write fails', (tester) async {
    // The write is fire-and-forget so the search does not wait on the
    // database, but an unhandled async error takes the whole action down.
    final recent = RecordingRecentSearchRepository(failOnWrite: true);
    var navigations = 0;

    await tester.pumpWidget(
      buildScreen(recent: recent, onSearch: (_) => navigations++),
    );
    await tester.pumpAndSettle();

    // bar 模式自带 TextField；tap 让焦点落进去，onSubmitted 才会触发。
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'flutter');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(navigations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('records history without suggestion support', (tester) async {
    // The reason the write moved off SearchBloc: router.dart skips injecting
    // it when the data source has no suggestions, so a bloc-bound write never
    // runs for sources like YouTube.
    final recent = RecordingRecentSearchRepository();
    var navigations = 0;

    await tester.pumpWidget(
      buildScreen(recent: recent, onSearch: (_) => navigations++),
    );
    await tester.pumpAndSettle();

    // bar 模式自带 TextField；tap 让焦点落进去，onSubmitted 才会触发。
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'flutter');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(navigations, 1);
    expect(recent.written, ['flutter']);
  });
}
