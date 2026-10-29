import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/domain/get_search_contents_use_case.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

/// Captures the query passed to the repository and returns a canned page.
///
/// `SearchContentsRepository` is an `abstract interface class`, so a plain
/// `implements` is enough -- no mocking library is needed in this package.
class _RecordingSearchContentsRepository({
  required final Result<Page<VideoModel>, Exception> result,
}) implements SearchContentsRepository<VideoModel> {
  final receivedQueries = <SearchQuery>[];

  @override
  Future<Result<Page<VideoModel>, Exception>> search(
    SearchQuery searchQuery,
  ) async {
    receivedQueries.add(searchQuery);
    return result;
  }

  @override
  List<SortOption> get sortOptions => const [];

  @override
  List<FilterGroup> get filters => const [];
}

/// The use case forwards the query and returns the repository's `Result`
/// untouched. What matters is that it does not unwrap the `Result` into a
/// bare `Page`: callers branch on `isOk`/`isError`, so a lost error would turn
/// a failed search into an empty result page.
void main() {
  group('GetSearchContentsUseCase', () {
    const query = SearchQuery(query: 'flutter');
    final emptyPage = Page<VideoModel>(
      data: const [],
      number: 1,
      totalPages: 1,
    );

    test('returns the success result from the repository', () async {
      final repository = _RecordingSearchContentsRepository(
        result: Result.success(emptyPage),
      );
      final useCase = GetSearchContentsUseCase<VideoModel>(
        repository: repository,
      );

      final result = await useCase.invoke(query);

      expect(result.isSuccess(), isTrue);
      expect(
        (result as Success<Page<VideoModel>, Exception>).success,
        same(emptyPage),
      );
    });

    test('keeps the failure result instead of unwrapping it', () async {
      final repository = _RecordingSearchContentsRepository(
        result: Result<Page<VideoModel>, Exception>.error(
          Exception('search failed'),
        ),
      );
      final useCase = GetSearchContentsUseCase<VideoModel>(
        repository: repository,
      );

      final result = await useCase.invoke(query);

      expect(result.isError(), isTrue);
      expect(
        (result as Error<Page<VideoModel>, Exception>).error,
        isA<Exception>(),
      );
    });

    test('forwards the query object to the repository unchanged', () async {
      final repository = _RecordingSearchContentsRepository(
        result: Result.success(emptyPage),
      );
      final useCase = GetSearchContentsUseCase<VideoModel>(
        repository: repository,
      );

      await useCase.invoke(query);

      expect(repository.receivedQueries, hasLength(1));
      expect(repository.receivedQueries.single, same(query));
    });

    test('preserves paging fields on the returned page', () async {
      final paged = Page<VideoModel>(data: const [], number: 3, totalPages: 9);
      final repository = _RecordingSearchContentsRepository(
        result: Result.success(paged),
      );
      final useCase = GetSearchContentsUseCase<VideoModel>(
        repository: repository,
      );

      final result = await useCase.invoke(query);

      final ok = switch (result) {
        Success(:final success) => success,
        Error(:final error) => fail('expected Ok but got Error: $error'),
      };
      expect(ok.number, 3);
      expect(ok.totalPages, 9);
    });
  });
}
