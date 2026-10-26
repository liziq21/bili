import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_detail_repository.dart';
import '../player/media_playback_controller.dart';

@immutable
class const PlaybackQueueItem({
  required final String sourceId,
  required final VideoModel video,
  required final MediaStream stream,
}) extends Equatable {
  @override
  List<Object?> get props => [sourceId, video.id, stream.videoUrl];
}

@immutable
class const QueueState({
  final List<PlaybackQueueItem> items = const [],
  final int currentIndex = 0,
  final PlaybackQueueMode mode = PlaybackQueueMode.none,
}) extends Equatable {
  QueueState copyWith({
    List<PlaybackQueueItem>? items,
    int? currentIndex,
    PlaybackQueueMode? mode,
  }) => QueueState(
    items: items ?? this.items,
    currentIndex: currentIndex ?? this.currentIndex,
    mode: mode ?? this.mode,
  );

  @override
  List<Object?> get props => [items, currentIndex, mode];
}

sealed class const QueueEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const QueueSetCurrent(final PlaybackQueueItem item)
    extends QueueEvent {
  @override
  List<Object?> get props => [item];
}

final class const QueueEnqueueVideo(
  final VideoModel video,
  final Completer<bool> completer,
) extends QueueEvent {
  @override
  List<Object?> get props => [video];
}

final class const QueueUpdateCurrentStream(final MediaStream stream)
    extends QueueEvent {
  @override
  List<Object?> get props => [stream.videoUrl];
}

final class const QueueSelectItem(final int index) extends QueueEvent {
  @override
  List<Object?> get props => [index];
}

final class const QueueRemoveItem(final int index) extends QueueEvent {
  @override
  List<Object?> get props => [index];
}

final class const QueueMoveItem(final int from, final int to)
    extends QueueEvent {
  @override
  List<Object?> get props => [from, to];
}

final class const QueueClear() extends QueueEvent;

final class const QueuePlaybackChanged(
  final int currentIndex,
  final PlaybackQueueMode mode,
) extends QueueEvent {
  @override
  List<Object?> get props => [currentIndex, mode];
}

final class const QueuePlaybackCompleted() extends QueueEvent;

