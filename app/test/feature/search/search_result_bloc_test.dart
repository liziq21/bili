import 'dart:async';

import 'package:app/data/repository/search_contents_repository.dart';
import 'package:app/feature/search/bloc/search_result_bloc.dart';
import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

void main() {
  test('initial state carries the source filters and first sort', () {
    final repository = _RecordingSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    expect(bloc.state.filters, repository.filters);
    expect(bloc.state.sortOption, repository.sortOptions);
    expect(bloc.state.currentSort, repository.sortOptions.first);
  });

  test('applying filters and sort restarts from page one', () async {
    final repository = _RecordingSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    bloc.add(const FetchNextPage());
    await _settle();

    expect(repository.queries, hasLength(1));
    expect(repository.queries.single.pageKey, 1);
    expect(
      repository.queries.single.sortOption,
      PhotoOrVideoSearchSort.totalrank,
    );

    bloc.add(
      ApplySearchOptions(
        filters: [
          const VideoDurationFilter().copyWith(
            selection: VideoDurationFilterOption.tenTo30Minutes,
          ),
        ],
        sortOption: PhotoOrVideoSearchSort.pubdate,
      ),
    );
    await _settle();

    expect(repository.queries, hasLength(2));
    expect(repository.queries.last.pageKey, 1);
    expect(repository.queries.last.sortOption, PhotoOrVideoSearchSort.pubdate);
    expect(
      (repository.queries.last.filters.single as SingleFilterGroup).selection,
      VideoDurationFilterOption.tenTo30Minutes,
    );
  });

  test('ignores a slow response superseded by a filter change', () async {
    final repository = _DelayedSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    bloc.add(const FetchNextPage());
    await _settle();
    expect(repository.completers, hasLength(1));

    bloc.add(
      ApplySearchOptions(
        filters: const [VideoDurationFilter()],
        sortOption: PhotoOrVideoSearchSort.pubdate,
      ),
    );
    await _settle();
    expect(repository.completers, hasLength(2));

    repository.completers[0].complete(
      Result.success(
        Page<VideoModel>(
          data: const [
            VideoModel(id: 'stale', title: 'stale', url: 'https://stale'),
          ],
          number: 1,
          totalPages: 1,
        ),
      ),
    );
    await _settle();
    expect(bloc.state.pagingState.pages, isEmpty);

    repository.completers[1].complete(
      Result.success(
        Page<VideoModel>(
          data: const [
            VideoModel(id: 'fresh', title: 'fresh', url: 'https://fresh'),
          ],
          number: 1,
          totalPages: 1,
        ),
      ),
    );
    await _settle();

    expect(bloc.state.pagingState.pages.single.single.id, 'fresh');
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _RecordingSearchContentsRepository()
    implements SearchContentsRepository<VideoModel> {
  final List<SearchQuery> queries = [];

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    queries.add(searchQuery);
    return Result.success(
      Page<VideoModel>(data: const [], number: 1, totalPages: 1),
    );
  }
}

class _DelayedSearchContentsRepository()
    implements SearchContentsRepository<VideoModel> {
  final List<Completer<PagedResult<VideoModel>>> completers = [];

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) {
    final completer = Completer<PagedResult<VideoModel>>();
    completers.add(completer);
    return completer.future;
  }
}
