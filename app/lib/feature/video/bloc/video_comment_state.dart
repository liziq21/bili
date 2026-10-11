part of 'video_comment_bloc.dart';

class const _VideoCommentErrorSentinel();

const _keepVideoCommentError = _VideoCommentErrorSentinel();
const _keepVideoCommentReplyError = _VideoCommentErrorSentinel();

@immutable
class const VideoCommentReplyState({
  final List<VideoComment> replies = const [],
  final bool isExpanded = false,
  final bool isLoading = false,
  final bool hasLoaded = false,
  final int currentPage = 0,
  final int totalPages = 1,
  final String? error,
}) extends Equatable {
  bool get hasMore => !hasLoaded || currentPage < totalPages;

  VideoCommentReplyState copyWith({
    List<VideoComment>? replies,
    bool? isExpanded,
    bool? isLoading,
    bool? hasLoaded,
    int? currentPage,
    int? totalPages,
    Object? error = _keepVideoCommentReplyError,
  }) {
    return VideoCommentReplyState(
      replies: replies ?? this.replies,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: identical(error, _keepVideoCommentReplyError)
          ? this.error
          : error as String?,
    );
  }

  @override
  List<Object?> get props => [
    replies,
    isExpanded,
    isLoading,
    hasLoaded,
    currentPage,
    totalPages,
    error,
  ];
}

@immutable
class const VideoCommentState({
  final bool isLoading = false,
  final bool isLoadingMore = false,
  final String? error,
  final List<VideoComment> comments = const [],
  final int currentPage = 1,
  final int totalPages = 1,
  final bool hasMore = false,
  final String videoId = '',
  final Map<String, VideoCommentReplyState> replyStates = const {},
}) extends Equatable {
  VideoCommentState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _keepVideoCommentError,
    List<VideoComment>? comments,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? videoId,
    Map<String, VideoCommentReplyState>? replyStates,
  }) {
    return VideoCommentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: identical(error, _keepVideoCommentError)
          ? this.error
          : error as String?,
      comments: comments ?? this.comments,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      videoId: videoId ?? this.videoId,
      replyStates: replyStates == null
          ? this.replyStates
          : Map.unmodifiable(replyStates),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    error,
    comments,
    currentPage,
    totalPages,
    hasMore,
    videoId,
    replyStates,
  ];
}
