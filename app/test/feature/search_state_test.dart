import 'package:app/data/model/recent_search_query.dart';
import 'package:app/feature/search/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _date = DateTime(2026, 10, 4);

void main() {
  group('SearchState list immutability', () {
    test('copyWith does not retain the caller list', () {
      final source = <RecentSearchQuery>[
        RecentSearchQuery(query: 'a', queriedDate: _date),
      ];

      final state = SearchState().copyWith(recentSearchQueries: source);

      source.add(RecentSearchQuery(query: 'b', queriedDate: _date));

      expect(state.recentSearchQueries.length, equals(1));
    });

    test('resulting lists reject mutation', () {
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

    test('frozen list contents survive later copyWith calls', () {
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

    test('carried-over list keeps its instance so the selector value is stable', () {
      final withHistory = SearchState().copyWith(
        recentSearchQueries: [
          RecentSearchQuery(query: 'a', queriedDate: _date),
        ],
      );

      // BlocSelector compares the selected value with !=, and Dart compares
      // lists by instance. Updating only currentQuery or suggests must reuse
      // the same recentSearchQueries instance, otherwise the recent searches
      // subtree is rebuilt on unrelated updates.
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

      // A genuinely new list must not share the instance, otherwise the
      // selector treats the change as "value unchanged" and skips the rebuild.
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
  });
}
