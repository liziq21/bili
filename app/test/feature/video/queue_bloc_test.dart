import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/queue_bloc.dart';
import 'package:app/feature/video/common_widgets/playback_queue_view.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

void main() {
  test('keeps queue operations within the selected source', () async {
    final controller = _FakePlaybackController();
    final selected = <String>[];
    final bloc = QueueBloc(
      sourceId: 'bilibili',
      controller: controller,
      repository: _TestVideoDetailRepository(),
      onItemSelected: (item) => selected.add(item.video.id),
    );
    addTearDown(bloc.close);
    addTearDown(controller.dispose);
    final first = _item('first', 'First');
    final second = _item('second', 'Second');
    bloc.add(QueueSetCurrent(first));
    await _flush();
    bloc.add(QueueSetCurrent(second));
    await _flush();

    expect(bloc.state.items.map((item) => item.video.id), ['first', 'second']);
    expect(controller.openedQueues, [1, 2]);

    bloc.add(const QueueMoveItem(1, 0));
    await _flush();
    expect(bloc.state.items.first.video.id, 'second');

    bloc.add(const QueueSelectItem(0));
    await _flush();
    expect(selected, ['second']);
    expect(controller.jumpCalls, [0]);

    bloc.add(const QueueRemoveItem(0));
    await _flush();
    expect(bloc.state.items.single.video.id, 'first');

    bloc.add(QueueSetCurrent(_foreignItem));
    await _flush();
    expect(bloc.state.items.single.video.id, 'first');

    bloc.add(const QueueClear());
    await _flush();
    expect(bloc.state.items, isEmpty);
  });

  test('resolves an item and advances when playback completes', () async {
    final controller = _FakePlaybackController();
    final selected = <String>[];
    final bloc = QueueBloc(
      sourceId: 'youtube',
      controller: controller,
      repository: _TestVideoDetailRepository(),
      onItemSelected: (item) => selected.add(item.video.id),
    );
    addTearDown(bloc.close);
    addTearDown(controller.dispose);

    bloc.add(QueueSetCurrent(_item('first', 'First', sourceId: 'youtube')));
    await _flush();
    expect(await bloc.enqueue(_video('second', 'Second')), isTrue);

    controller.completeCurrent();
    await _flush();

    expect(controller.nextCalls, 1);
    expect(bloc.state.currentIndex, 1);
    expect(selected, ['second']);
  });

  testWidgets('renders queue items and highlights the playing item', (
    tester,
  ) async {
    final controller = _FakePlaybackController();
    final bloc = QueueBloc(
      sourceId: 'bilibili',
      controller: controller,
      repository: _TestVideoDetailRepository(),
      onItemSelected: (_) {},
    );
    addTearDown(bloc.close);
    addTearDown(controller.dispose);
    bloc.add(QueueSetCurrent(_item('first', 'First')));
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const PlaybackQueueView()),
      ),
    );

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Playing'), findsOneWidget);
    expect(find.byTooltip('Clear queue'), findsOneWidget);
  });
}

Future<void> _flush() => pumpEventQueue(times: 20);

VideoModel _video(String id, String title) =>
    VideoModel(id: id, title: title, url: 'https://example.com/$id');

PlaybackQueueItem _item(
  String id,
  String title, {
  String sourceId = 'bilibili',
}) => PlaybackQueueItem(
  sourceId: sourceId,
  video: _video(id, title),
  stream: MediaStream(videoUrl: 'https://cdn.example.com/$id.m4s'),
);

final _foreignItem = PlaybackQueueItem(
  sourceId: 'youtube',
  video: _video('foreign', 'Foreign'),
  stream: MediaStream(videoUrl: 'https://cdn.example.com/foreign.m4s'),
);

class const _TestVideoDetailRepository() implements VideoDetailRepository {
  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async =>
      Result.ok(MediaStream(videoUrl: 'https://cdn.example.com/$id.m4s'));

  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      throw UnimplementedError();

  @override
  Future<Result<bool>> toggleSubscribe(String id, bool isSubscribed) async =>
      throw UnimplementedError();
}

class _FakePlaybackController() implements MediaPlaybackController {
  final _states = StreamController<PlaybackState>.broadcast();
  final _completions = StreamController<void>.broadcast();
  final List<int> openedQueues = [];
  final List<int> jumpCalls = [];
  int nextCalls = 0;
  PlaybackState _current = PlaybackState(
    isPlaying: false,
    isBuffering: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  @override
  PlaybackState get state => _current;

  @override
  Stream<PlaybackState> get states => _states.stream;

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Future<void> openQueue(List<MediaStream> streams, {int index = 0}) async {
    openedQueues.add(streams.length);
    _emit(queueLength: streams.length, currentIndex: index);
  }

  @override
  Future<void> addToQueue(MediaStream stream) async => _emit(
    queueLength: _current.queueLength + 1,
    currentIndex: _current.currentIndex,
  );

  @override
  Future<void> removeFromQueue(int index) async => _emit(
    queueLength: _current.queueLength - 1,
    currentIndex: index < _current.currentIndex
        ? _current.currentIndex - 1
        : _current.currentIndex,
  );

  @override
  Future<void> moveQueueItem(int from, int to) async {}

  @override
  Future<void> jumpTo(int index) async {
    jumpCalls.add(index);
    _emit(queueLength: _current.queueLength, currentIndex: index);
  }

  @override
  Future<void> next() async {
    nextCalls++;
    _emit(
      queueLength: _current.queueLength,
      currentIndex: _current.currentIndex + 1,
    );
  }

  void completeCurrent() => _completions.add(null);

  void _emit({required int queueLength, required int currentIndex}) {
    _current = PlaybackState(
      isPlaying: false,
      isBuffering: false,
      position: Duration.zero,
      duration: Duration.zero,
      queueLength: queueLength,
      currentIndex: currentIndex,
    );
    _states.add(_current);
  }

  @override
  Future<void> dispose() async {
    await _states.close();
    await _completions.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
