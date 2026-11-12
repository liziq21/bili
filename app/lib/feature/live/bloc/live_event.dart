part of 'live_bloc.dart';

sealed class const LiveEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 请求直播间详情（首次进入房间）。
///
/// 失败把整页换成错误态。
final class const LoadLiveRoomDetail(final int roomId) extends LiveEvent {
  @override
  List<Object?> get props => [roomId];
}

/// 后台刷新直播间详情（在线人数、标题、直播状态）。
///
/// 与 [LoadLiveRoomDetail] 的差别是失败后果：刷新失败只保留上一份详情，
/// 不写 [LiveState.roomError]、不切换到加载态——用户正在看的播放器不该因为
/// 一次轮询失败被打断。
final class const RefreshLiveRoomDetail(final int roomId) extends LiveEvent {
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
