import 'package:app/data/model/recent_search_query.dart';
import 'package:app/feature/search/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _date = DateTime(2026, 10, 4);

void main() {
  group('SearchState 列表不可变性', () {
    test('copyWith 不持有调用方那个可变列表', () {
      final source = <RecentSearchQuery>[
        RecentSearchQuery(query: 'a', queriedDate: _date),
      ];

      final state = SearchState().copyWith(recentSearchQueries: source);

      source.add(RecentSearchQuery(query: 'b', queriedDate: _date));

      expect(state.recentSearchQueries.length, equals(1));
    });

    test('所得列表不可修改', () {
      final state = SearchState().copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'a', queriedDate: _date),
        ],
        suggests: ['flutter'],
      );

      expect(
        () => state.recentSearchQueries.add(
          RecentSearchQuery(query: 'b', queriedDate: _date),
        ),
        throwsUnsupportedError,
      );
      expect(() => state.suggests.add('dart'), throwsUnsupportedError);
    });

    test('冻结后的列表内容不受后续 copyWith 影响', () {
      final first = SearchState().copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'a', queriedDate: _date),
        ],
      );
      final same = first.copyWith(currentQuery: 'flutter');
      final different = first.copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'b', queriedDate: _date),
        ],
      );

      expect(same.recentSearchQueries.map((q) => q.query), equals(['a']));
      expect(different.recentSearchQueries.map((q) => q.query), equals(['b']));
    });
  });
    test('沿用列表时保留实例，更新查询时不重建选择值', () {
      final withHistory = SearchState().copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'a', queriedDate: _date),
        ],
      );

      // BlocSelector 用 != 比较所选值，Dart 列表按实例比较。只更新 currentQuery
      // 或 suggests 时，recentSearchQueries 必须复用同一实例，否则最近搜索子树
      // 会因无关更新而重建。
      final typed = withHistory.copyWith(currentQuery: 'flutter');
      final suggested = withHistory.copyWith(suggests: ['dart']);

      expect(
        identical(typed.recentSearchQueries, withHistory.recentSearchQueries),
        isTrue,
      );
      expect(
        identical(
          suggested.recentSearchQueries,
          withHistory.recentSearchQueries,
        ),
        isTrue,
      );

      // 列表本身变化时实例必须不同，否则选择器会误判为「值没变」而跳过重建。
      final changed = withHistory.copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'b', queriedDate: _date),
        ],
      );
      expect(
        identical(changed.recentSearchQueries, withHistory.recentSearchQueries),
        isFalse,
      );
    });

}
