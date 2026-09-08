part of 'video_comment_bloc.dart';

class VideoCommentState extends Equatable {
  const VideoCommentState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.comments = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.videoId = '',
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<VideoComment> comments;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String videoId;

  VideoCommentState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<VideoComment>? comments,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? videoId,
  }) {
    return VideoCommentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
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
