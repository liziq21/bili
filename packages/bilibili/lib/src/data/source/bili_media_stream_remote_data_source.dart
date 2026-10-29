import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_remote_data_source.dart';

/// B站播放地址数据源
///
/// 把 B站的两类地址形态（DASH 分离流与 durl 分段）收敛成中立的
/// [MediaStream]：分离流给出 audioUrl 由播放层拼虚拟媒体；durl 形态保留
/// 全部片段供播放层按序播放。
final class BiliMediaStreamRemoteDataSource({
  required final NetworkVideoDataSource network,
  required final String browserUserAgent,
}) extends MediaStreamRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String videoId, {
    int? preferHeight,
    int? preferStreamId,
  }) async {
    try {
      final sanitizedVideoId = videoId.replaceAll(_controlChars, '').trim();
      if (sanitizedVideoId.isEmpty) {
        return Result.error(Exception('Video ID cannot be empty'));
      }

      // B站的播放地址按分P（cid）下发，而能力接口收的是媒体标识（bvid），
      // 故先取详情取首个分P的 cid。
      final detail = await network.getVideoDetail(bvid: sanitizedVideoId);
      final pages = detail.pages;
      if (pages == null || pages.isEmpty) {
        return Result.error(Exception('视频 $sanitizedVideoId 没有可用分P，无法解析播放地址'));
      }
      final cid = pages.first.cid;

      final playUrl = await network.getPlayUrl(
        bvid: sanitizedVideoId,
        cid: cid,
      );

      final dash = playUrl.dash;
      if (dash != null) {
        final videoItems = _playable(dash.video);
        if (videoItems.isNotEmpty) {
          return _fromDash(
            sanitizedVideoId,
            playUrl,
            dash,
            videoItems,
            preferHeight,
            preferStreamId,
          );
        }
      }

      final segments = _segmentsOf(playUrl.durl);
      if (segments.isNotEmpty) {
        return Result.success(
          MediaStream(
            videoUrl: segments.first.url,
            headers: _headers,
            segments: segments,
            duration: _milliseconds(playUrl.timelength),
          ),
        );
      }

      return Result.error(Exception('视频 $sanitizedVideoId 未返回可播放的流'));
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  Map<String, String> get _headers => {
    'User-Agent': browserUserAgent,
    'Referer': 'https://www.bilibili.com/',
  };

  /// DASH 分离流。响应里有视频流却无可用音轨时报错而非降级：此时
  /// `audioUrl` 为空会让播放层把纯视频当作自带声音的文件，必然无声。
  Result<MediaStream, Exception> _fromDash(
    String videoId,
    NetworkPlayUrl playUrl,
    DashData dash,
    List<MediaStreamItem> videoItems,
    int? preferHeight,
    int? preferStreamId,
  ) {
    final audioItems = _playable(dash.audio);
    if (audioItems.isEmpty) {
      return Result.error(Exception('视频 $videoId 的分离流缺少可用音轨'));
    }

    final video = _pickVideo(videoItems, preferHeight, preferStreamId);
    final audio = _pickAudio(audioItems);

    final rawVideoUrl = video.playUrls.firstWhere(
      (candidate) => candidate.isNotEmpty,
      orElse: () => '',
    );
    final rawAudioUrl = audio.playUrls.firstWhere(
      (candidate) => candidate.isNotEmpty,
      orElse: () => '',
    );
    final videoUrl = normalizeBiliUrl(rawVideoUrl);
    final audioUrl = normalizeBiliUrl(rawAudioUrl);

    if (videoUrl == null || videoUrl.isEmpty) {
      return Result.error(Exception('视频 $videoId 的分离流视频地址无效'));
    }
    if (audioUrl == null || audioUrl.isEmpty) {
      return Result.error(Exception('视频 $videoId 的分离流音频地址无效'));
    }

    return Result.success(
      MediaStream(
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        headers: _headers,
        width: video.width,
        height: video.height,
        bitrate: video.bandwidth,
        streamId: video.id,
        qualityLabel: _qualityLabel(
          video.id,
          video.height,
          acceptQuality: playUrl.acceptQuality,
          acceptDescription: playUrl.acceptDescription,
          supportFormats: playUrl.supportFormats,
        ),
        codecs: video.codecs,
        // dash.duration 以秒计，与视频详情的 duration 同量纲。
        duration: dash.duration == null
            ? null
            : Duration(seconds: dash.duration!),
        alternatives: _qualityOptions(
          videoItems,
          currentStreamId: video.id,
          acceptQuality: playUrl.acceptQuality,
          acceptDescription: playUrl.acceptDescription,
          supportFormats: playUrl.supportFormats,
        ),
      ),
    );
  }

  /// 把全部可选视频轨收敛为 UI 可渲染的画质档位列表。
  ///
  /// 只保留有高度且非当前档的条目，按高度降序，方便弹窗从高到低排列。
  /// 可读标签优先取源侧的描述映射（acceptDescription 与 acceptQuality
  /// 等长对应），取不到时退回 `{height}P`。
  List<MediaQualityOption> _qualityOptions(
    List<MediaStreamItem> videoItems, {
    required int currentStreamId,
    List<int>? acceptQuality,
    List<String>? acceptDescription,
    List<FormatDescription>? supportFormats,
  }) {
    final options = <MediaQualityOption>[];
    for (final item in videoItems) {
      final height = item.height;
      if (height == null || item.id == currentStreamId) continue;
      options.add(
        MediaQualityOption(
          height: height,
          streamId: item.id,
          label: _qualityLabel(
            item.id,
            height,
            acceptQuality: acceptQuality,
            acceptDescription: acceptDescription,
            supportFormats: supportFormats,
          ),
          bitrate: item.bandwidth,
        ),
      );
    }
    options.sort((a, b) => b.height.compareTo(a.height));
    return options;
  }

  /// 源侧画质 id 与画面高度 → 可读标签。
  ///
  /// acceptQuality 与 acceptDescription 等长且按序对应，是源的官方描述；
  /// supportFormats 的 new_description 是次要来源（部分响应才带）；
  /// 两者都没有时用 `{height}P` 兜底。
  String _qualityLabel(
    int streamId,
    int? height, {
    List<int>? acceptQuality,
    List<String>? acceptDescription,
    List<FormatDescription>? supportFormats,
  }) {
    final qualityIndex = acceptQuality?.indexOf(streamId);
    if (qualityIndex != null &&
        qualityIndex >= 0 &&
        acceptDescription != null &&
        qualityIndex < acceptDescription.length &&
        acceptDescription[qualityIndex].isNotEmpty) {
      return acceptDescription[qualityIndex];
    }
    final format = supportFormats?.firstWhere(
      (format) => format.quality == streamId,
      orElse: () => FormatDescription(),
    );
    final description = format?.newDescription;
    if (description != null && description.isNotEmpty) return description;
    return height == null ? '' : '${height}P';
  }

  /// 只保留带可用地址的条目。缺地址的条目不能参与择优，否则会选中一条
  /// 不可播放的流而放弃同响应里可用的低档流。
  List<MediaStreamItem> _playable(List<MediaStreamItem>? items) {
    if (items == null) return [];
    return items.where((item) => item.playUrls.isNotEmpty).toList();
  }

  /// 选取视频流：优先按记忆的清晰度 id 精确匹配，其次按期望高度就近，最后取码率最高。
  ///
  /// 精确匹配优先是因为同高度可能有多路码率，按高度只能就近命中其中一路，
  /// 用户记住的「那一档」就丢了。id 取不到（该视频换了档位）时退回高度。
  ///
  /// 就近 = 与期望高度绝对差最小的一档，故期望高于全部可用档时自然落到
  /// 最高档、低于全部时落到最低档，无需为两种边界另写分支。缺高度的条目
  /// 视为不可比（差值无穷大），只在所有条目都缺高度时才被选中。
  MediaStreamItem _pickVideo(
    List<MediaStreamItem> items,
    int? preferHeight, [
    int? preferStreamId,
  ]) {
    if (preferStreamId != null) {
      for (final item in items) {
        if (item.id == preferStreamId) return item;
      }
    }
    if (preferHeight == null) return _highestBandwidth(items);
    return items.reduce((best, item) {
      final candidateGap = _heightGap(item, preferHeight);
      final bestGap = _heightGap(best, preferHeight);
      return candidateGap < bestGap ? item : best;
    });
  }

  int _heightGap(MediaStreamItem item, int preferHeight) {
    final height = item.height;
    return height == null ? 1 << 30 : (height - preferHeight).abs();
  }

  /// 取音频流。按码率最高择一，保证在解码能力有限的设备上能出声。
  MediaStreamItem _pickAudio(List<MediaStreamItem> items) =>
      _highestBandwidth(items);

  MediaStreamItem _highestBandwidth(List<MediaStreamItem> items) =>
      (items.toList()
            ..sort((a, b) => (a.bandwidth ?? 0).compareTo(b.bandwidth ?? 0)))
          .last;

  Duration? _milliseconds(int? value) =>
      value == null ? null : Duration(milliseconds: value);

  /// durl 分段在所有条目都有 order 时按 order 升序组装，相同 order 按响应
  /// 顺序处理；任一缺失 order 时保持响应顺序。每个片段只取首个可用地址，
  /// 备选地址是同一段的镜像而非新片段。
  List<MediaSegment> _segmentsOf(List<DurlData>? durl) {
    if (durl == null || durl.isEmpty) return [];
    final allHaveOrder = durl.every((item) => item.order != null);
    final List<DurlData> ordered;
    if (allHaveOrder) {
      final indexed = [for (var i = 0; i < durl.length; i++) (i, durl[i])];
      indexed.sort((a, b) {
        final byOrder = a.$2.order!.compareTo(b.$2.order!);
        return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
      });
      ordered = [for (final entry in indexed) entry.$2];
    } else {
      ordered = List<DurlData>.from(durl);
    }
    final segments = <MediaSegment>[];
    for (final item in ordered) {
      final rawUrl = item.playUrls.firstWhere(
        (candidate) => candidate.isNotEmpty,
        orElse: () => '',
      );
      final url = normalizeBiliUrl(rawUrl);
      // 任一片段无可用地址都会让播放层拿到残缺序列却无从察觉（播到该段
      // 才断），故整条流判为不可用，而不是跳过后返回缺片的列表。
      if (url == null || url.isEmpty) return [];
      segments.add(
        MediaSegment(
          url: url,
          // B站接口文档记 durl.length 为毫秒（与同响应的 timelength 同
          // 量纲）。仓内 fixture 的 durl 为空，该单位未经实响应验证，故
          // 为 null 时播放层须能退化为不声明时长。
          duration: item.length == null
              ? null
              : Duration(milliseconds: item.length!),
        ),
      );
    }
    return segments;
  }
}
