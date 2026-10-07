part of 'video_bloc.dart';

sealed class const VideoEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const LoadVideoDetail(final String id) extends VideoEvent {
  @override
  List<Object?> get props => [id];
}

/// 请求解析当前视频的可播放地址。
///
/// 与 [LoadVideoDetail] 分开，因为两者的失败后果不同：详情失败整页换错误
/// 态，地址失败只是播放器区域显示错误，简介与评论仍可看。
final class const LoadMediaStream(final String id) extends VideoEvent {
  @override
  List<Object?> get props => [id];
}

final class const ToggleVideoLike() extends VideoEvent;

final class const ToggleVideoFavorite() extends VideoEvent;

final class const ToggleCreatorSubscribe() extends VideoEvent;
