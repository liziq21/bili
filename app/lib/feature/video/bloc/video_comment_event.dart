part of 'video_comment_bloc.dart';

sealed class const VideoCommentEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const LoadVideoComments(final String videoId)
    extends VideoCommentEvent {
  @override
  List<Object?> get props => [videoId];
}

final class const FetchNextCommentPage() extends VideoCommentEvent;

final class const ToggleCommentLike(final String commentId)
    extends VideoCommentEvent {
  @override
  List<Object?> get props => [commentId];
}
