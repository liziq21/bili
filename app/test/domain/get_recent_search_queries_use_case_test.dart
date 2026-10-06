import 'dart:async';

import 'package:app/data/model/recent_search_query.dart';
import 'package:app/data/repository/recent_search_query/recent_search_query_repository.dart';
import 'package:app/domain/get_recent_search_queries_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the limit each call forwarded so the default can be pinned.
///
/// The repository is an `abstract class` and this package has no mocking
/// library, so the fake implements it directly.
class _RecordingRecentSearchQueryRepository()
    implements RecentSearchQueryRepository {
  final requestedLimits = <int>[];

  @override
  Stream<List<RecentSearchQuery>> getRecentSearchQueries(int limit) {
    requestedLimits.add(limit);
    return const Stream<List<RecentSearchQuery>>.empty();
  }

  @override
  Future<void> insertOrReplaceRecentSearch(String searchQuery) async {}

  @override
  Future<void> clearRecentSearchQueries() async {}
}

/// The use case is a one-line delegation, so the only behaviour worth pinning
/// is the limit it forwards. A silent change to the default reshapes the
/// search suggestion list; a lost explicit limit silently truncates or
/// over-fetches history.
void main() {
  group('GetRecentSearchQueriesUseCase', () {
    late _RecordingRecentSearchQueryRepository repository;
    late GetRecentSearchQueriesUseCase useCase;

    setUp(() {
      repository = _RecordingRecentSearchQueryRepository();
      useCase = GetRecentSearchQueriesUseCase(
        recentSearchQueryRepository: repository,
      );
    });

    test('defaults to ten entries when no limit is given', () {
      useCase.invoke();

      expect(repository.requestedLimits, [10]);
    });

    test('forwards an explicit limit untouched', () {
      useCase.invoke(3);

      expect(repository.requestedLimits, [3]);
    });

    test('forwards a zero limit rather than substituting the default', () {
      // Zero is a legitimate request; collapsing it into the default would
      // resurrect history the caller asked to drop.
      useCase.invoke(0);

      expect(repository.requestedLimits, [0]);
    });

    test('each invocation forwards its own limit', () {
      useCase.invoke(1);
      useCase.invoke(7);
      useCase.invoke();

      expect(repository.requestedLimits, [1, 7, 10]);
    });
  });
}
