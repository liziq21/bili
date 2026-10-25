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

  /// 源侧的流 id（B 站 dash 的 video id），跨视频稳定，未知时为 null。
  ///
  /// 用来判断「当前已经是记住的那一档」以及让源按 id 精确匹配；只有高度时
  /// 同高度的多路码率无法区分。
  final int? streamId,

  /// 当前流的可读画质标签，如 `高清 1080P`。
  ///
  /// 该字段与 [alternatives] 中的 [MediaQualityOption.label] 使用同一来源，
  /// 因而在同一分辨率存在多路码率时，当前档的文案也不会误用另一档的标签。
  final String? qualityLabel,

  /// 画面编码标识（如 `avc1.640028`），未知时为 null。
  final String? codecs,

  /// 总时长，源未提供时为 null。
  final Duration? duration,

  /// 同一视频的其他可选画质档位，不含当前正在播放的这一档。
  ///
  /// 由各服务适配层在解析出多档流（如 DASH 的全部视频轨）时填充；
  /// 只下发单档的源为空。UI 据此渲染画质选择列表，选中后以
  /// [MediaQualityOption.height] 重新解析地址。
  final List<MediaQualityOption> alternatives = const [],
}) {
  /// 音视频是否分离，即播放前是否需要先拼成虚拟媒体。
  bool get hasSeparateAudio => audioUrl != null && audioUrl!.isNotEmpty;

  /// 是否需要按片段顺序播放。
  bool get isSegmented => segments.isNotEmpty;
}

/// 一个可选的画质档位。
///
/// 字段刻意源中立：不出现任何服务端的清晰度编号体系，只有 UI 展示与
/// 重新解析所需的两项（可读标签、画面高度）。
class MediaQualityOption({
  /// 画面高度（像素），用于重新解析时让源就近选档。
  required final int height,

  /// 可读标签，如 `1080P`。
  required final String label,

  /// 源侧的清晰度 id，跨视频稳定（如 B 站 dash 的 video id）。
  ///
  /// 记忆「选的是哪一档」要用它而不是高度：同一高度可能有多个码率，按高度
  /// 选只能就近命中其中一路。源不认识该 id 时忽略即可，不影响按高度回退。
  final int? streamId,

  /// 平均码率（bit/s），未知时为 null。仅用于排序与展示。
  final int? bitrate,
});

/// 媒体流中的一个片段
class MediaSegment({
  /// 该片段的地址。
  required final String url,

  /// 该片段的时长，未知时为 null。
  final Duration? duration,
});
