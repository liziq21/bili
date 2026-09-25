part of 'video_comment_bloc.dart';

const _keepVideoCommentError = Object();

class const VideoCommentState({
  final bool isLoading = false,
  final bool isLoadingMore = false,
  final String? error,
  final List<VideoComment> comments = const [],
  final int currentPage = 1,
  final int totalPages = 1,
  final bool hasMore = false,
  final String videoId = '',
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
  ];
}
