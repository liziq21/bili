import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_detail_repository.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc({required final VideoDetailRepository _repository})
    extends Bloc<VideoEvent, VideoState> {
  this : super(const VideoState()) {
    on<LoadVideoDetail>(_onLoadVideoDetail);
    on<ToggleVideoLike>(_onToggleVideoLike);
    on<ToggleVideoFavorite>(_onToggleVideoFavorite);
    on<ToggleCreatorSubscribe>(_onToggleCreatorSubscribe);
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
      case Ok(:final value):
        emit(state.copyWith(isLoading: false, videoDetail: value));
      case Error(:final error):
        _log.warning('Failed to load video detail', error);
        emit(state.copyWith(isLoading: false, error: error.toString()));
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
        emit(state.copyWith(videoDetail: detail, actionError: '点赞失败'));
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

    final result = await _repository.toggleFavorite(
      detail.video.id,
      updatedDetail.isFavorited,
    );
    // 回滚理由同 _onToggleVideoLike
    switch (result) {
      case Ok():
        break;
      case Error(:final error):
        _log.warning('Failed to toggle favorite', error);
        emit(state.copyWith(videoDetail: detail, actionError: '收藏失败'));
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

    final result = await _repository.toggleSubscribe(
      detail.creator!.id,
      updatedDetail.isSubscribed,
    );
    // 回滚理由同 _onToggleVideoLike
    switch (result) {
      case Ok():
        break;
      case Error(:final error):
        _log.warning('Failed to toggle subscribe', error);
        emit(state.copyWith(videoDetail: detail, actionError: '关注失败'));
    }
  }
}