/// Holds the in-memory queue for one source-scoped video route.
///
/// The media controller remains the playback source of truth. This bloc owns
/// the metadata needed by the queue UI and mirrors controller index changes
/// back into the currently displayed [VideoBloc] item.
class QueueBloc({
  required final String sourceId,
  required final MediaPlaybackController controller,
  required final VideoDetailRepository repository,
  required final void Function(PlaybackQueueItem item) onItemSelected,
}) extends Bloc<QueueEvent, QueueState> {
  this : super(const QueueState()) {
    on<QueueSetCurrent>(_onSetCurrent);
    on<QueueEnqueueVideo>(_onEnqueueVideo);
    on<QueueUpdateCurrentStream>(_onUpdateCurrentStream);
    on<QueueSelectItem>(_onSelectItem);
    on<QueueRemoveItem>(_onRemoveItem);
    on<QueueMoveItem>(_onMoveItem);
    on<QueueClear>(_onClear);
    on<QueuePlaybackChanged>(_onPlaybackChanged);
    on<QueuePlaybackCompleted>(_onPlaybackCompleted);
    _subscriptions.addAll([
      controller.states.listen((playback) {
        if (isClosed) return;
        add(QueuePlaybackChanged(playback.currentIndex, playback.queueMode));
      }),
      controller.completions.listen((_) {
        if (!isClosed) add(const QueuePlaybackCompleted());
      }),
    ]);
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Resolves a video and appends it to this source's in-memory queue.
  Future<bool> enqueue(VideoModel video) {
    final completer = Completer<bool>();
    add(QueueEnqueueVideo(video, completer));
    return completer.future;
  }

  void setCurrent(VideoModel video, MediaStream stream) => add(
    QueueSetCurrent(
      PlaybackQueueItem(sourceId: sourceId, video: video, stream: stream),
    ),
  );

  void updateCurrentStream(MediaStream stream) =>
      add(QueueUpdateCurrentStream(stream));

  Future<void> _onSetCurrent(
    QueueSetCurrent event,
    Emitter<QueueState> emit,
  ) async {
    if (event.item.sourceId != sourceId) return;
    final index = state.items.indexWhere(
      (item) =>
          item.sourceId == event.item.sourceId &&
          item.video.id == event.item.video.id,
    );
    if (index < 0) {
      final items = [...state.items, event.item];
      emit(
        state.copyWith(
          items: List.unmodifiable(items),
          currentIndex: items.length - 1,
        ),
      );
      await controller.openQueue(
        items.map((item) => item.stream).toList(),
        index: items.length - 1,
      );
      return;
    }

    final items = [...state.items];
    final streamChanged =
        items[index].stream.videoUrl != event.item.stream.videoUrl;
    items[index] = event.item;
    emit(state.copyWith(items: List.unmodifiable(items), currentIndex: index));
    if (streamChanged) {
      await controller.openQueue(
        items.map((item) => item.stream).toList(),
        index: index,
      );
    }
  }

  Future<void> _onEnqueueVideo(
    QueueEnqueueVideo event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final result = await repository.getMediaStream(event.video.id);
      switch (result) {
        case Ok(:final value):
          final item = PlaybackQueueItem(
            sourceId: sourceId,
            video: event.video,
            stream: value,
          );
          final items = [...state.items, item];
          emit(
            state.copyWith(
              items: List.unmodifiable(items),
              currentIndex: state.items.isEmpty ? 0 : state.currentIndex,
            ),
          );
          if (state.items.length == 1) {
            await controller.openQueue([value]);
          } else {
            await controller.addToQueue(value);
          }
          event.completer.complete(true);
        case Error():
          event.completer.complete(false);
      }
    } on Object catch (_) {
      if (!event.completer.isCompleted) event.completer.complete(false);
    }
  }

  Future<void> _onUpdateCurrentStream(
    QueueUpdateCurrentStream event,
    Emitter<QueueState> emit,
  ) async {
    if (state.items.isEmpty || state.currentIndex >= state.items.length) return;
    final current = state.items[state.currentIndex];
    final item = PlaybackQueueItem(
      sourceId: current.sourceId,
      video: current.video,
      stream: event.stream,
    );
    final items = [...state.items]..[state.currentIndex] = item;
    emit(state.copyWith(items: List.unmodifiable(items)));
    await controller.openQueue(
      items.map((queueItem) => queueItem.stream).toList(),
      index: state.currentIndex,
    );
  }

  Future<void> _onSelectItem(
    QueueSelectItem event,
    Emitter<QueueState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.items.length) return;
    emit(state.copyWith(currentIndex: event.index));
    await controller.jumpTo(event.index);
    onItemSelected(state.items[event.index]);
  }

  Future<void> _onRemoveItem(
    QueueRemoveItem event,
    Emitter<QueueState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.items.length) return;
    final items = [...state.items]..removeAt(event.index);
    if (items.isEmpty) {
      emit(const QueueState());
      await controller.openQueue(const []);
      return;
    }
    var index = state.currentIndex;
    if (event.index < index) index--;
    if (index >= items.length) index = items.length - 1;
    emit(state.copyWith(items: List.unmodifiable(items), currentIndex: index));
    await controller.removeFromQueue(event.index);
    if (event.index == state.currentIndex) await controller.jumpTo(index);
  }

  Future<void> _onMoveItem(
    QueueMoveItem event,
    Emitter<QueueState> emit,
  ) async {
    if (event.from < 0 ||
        event.from >= state.items.length ||
        event.to < 0 ||
        event.to >= state.items.length ||
        event.from == event.to) {
      return;
    }
    final items = [...state.items];
    final item = items.removeAt(event.from);
    items.insert(event.to, item);
    var index = state.currentIndex;
    if (index == event.from) {
      index = event.to;
    } else if (event.from < index && event.to >= index) {
      index--;
    } else if (event.from > index && event.to <= index) {
      index++;
    }
    emit(state.copyWith(items: List.unmodifiable(items), currentIndex: index));
    await controller.moveQueueItem(event.from, event.to);
  }

  Future<void> _onClear(QueueClear event, Emitter<QueueState> emit) async {
    emit(const QueueState());
    await controller.openQueue(const []);
  }

  void _onPlaybackChanged(
    QueuePlaybackChanged event,
    Emitter<QueueState> emit,
  ) {
    if (state.items.isEmpty) return;
    final index = event.currentIndex.clamp(0, state.items.length - 1);
    final changed = index != state.currentIndex;
    emit(state.copyWith(currentIndex: index, mode: event.mode));
    if (changed) onItemSelected(state.items[index]);
  }

  Future<void> _onPlaybackCompleted(
    QueuePlaybackCompleted event,
    Emitter<QueueState> emit,
  ) async {
    await Future<void>.delayed(Duration.zero);
    if (state.mode != PlaybackQueueMode.none ||
        state.currentIndex >= state.items.length - 1 ||
        controller.state.currentIndex != state.currentIndex) {
      return;
    }
    await controller.next();
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }
}
