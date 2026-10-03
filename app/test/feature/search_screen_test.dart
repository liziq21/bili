import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/data/repository/search_suggest_repository.dart';
import 'package:app/feature/search/search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final recent = RecordingRecentSearchRepository(failOnWrite: true);
    var navigations = 0;

    await tester.pumpWidget(
      buildScreen(recent: recent, onSearch: (_) => navigations++),
    );
    await tester.pumpAndSettle();

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
    final recent = RecordingRecentSearchRepository();
    var navigations = 0;

    await tester.pumpWidget(
      buildScreen(recent: recent, onSearch: (_) => navigations++),
    );
    await tester.pumpAndSettle();

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
