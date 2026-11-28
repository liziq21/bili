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

  test('serializes a filter change behind the in-flight request', () async {
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
    // 排序变化不能和在途请求并发发出，否则同一个风控窗口里叠两个请求。
    expect(repository.completers, hasLength(1));

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

    // 上一个请求结束后才发出新的第一页请求。
    expect(repository.completers, hasLength(2));
    expect(repository.queries.last.pageKey, 1);
    expect(repository.queries.last.sortOption, PhotoOrVideoSearchSort.pubdate);

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

  test('keeps results and the chosen sort when a refresh is rejected, '
      'and retry re-runs page one', () async {
    final repository = _FailingRefreshSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    bloc.add(const FetchNextPage());
    await _settle();
    expect(bloc.state.pagingState.pages.single.single.id, 'old');

    bloc.add(
      ApplySearchOptions(
        filters: const [VideoDurationFilter()],
        sortOption: PhotoOrVideoSearchSort.pubdate,
      ),
    );
    await _settle();

    // 刷新失败：保留上一轮结果与用户选择的排序，而不是整页换成错误态。
    expect(bloc.state.currentSort, PhotoOrVideoSearchSort.pubdate);
    expect(bloc.state.pendingRefresh, isTrue);
    expect(bloc.state.pagingState.error, isNotNull);
    expect(bloc.state.pagingState.pages.single.single.id, 'old');

    // 重试必须重跑第 1 页（新的排序），而不是接着旧结果翻页。
    bloc.add(const FetchNextPage());
    await _settle();
    expect(repository.queries.last.pageKey, 1);
    expect(repository.queries.last.sortOption, PhotoOrVideoSearchSort.pubdate);
    expect(bloc.state.pendingRefresh, isFalse);
    expect(bloc.state.pagingState.error, isNull);
    expect(bloc.state.pagingState.pages.single.single.id, 'fresh');
  });

  test('re-applying the same selection does not re-query', () async {
    final repository = _RecordingSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    bloc.add(const FetchNextPage());
    await _settle();
    expect(repository.queries, hasLength(1));

    bloc.add(
      ApplySearchOptions(
        filters: repository.filters,
        sortOption: bloc.state.currentSort,
      ),
    );
    await _settle();

    expect(repository.queries, hasLength(1));
  });

  test(
    'coalesces sort changes that arrive during an in-flight request',
    () async {
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
      bloc.add(
        ApplySearchOptions(
          filters: const [VideoDurationFilter()],
          sortOption: PhotoOrVideoSearchSort.scores,
        ),
      );
      await _settle();

      // 状态立即跟随最新选择，但在途请求结束前不再发新请求。
      expect(bloc.state.currentSort, PhotoOrVideoSearchSort.scores);
      expect(repository.completers, hasLength(1));

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

      // 被取代的最初选择不再单独发请求，只为最新选择发一次。
      expect(repository.completers, hasLength(2));
      expect(repository.queries.last.sortOption, PhotoOrVideoSearchSort.scores);
      expect(repository.queries.last.pageKey, 1);
    },
  );

  test(
    'drops a duplicate next-page request while a request is in flight',
    () async {
      final repository = _DelayedSearchContentsRepository();
      final bloc = SearchResultBloc<VideoModel>(
        searchContentsRepository: repository,
        query: 'flutter',
      );
      addTearDown(bloc.close);

      bloc.add(const FetchNextPage());
      await _settle();
      expect(repository.completers, hasLength(1));

      // 在途时的重复翻页请求必须丢弃，否则结果会多翻一页。
      bloc.add(const FetchNextPage());
      await _settle();
      expect(repository.completers, hasLength(1));

      repository.completers[0].complete(
        Result.success(
          Page<VideoModel>(
            data: const [VideoModel(id: 'p1', title: 'p1', url: 'https://p1')],
            number: 1,
            totalPages: 3,
          ),
        ),
      );
      await _settle();

      expect(repository.completers, hasLength(1));
      expect(bloc.state.pagingState.pages, hasLength(1));
    },
  );

  test('a successful retry clears the previous error', () async {
    // 成功分支必须清掉 error，否则错误视图的「成功 → 清零冷却」监听器看不到
    // 成功状态，且旧的错误标记会残留在已加载的列表上。
    final repository = _FailThenSucceedSearchContentsRepository();
    final bloc = SearchResultBloc<VideoModel>(
      searchContentsRepository: repository,
      query: 'flutter',
    );
    addTearDown(bloc.close);

    bloc.add(const FetchNextPage());
    await _settle();
    expect(bloc.state.pagingState.error, isNotNull);
    expect(bloc.state.pagingState.pages, isEmpty);

    bloc.add(const FetchNextPage());
    await _settle();
    expect(bloc.state.pagingState.error, isNull);
    expect(bloc.state.pagingState.pages, hasLength(1));
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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
  final List<SearchQuery> queries = [];
  final List<Completer<PagedResult<VideoModel>>> completers = [];

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) {
    queries.add(searchQuery);
    final completer = Completer<PagedResult<VideoModel>>();
    completers.add(completer);
    return completer.future;
  }
}

/// 第一次成功，刷新被拒，重试再次成功。
class _FailingRefreshSearchContentsRepository()
    implements SearchContentsRepository<VideoModel> {
  final List<SearchQuery> queries = [];
  int calls = 0;

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    queries.add(searchQuery);
    calls++;
    if (calls == 2) return Result.error(_RateLimitedSearchFailure());
    final id = calls == 1 ? 'old' : 'fresh';
    return Result.success(
      Page<VideoModel>(
        data: [VideoModel(id: id, title: id, url: 'https://$id')],
        number: 1,
        totalPages: 1,
      ),
    );
  }
}

class const _RateLimitedSearchFailure() implements RateLimitedFailure;

class _FailThenSucceedSearchContentsRepository()
    implements SearchContentsRepository<VideoModel> {
  int calls = 0;

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];

  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<PagedResult<VideoModel>> search(SearchQuery searchQuery) async {
    calls++;
    if (calls == 1) return Result.error(Exception('rate limited'));
    return Result.success(
      Page<VideoModel>(
        data: const [VideoModel(id: 'ok', title: 'ok', url: 'https://ok')],
        number: 1,
        totalPages: 1,
      ),
    );
  }
}
