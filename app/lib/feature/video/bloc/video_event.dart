part of 'video_bloc.dart';

sealed class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

final class LoadVideoDetail extends VideoEvent {
  const LoadVideoDetail(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class ToggleVideoLike extends VideoEvent {
  const ToggleVideoLike();
}

final class ToggleVideoFavorite extends VideoEvent {
  const ToggleVideoFavorite();
}

final class ToggleCreatorSubscribe extends VideoEvent {
  const ToggleCreatorSubscribe();
}
