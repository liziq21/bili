import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_comment_repository.dart';

part 'video_comment_event.dart';
part 'video_comment_state.dart';

class VideoCommentBloc extends Bloc<VideoCommentEvent, VideoCommentState> {
  VideoCommentBloc({
    required this._repository,
  })  : super(const VideoCommentState()) {
    on<LoadVideoComments>(_onLoadVideoComments);
    on<FetchNextCommentPage>(_onFetchNextCommentPage);
    on<ToggleCommentLike>(_onToggleCommentLike);
  }

  final VideoCommentRepository _repository;
  final _log = Logger('VideoCommentBloc');

  Future<void> _onLoadVideoComments(
    LoadVideoComments event,
    Emitter<VideoCommentState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      videoId: event.videoId,
      currentPage: 1,
      comments: const [],
    ));

    _log.info('Loading comments for videoId: ${event.videoId}');
    final result = await _repository.getVideoComments(event.videoId, page: 1);

    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(
          isLoading: false,
          comments: value.data,
          currentPage: 1,
          totalPages: value.totalPages,
          hasMore: 1 < value.totalPages,
        ));
      case Error(:final error):
        _log.warning('Failed to load comments', error);
        emit(state.copyWith(
          isLoading: false,
          error: error.toString(),
        ));
    }
  }

  Future<void> _onFetchNextCommentPage(
    FetchNextCommentPage event,
    Emitter<VideoCommentState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _repository.getVideoComments(state.videoId, page: nextPage);

    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(
          isLoadingMore: false,
          comments: [...state.comments, ...value.data],
          currentPage: nextPage,
          totalPages: value.totalPages,
          hasMore: nextPage < value.totalPages,
        ));
      case Error(:final error):
        _log.warning('Failed to fetch next comment page', error);
        emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onToggleCommentLike(
    ToggleCommentLike event,
    Emitter<VideoCommentState> emit,
  ) async {
    final updatedComments = state.comments.map((comment) {
      if (comment.id == event.commentId) {
        final newIsLiked = !comment.isLiked;
        final newCount = newIsLiked ? comment.likeCount + 1 : comment.likeCount - 1;
        return comment.copyWith(
          isLiked: newIsLiked,
          likeCount: newCount < 0 ? 0 : newCount,
        );
      }
      return comment;
    }).toList();

    emit(state.copyWith(comments: updatedComments));
  }
}
