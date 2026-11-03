import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_detail_repository.dart';
import '../../../data/repository/local_library_repository.dart';
import '../player/media_playback_controller.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc({
  required final VideoDetailRepository _repository,
  final LocalLibraryRepository? _localLibraryRepository,
  final String? _sourceId,
}) extends Bloc<VideoEvent, VideoState> {
  this : super(const VideoState()) {
    on<LoadVideoDetail>(_onLoadVideoDetail);
    on<LoadMediaStream>(_onLoadMediaStream);
    on<ToggleVideoLike>(_onToggleVideoLike);
    on<ToggleVideoFavorite>(_onToggleVideoFavorite);
    on<ToggleCreatorSubscribe>(_onToggleCreatorSubscribe);
    on<MediaStreamChanged>(_onMediaStreamChanged);
    on<QueueAddVideo>(_onQueueAddVideo);
    on<QueueRemoveItem>(_onQueueRemoveItem);
    on<QueueReorderItems>(_onQueueReorderItems);
    on<QueueJumpTo>(_onQueueJumpTo);
    on<QueueSetMode>(_onQueueSetMode);
  }

  final _log = Logger('VideoBloc');
  Future<void> _onLoadVideoDetail(
    LoadVideoDetail event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    _log.info('Loading video detail for id: ${event.id}');

    final result = await _repository.getVideoDetail(event.id);
    switch (result) {
      case Success(:final success):
        var detail = success;
        final local = _localLibraryRepository;
        final sourceId = _sourceId;
        if (local != null && sourceId != null) {
          final isFavorited = await local.isBookmarked(
            sourceId,
            success.video.id,
          );
          final isSubscribed = success.creator == null
              ? false
              : await local.isSubscribed(sourceId, success.creator!.id);
          detail = success.copyWith(
            isFavorited: isFavorited,
            isSubscribed: isSubscribed,
          );
        }
        emit(state.copyWith(isLoading: false, videoDetail: detail));
      case Error(:final error):
        _log.warning('Failed to load video detail', error);
        emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onLoadMediaStream(
    LoadMediaStream event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(streamError: null));
    _log.info('Loading media stream for id: ${event.id}');

    final result = await _repository.getMediaStream(event.id);
    switch (result) {
      case Success(:final success):
        emit(state.copyWith(mediaStream: success));
      case Error(:final error):
        _log.warning('Failed to load media stream', error);
        emit(state.copyWith(streamError: error.toString()));
    }
  }

  Future<void> _onToggleVideoLike(
    ToggleVideoLike event,
    Emitter<VideoState> emit,
  ) async {
    final detail = state.videoDetail;
    if (detail == null) return;

    final newIsLiked = !detail.isLiked;
    final newCount = newIsLiked ? detail.likeCount + 1 : detail.likeCount - 1;
    final updatedDetail = detail.copyWith(
      isLiked: newIsLiked,
      likeCount: newCount < 0 ? 0 : newCount,
    );

    emit(state.copyWith(videoDetail: updatedDetail));

    final result = await _repository.toggleLike(
      detail.video.id,
      updatedDetail.isLiked,
    );
    // 乐观更新已经上屏，写失败必须回滚：否则界面停在一个从未被持久化的状态上，
    // 且没有任何迹象告诉用户它没生效。
    switch (result) {
      case Success():
        break;
      case Error(:final error):
        _log.warning('Failed to toggle like', error);
        emit(state.copyWith(videoDetail: detail, actionError: 'Like failed'));
    }
  }

  Future<void> _onToggleVideoFavorite(
    ToggleVideoFavorite event,
    Emitter<VideoState> emit,
  ) async {
    final detail = state.videoDetail;
    if (detail == null) return;

    final newIsFavorited = !detail.isFavorited;
    final newCount = newIsFavorited
        ? detail.favoriteCount + 1
        : detail.favoriteCount - 1;
    final updatedDetail = detail.copyWith(
      isFavorited: newIsFavorited,
      favoriteCount: newCount < 0 ? 0 : newCount,
    );

    emit(state.copyWith(videoDetail: updatedDetail));

    final local = _localLibraryRepository;
    final sourceId = _sourceId;
    final result = local != null && sourceId != null
        ? await _setLocalBookmark(local, sourceId, updatedDetail)
        : await _repository.toggleFavorite(
            detail.video.id,
            updatedDetail.isFavorited,
          );
    // 回滚理由同 _onToggleVideoLike
    switch (result) {
      case Success():
        break;
      case Error(:final error):
        _log.warning('Failed to toggle favorite', error);
        emit(
          state.copyWith(videoDetail: detail, actionError: 'Favorite failed'),
        );
    }
  }

  Future<void> _onToggleCreatorSubscribe(
    ToggleCreatorSubscribe event,
    Emitter<VideoState> emit,
  ) async {
    final detail = state.videoDetail;
    if (detail == null || detail.creator == null) return;

    final newIsSubscribed = !detail.isSubscribed;
    final updatedDetail = detail.copyWith(isSubscribed: newIsSubscribed);

    emit(state.copyWith(videoDetail: updatedDetail));

    final local = _localLibraryRepository;
    final sourceId = _sourceId;
    final result = local != null && sourceId != null
        ? await _setLocalSubscription(local, sourceId, updatedDetail)
        : await _repository.toggleSubscribe(
            detail.creator!.id,
            updatedDetail.isSubscribed,
          );
    // 回滚理由同 _onToggleVideoLike
    switch (result) {
      case Success():
        break;
      case Error(:final error):
        _log.warning('Failed to toggle subscribe', error);
        emit(state.copyWith(videoDetail: detail, actionError: 'Follow failed'));
    }
  }

  /// 只更新媒体流，不触发解析：解析与续接由持有播放会话的 UI 层完成。
  void _onMediaStreamChanged(
    MediaStreamChanged event,
    Emitter<VideoState> emit,
  ) {
    emit(state.copyWith(mediaStream: event.stream, streamError: null));
  }

  Future<Result<void, Exception>> _setLocalBookmark(
    LocalLibraryRepository repository,
    String sourceId,
    VideoDetail updatedDetail,
  ) async {
    try {
      await repository.setBookmark(
        sourceId: sourceId,
        video: updatedDetail.video,
        bookmarked: updatedDetail.isFavorited,
      );
      return const Result.success(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void, Exception>> _setLocalSubscription(
    LocalLibraryRepository repository,
    String sourceId,
    VideoDetail updatedDetail,
  ) async {
    try {
      final creator = updatedDetail.creator;
      if (creator == null) return const Result.success(null);
      await repository.setSubscription(
        sourceId: sourceId,
        creator: creator,
        subscribed: updatedDetail.isSubscribed,
      );
      return const Result.success(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  /// 请求把视频加入播放队列。
  Future<void> _onQueueAddVideo(
    QueueAddVideo event,
    Emitter<VideoState> emit,
  ) async {
    // 解析地址后交给播放层，由 MediaPlaybackController.addToQueue 处理。
    // 这里只负责触发解析；解析结果在 UI 层通过 MediaPlaybackController 回调处理。
    _log.info('Queue add video: ${event.videoId}');
  }

  /// 请求从队列移除指定序号的条目。
  void _onQueueRemoveItem(QueueRemoveItem event, Emitter<VideoState> emit) {
    _log.info('Queue remove item: ${event.index}');
  }

  /// 请求重排队列条目。
  void _onQueueReorderItems(QueueReorderItems event, Emitter<VideoState> emit) {
    _log.info('Queue reorder: ${event.from} -> ${event.to}');
  }

  /// 请求跳转到队列指定序号。
  void _onQueueJumpTo(QueueJumpTo event, Emitter<VideoState> emit) {
    _log.info('Queue jump to: ${event.index}');
  }

  /// 请求切换队列播放模式。
  void _onQueueSetMode(QueueSetMode event, Emitter<VideoState> emit) {
    _log.info('Queue set mode: ${event.mode}');
  }
}
