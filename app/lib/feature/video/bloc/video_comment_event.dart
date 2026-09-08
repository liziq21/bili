part of 'video_comment_bloc.dart';

sealed class VideoCommentEvent extends Equatable {
  const VideoCommentEvent();

  @override
  List<Object?> get props => [];
}

final class LoadVideoComments extends VideoCommentEvent {
  const LoadVideoComments(this.videoId);
  final String videoId;

  @override
  List<Object?> get props => [videoId];
}

final class FetchNextCommentPage extends VideoCommentEvent {
  const FetchNextCommentPage();
}

final class ToggleCommentLike extends VideoCommentEvent {
  const ToggleCommentLike(this.commentId);
  final String commentId;

  @override
  List<Object?> get props => [commentId];
}
