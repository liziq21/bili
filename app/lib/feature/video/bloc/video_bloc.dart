import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_detail_repository.dart';
import '../../../data/repository/local_library_repository.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc({
    required VideoDetailRepository repository,
    LocalLibraryRepository? localLibraryRepository,
    String? sourceId,
  }) : _repository = repository,
       _localLibraryRepository = localLibraryRepository,
       _sourceId = sourceId,
       super(const VideoState()) {
    on<LoadVideoDetail>(_onLoadVideoDetail);
    on<LoadMediaStream>(_onLoadMediaStream);
    on<ToggleVideoLike>(_onToggleVideoLike);
    on<ToggleVideoFavorite>(_onToggleVideoFavorite);
    on<ToggleCreatorSubscribe>(_onToggleCreatorSubscribe);
    on<MediaStreamChanged>(_onMediaStreamChanged);
  }

  final _log = Logger('VideoBloc');
  final VideoDetailRepository _repository;
  final LocalLibraryRepository? _localLibraryRepository;
  final String? _sourceId;

  Future<void> _onLoadVideoDetail(
    LoadVideoDetail event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    _log.info('Loading video detail for id: ${event.id}');

    final result = await _repository.getVideoDetail(event.id);
    switch (result) {
      case Ok(:final value):
        var detail = value;
        final local = _localLibraryRepository;
        final sourceId = _sourceId;
        if (local != null && sourceId != null) {
          final isFavorited = await local.isBookmarked(
            sourceId,
            value.video.id,
          );
          final isSubscribed = value.creator == null
              ? false
              : await local.isSubscribed(sourceId, value.creator!.id);
          detail = value.copyWith(
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
      case Ok(:final value):
        emit(state.copyWith(mediaStream: value));
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
      case Ok():
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
      case Ok():
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
      case Ok():
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

  Future<Result<void>> _setLocalBookmark(
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
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> _setLocalSubscription(
    LocalLibraryRepository repository,
    String sourceId,
    VideoDetail updatedDetail,
  ) async {
    try {
      final creator = updatedDetail.creator;
      if (creator == null) return const Result.ok(null);
      await repository.setSubscription(
        sourceId: sourceId,
        creator: creator,
        subscribed: updatedDetail.isSubscribed,
      );
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
