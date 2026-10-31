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

/// 切换直播清晰度。
///
/// 直播切档 = 带目标 qn 重新请求流地址，成功后换流地址重新 open（与点播
/// 的 track 切换不同）。失败时不换错误态：旧流地址仍在播放，继续用它。
final class const SwitchLiveQuality(final int roomId, final int qn)
    extends LiveEvent {
  @override
  List<Object?> get props => [roomId, qn];
}
