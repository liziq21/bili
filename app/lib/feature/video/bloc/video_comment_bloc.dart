import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../data/repository/video_comment_repository.dart';

part 'video_comment_event.dart';
part 'video_comment_state.dart';

class VideoCommentBloc({required final VideoCommentRepository _repository})
    extends Bloc<VideoCommentEvent, VideoCommentState> {
  this : super(const VideoCommentState()) {
    on<LoadVideoComments>(_onLoadVideoComments);
    on<FetchNextCommentPage>(_onFetchNextCommentPage);
    on<ToggleCommentLike>(_onToggleCommentLike);
    on<ToggleCommentReplies>(_onToggleCommentReplies);
    on<FetchNextCommentRepliesPage>(_onFetchNextCommentRepliesPage);
  }

  final _log = Logger('VideoCommentBloc');
  int _loadGeneration = 0;

  Future<void> _onLoadVideoComments(
    LoadVideoComments event,
    Emitter<VideoCommentState> emit,
  ) async {
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        videoId: event.videoId,
        currentPage: 1,
        comments: const [],
        replyStates: const {},
      ),
    );

    _log.info('Loading comments for videoId: ${event.videoId}');
    final result = await _repository.getVideoComments(event.videoId, page: 1);

    if (generation != _loadGeneration || state.videoId != event.videoId) {
      return;
    }

    switch (result) {
      case Success(:final success):
        emit(
          state.copyWith(
            isLoading: false,
            comments: success.data,
            currentPage: 1,
            totalPages: success.totalPages,
            hasMore: 1 < success.totalPages,
            replyStates: _replyStatesFor(success.data),
          ),
        );
      case Error(:final error):
        _log.warning('Failed to load comments', error);
        emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onFetchNextCommentPage(
    FetchNextCommentPage event,
    Emitter<VideoCommentState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final generation = _loadGeneration;
    final videoId = state.videoId;
    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _repository.getVideoComments(
      state.videoId,
      page: nextPage,
    );

    if (generation != _loadGeneration || state.videoId != videoId) return;

    switch (result) {
      case Success(:final success):
        emit(
          state.copyWith(
            isLoadingMore: false,
            comments: [...state.comments, ...success.data],
            currentPage: nextPage,
            totalPages: success.totalPages,
            hasMore: nextPage < success.totalPages,
            replyStates: _mergeReplyStates(
              state.replyStates,
              _replyStatesFor(success.data),
            ),
          ),
        );
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
        final newCount = newIsLiked
            ? comment.likeCount + 1
            : comment.likeCount - 1;
        return comment.copyWith(
          isLiked: newIsLiked,
          likeCount: newCount < 0 ? 0 : newCount,
        );
      }
      return comment;
    }).toList();

    emit(state.copyWith(comments: updatedComments));
  }

  Future<void> _onToggleCommentReplies(
    ToggleCommentReplies event,
    Emitter<VideoCommentState> emit,
  ) async {
    final current = state.replyStates[event.commentId];
    if (current == null) return;

    final isExpanded = !current.isExpanded;
    emit(
      state.copyWith(
        replyStates: {
          ...state.replyStates,
          event.commentId: current.copyWith(isExpanded: isExpanded),
        },
      ),
    );

    if (isExpanded &&
        !current.isLoading &&
        (!current.hasLoaded || current.error != null)) {
      add(FetchNextCommentRepliesPage(event.commentId));
    }
  }

  Future<void> _onFetchNextCommentRepliesPage(
    FetchNextCommentRepliesPage event,
    Emitter<VideoCommentState> emit,
  ) async {
    final current = state.replyStates[event.commentId];
    if (current == null || current.isLoading || !current.hasMore) return;

    final generation = _loadGeneration;
    final videoId = state.videoId;
    final nextPage = current.hasLoaded ? current.currentPage + 1 : 1;
    emit(
      state.copyWith(
        replyStates: {
          ...state.replyStates,
          event.commentId: current.copyWith(
            isExpanded: true,
            isLoading: true,
            error: null,
          ),
        },
      ),
    );

    final result = await _repository.getVideoCommentReplies(
      state.videoId,
      event.commentId,
      page: nextPage,
    );

    if (generation != _loadGeneration || state.videoId != videoId) return;

    switch (result) {
      case Success(:final success):
        final loaded = state.replyStates[event.commentId] ?? current;
        emit(
          state.copyWith(
            replyStates: {
              ...state.replyStates,
              event.commentId: loaded.copyWith(
                isLoading: false,
                hasLoaded: true,
                currentPage: success.number,
                totalPages: success.totalPages,
                replies: _mergeReplies(loaded.replies, success.data),
                error: null,
              ),
            },
          ),
        );
      case Error(:final error):
        _log.warning('Failed to fetch comment replies', error);
        final loaded = state.replyStates[event.commentId] ?? current;
        emit(
          state.copyWith(
            replyStates: {
              ...state.replyStates,
              event.commentId: loaded.copyWith(
                isLoading: false,
                error: error.toString(),
              ),
            },
          ),
        );
    }
  }

  static Map<String, VideoCommentReplyState> _replyStatesFor(
    Iterable<VideoComment> comments,
  ) {
    return {
      for (final comment in comments)
        if (comment.replyCount > 0 || comment.replies.isNotEmpty)
          comment.id: VideoCommentReplyState(replies: comment.replies),
    };
  }

  static Map<String, VideoCommentReplyState> _mergeReplyStates(
    Map<String, VideoCommentReplyState> existing,
    Map<String, VideoCommentReplyState> incoming,
  ) {
    final merged = {...existing};
    for (final entry in incoming.entries) {
      merged.putIfAbsent(entry.key, () => entry.value);
    }
    return merged;
  }

  static List<VideoComment> _mergeReplies(
    List<VideoComment> existing,
    List<VideoComment> incoming,
  ) {
    final merged = <VideoComment>[];
    final seen = <String>{};
    for (final reply in [...existing, ...incoming]) {
      if (seen.add(reply.id)) merged.add(reply);
    }
    return merged;
  }
}
