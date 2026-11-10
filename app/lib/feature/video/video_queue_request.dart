import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// 进入视频页时要打开的播放队列。
///
/// 由本地播放列表的「播放全部」入口传入：[videoIds] 按播放列表顺序排列，
/// [startIndex] 是用户点中的起播位置。视频页负责把每条 id 解析成可播地址、
/// 逐条跳过解析失败的条目，再把能播的部分交给播放层。
@immutable
class const VideoQueueRequest({
  required final List<String> videoIds,
  final int startIndex = 0,
}) extends Equatable {
  this : assert(videoIds.length > 0, 'a queue request needs at least one id');

  @override
  List<Object?> get props => [videoIds, startIndex];
}

/// 已解析的播放队列：能播的条目、起播下标与请求总数。
///
/// [requestedCount] 与 [items] 的长度相等表示全部条目都可用；不等时页面
/// 提示「播放了其中几项」，不让静默丢弃看起来像全部成功。
@immutable
class const VideoQueueResult({
  required final List<VideoQueueItem> items,
  final int startIndex = 0,
  final int requestedCount = 0,
  final String? error,
}) extends Equatable {
  @override
  List<Object?> get props => [items, startIndex, requestedCount, error];
}

/// 播放队列中的一条已解析条目。
@immutable
class const VideoQueueItem({
  required final String videoId,
  required final MediaStream stream,
}) extends Equatable {
  @override
  List<Object?> get props => [videoId, stream];
}
