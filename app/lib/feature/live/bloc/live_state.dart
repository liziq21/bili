part of 'live_bloc.dart';

class const LiveState({
  final bool isLoading = false,

  /// 切换清晰度请求进行中。与 [isLoading] 分开：切换失败不换错误态、
  /// 旧流继续播放，仅画质按钮显示进行态。
  final bool isSwitchingQuality = false,

  /// 加载直播间详情失败的原因。渲染侧据此把整页换成「加载失败，请重试」。
  final String? roomError,

  /// 加载播放流地址失败的原因。与 [roomError] 分开，因为流地址失败只
  /// 影响播放器区域，房间信息仍应显示。
  final String? streamError,

  /// 直播间详情（标题/主播/在线数）。
  final LiveRoomDetail? roomDetail,

  /// 当前直播流的可播放地址。null 表示尚未取得。
  final MediaStream? mediaStream,
}) extends Equatable {
  LiveState copyWith({
    bool? isLoading,
    bool? isSwitchingQuality,
    String? roomError,
    String? streamError,
    LiveRoomDetail? roomDetail,
    MediaStream? mediaStream,
  }) {
    return LiveState(
      isLoading: isLoading ?? this.isLoading,
      isSwitchingQuality: isSwitchingQuality ?? this.isSwitchingQuality,
      roomError: roomError,
      streamError: streamError,
      roomDetail: roomDetail ?? this.roomDetail,
      mediaStream: mediaStream ?? this.mediaStream,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSwitchingQuality,
    roomError,
    streamError,
    roomDetail,
    mediaStream,
  ];
}
