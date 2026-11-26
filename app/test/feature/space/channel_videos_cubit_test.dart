import 'package:app/data/repository/channel_videos_repository.dart';
import 'package:app/feature/space/bloc/channel_videos_cubit.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class _FakeChannelVideosRepository(
  final Map<int, Result<Page<VideoModel>, Exception>> responses,
) implements ChannelVideosRepository {
  final List<String> requestedChannels = [];
  final List<int> requestedPages = [];

  @override
  Future<Result<Page<VideoModel>, Exception>> fetchVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestedChannels.add(channelId);
    requestedPages.add(page);
    return responses[page] ??
        Result.success(
          Page<VideoModel>(number: page, totalPages: page, data: const []),
        );
  }
}

VideoModel _video(String id) =>
    VideoModel(id: id, title: 'Video $id', url: 'https://example.com/$id');

void main() {
  test('loads the first page for the requested channel', () async {
    final repository = _FakeChannelVideosRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: [_video('v1')])),
    });
    final cubit = ChannelVideosCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();

    expect(repository.requestedChannels, ['42']);
    expect(repository.requestedPages, [1]);
    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.pages.single.single.id, 'v1');
    expect(cubit.state.hasNextPage, isTrue);
    expect(cubit.state.isLoading, isFalse);
  });

  test('appends the next page and stops after the last page', () async {
    final repository = _FakeChannelVideosRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: [_video('v1')])),
      2: Result.success(Page(number: 2, totalPages: 2, data: [_video('v2')])),
    });
    final cubit = ChannelVideosCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();
    await cubit.fetchNextPage();
    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2]);
    expect(cubit.state.pages.expand((page) => page).map((video) => video.id), [
      'v1',
      'v2',
    ]);
    expect(cubit.state.hasNextPage, isFalse);
  });

  test('keeps loaded pages when a later page fails and retries it', () async {
    final repository = _FakeChannelVideosRepository({
      1: Result.success(Page(number: 1, totalPages: 2, data: [_video('v1')])),
      2: Result.error(Exception('network down')),
    });
    final cubit = ChannelVideosCubit(repository, '42');
    addTearDown(cubit.close);

    await cubit.fetchNextPage();
    await cubit.fetchNextPage();

    expect(cubit.state.pages, hasLength(1));
    expect(cubit.state.error, isA<Exception>());
    expect(cubit.state.isLoading, isFalse);

    repository.responses[2] = Result.success(
      Page(number: 2, totalPages: 2, data: [_video('v2')]),
    );
    await cubit.fetchNextPage();

    expect(repository.requestedPages, [1, 2, 2]);
    expect(cubit.state.error, isNull);
    expect(cubit.state.pages, hasLength(2));
    expect(cubit.state.hasNextPage, isFalse);
  });
}
