part of 'video_bloc.dart';

sealed class const VideoEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const LoadVideoDetail(final String id) extends VideoEvent {
  @override
  List<Object?> get props => [id];
}

final class const ToggleVideoLike() extends VideoEvent;

final class const ToggleVideoFavorite() extends VideoEvent;

final class const ToggleCreatorSubscribe() extends VideoEvent;
