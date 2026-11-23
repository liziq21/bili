import 'package:app/data/repository/channel_playlists_repository.dart';
import 'package:app/feature/space/bloc/channel_playlists_cubit.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class _FakeChannelPlaylistsRepository(
  final Map<int, Result<Page<PlaylistDetail>, Exception>> responses,
) implements ChannelPlaylistsRepository {
  final List<String> requestedChannels = [];
  final List<int> requestedPages = [];

  @override
  Future<Result<Page<PlaylistDetail>, Exception>> fetchPlaylists({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedChannels.add(channelId);
    requestedPages.add(page);
    return responses[page] ??
        Result.success(
          Page<PlaylistDetail>(number: page, totalPages: page, data: const []),
        );
  }
}

PlaylistDetail _playlist(String id) =>
    PlaylistDetail(id: id, title: 'Playlist $id');

void main() {
  test('loads the first page for the requested channel', () async {
    final repository = _FakeChannelPlaylistsRepository({
      1: Result.success(
        Page(number: 1, totalPages: 2, data: [_playlist('p1')]),
      ),
    });
    final cubit = ChannelPlaylistsCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();

    expect(repository.requestedChannels, ['42']);
    expect(repository.requestedPages, [1]);
    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.pages!.single.single.id, 'p1');
    expect(cubit.state.hasNextPage, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('appends the next page and stops after the last page', () async {
    final repository = _FakeChannelPlaylistsRepository({
      1: Result.success(
        Page(number: 1, totalPages: 2, data: [_playlist('p1')]),
      ),
      2: Result.success(
        Page(number: 2, totalPages: 2, data: [_playlist('p2')]),
      ),
    });
    final cubit = ChannelPlaylistsCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();
    await cubit.fetchNextPage();
    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2]);
    expect(
      cubit.state.pages!.expand((page) => page).map((playlist) => playlist.id),
      ['p1', 'p2'],
    );
    expect(cubit.state.hasNextPage, isFalse);
  });

  test('keeps loaded pages when a later page fails and retries it', () async {
    final repository = _FakeChannelPlaylistsRepository({
      1: Result.success(
        Page(number: 1, totalPages: 2, data: [_playlist('p1')]),
      ),
      2: Result.error(Exception('network down')),
    });
    final cubit = ChannelPlaylistsCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();
    await cubit.fetchNextPage();

    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.error, isA<Exception>());
    expect(cubit.state.isLoading, isFalse);

    repository.responses[2] = Result.success(
      Page(number: 2, totalPages: 2, data: [_playlist('p2')]),
    );
    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2, 2]);
    expect(cubit.state.error, isNull);
    expect(cubit.state.pages, hasLength(2));
    expect(cubit.state.hasNextPage, isFalse);
  });

  test('skips leading pages that only contain series', () async {
    final repository = _FakeChannelPlaylistsRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: const [])),
      2: Result.success(
        Page(number: 2, totalPages: 2, data: [_playlist('p2')]),
      ),
    });
    final cubit = ChannelPlaylistsCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2]);
    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.pages!.single.single.id, 'p2');
    expect(cubit.state.keys, [2]);
    expect(cubit.state.hasNextPage, isFalse);
    expect(cubit.state.isLoading, isFalse);
  });

  test('retries the same page after an error on a skipped page', () async {
    final repository = _FakeChannelPlaylistsRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: const [])),
      2: Result.error(Exception('network down')),
    });
    final cubit = ChannelPlaylistsCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();

    expect(cubit.state.error, isA<Exception>());
    expect(cubit.state.pages, isNull);

    repository.responses[2] = Result.success(
      Page(number: 2, totalPages: 2, data: [_playlist('p2')]),
    );
    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2, 2]);
    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.pages!.single.single.id, 'p2');
  });
}
