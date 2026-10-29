part of 'live_bloc.dart';

sealed class const LiveEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 请求直播间详情。
final class const LoadLiveRoomDetail(final int roomId) extends LiveEvent {
  @override
  List<Object?> get props => [roomId];
}

/// 请求直播间播放流地址。
///
/// 与 [LoadLiveRoomDetail] 分开，因为两者的失败后果不同：详情失败整页换
/// 错误态，流地址失败只影响播放器区域。
final class const LoadLiveStream(final int roomId) extends LiveEvent {
  @override
  List<Object?> get props => [roomId];
}
