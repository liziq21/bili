/// 媒体流模型
///
/// 描述一个可立即播放的媒体源。字段刻意保持源中立：不出现任何服务端的
/// 专有概念（清晰度编号、cid、fnval 等），不同服务的差异在各源的适配层
/// 内消解，播放层只消费本模型。
class MediaStream({
  /// 承载画面的流地址。
  ///
  /// 分段播放时为片段序列的第一段地址，同时 [segments] 非空。
  required final String videoUrl,

  /// 承载声音的流地址。
  ///
  /// 非空表示音视频分离（DASH 形态），播放层需拼 EDL 虚拟媒体后交给
  /// mpv 内部解复用；为空表示 [videoUrl] 已含声音，可直接播放。
  final String? audioUrl,

  /// 请求这些地址时必须携带的头。
  ///
  /// 各服务对来源校验的要求不同，部分地址不带特定头会被拒绝。
  final Map<String, String> headers = const {},

  /// 分段序列。非空时须按顺序播放，不能只取首段。
  ///
  /// 部分服务对较长媒体下发多个顺序片段而非单文件。适配层负责补齐
  /// [MediaSegment.duration]，播放层据此拼 EDL 保证跨段连续。
  final List<MediaSegment> segments = const [],

  /// 画面宽度（像素），未知时为 null。
  final int? width,

  /// 画面高度（像素），未知时为 null。
  final int? height,

  /// 平均码率（bit/s），未知时为 null。用于清晰度比较，不做播放决策。
  final int? bitrate,

  /// 画面编码标识（如 `avc1.640028`），未知时为 null。
  final String? codecs,

  /// 总时长，源未提供时为 null。
  final Duration? duration,
}) {
  /// 音视频是否分离，即播放前是否需要先拼成虚拟媒体。
  bool get hasSeparateAudio => audioUrl != null && audioUrl!.isNotEmpty;

  /// 是否需要按片段顺序播放。
  bool get isSegmented => segments.isNotEmpty;
}

/// 媒体流中的一个片段
class MediaSegment({
  /// 该片段的地址。
  required final String url,

  /// 该片段的时长，未知时为 null。
  final Duration? duration,
});
