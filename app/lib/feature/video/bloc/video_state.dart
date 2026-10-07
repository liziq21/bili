part of 'video_bloc.dart';

class const VideoState({
  final bool isLoading = false,

  /// 加载视频详情失败的原因。渲染侧据此把整页换成「加载失败，请重试」
  final String? error,

  /// 点赞/收藏/关注写失败的原因。
  ///
  /// 与 [error] 分开是因为二者的渲染后果不同：加载失败页面上还没有任何内容可
  /// 展示，整页替换合理；写失败时详情已在屏上，把它并入 [error] 会把整页顶掉，
  /// 用户看到的是「视频加载失败」——与刚发生的写操作毫无关系。写失败只回滚本次
  /// 乐观更新并提示一句，详情继续留在屏上。
  final String? actionError,

  final VideoDetail? videoDetail,

  /// 当前视频的可播放地址。
  ///
  /// 与 [videoDetail] 分开：详情可以无地址（某些源只给元信息），地址也可以
  /// 在详情之后单独到达。null 表示尚未取得，不区分原因——失败原因在
  /// [streamError] 里。
  final MediaStream? mediaStream,

  /// 解析播放地址失败的原因。
  ///
  /// 与 [error] 分开，理由同 [actionError]：播放地址失败只该影响播放器区域，
  /// 并入 [error] 会把已加载成功的简介与评论一起顶掉。
  final String? streamError,
}) extends Equatable {
  VideoState copyWith({
    bool? isLoading,
    String? error,
    String? actionError,
    VideoDetail? videoDetail,
    MediaStream? mediaStream,
    String? streamError,
  }) {
    return VideoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      actionError: actionError,
      videoDetail: videoDetail ?? this.videoDetail,
      mediaStream: mediaStream ?? this.mediaStream,
      streamError: streamError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    actionError,
    videoDetail,
    mediaStream,
    streamError,
  ];
}
