import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

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
  @override
  Future<Result<MediaStream>> getMediaStream(
    String videoId, {
    int? preferHeight,
  }) async {
    try {
      // B站的播放地址按分P（cid）下发，而能力接口收的是媒体标识（bvid），
      // 故先取详情取首个分P的 cid。
      final detail = await network.getVideoDetail(bvid: videoId);
      final pages = detail.pages;
      if (pages == null || pages.isEmpty) {
        return Result.error(Exception('视频 $videoId 没有可用分P，无法解析播放地址'));
      }
      final cid = pages.first.cid;

      final playUrl = await network.getPlayUrl(bvid: videoId, cid: cid);

      final dash = playUrl.dash;
      if (dash != null) {
        final videoItems = _playable(dash.video);
        if (videoItems.isNotEmpty) {
          return _fromDash(videoId, dash, videoItems, preferHeight);
        }
      }

      final segments = _segmentsOf(playUrl.durl);
      if (segments.isNotEmpty) {
        return Result.ok(
          MediaStream(
            videoUrl: segments.first.url,
            headers: _headers,
            segments: segments,
            duration: _milliseconds(playUrl.timelength),
          ),
        );
      }

      return Result.error(Exception('视频 $videoId 未返回可播放的流'));
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
  Result<MediaStream> _fromDash(
    String videoId,
    DashData dash,
    List<MediaStreamItem> videoItems,
    int? preferHeight,
  ) {
    final audioItems = _playable(dash.audio);
    if (audioItems.isEmpty) {
      return Result.error(Exception('视频 $videoId 的分离流缺少可用音轨'));
    }

    final video = _pickVideo(videoItems, preferHeight);
    final audio = _pickAudio(audioItems);

    return Result.ok(
      MediaStream(
        videoUrl: video.playUrls.first,
        audioUrl: audio.playUrls.first,
        headers: _headers,
        width: video.width,
        height: video.height,
        bitrate: video.bandwidth,
        codecs: video.codecs,
        // dash.duration 以秒计，与视频详情的 duration 同量纲。
        duration: dash.duration == null
            ? null
            : Duration(seconds: dash.duration!),
      ),
    );
  }

  /// 只保留带可用地址的条目。缺地址的条目不能参与择优，否则会选中一条
  /// 不可播放的流而放弃同响应里可用的低档流。
  List<MediaStreamItem> _playable(List<MediaStreamItem>? items) {
    if (items == null) return [];
    return items.where((item) => item.playUrls.isNotEmpty).toList();
  }

  /// 按期望高度就近选取视频流，缺省取码率最高的一路。
  ///
  /// 就近 = 与期望高度绝对差最小的一档，故期望高于全部可用档时自然落到
  /// 最高档、低于全部时落到最低档，无需为两种边界另写分支。缺高度的条目
  /// 视为不可比（差值无穷大），只在所有条目都缺高度时才被选中。
  MediaStreamItem _pickVideo(List<MediaStreamItem> items, int? preferHeight) {
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
      final url = item.playUrls.firstWhere(
        (candidate) => candidate.isNotEmpty,
        orElse: () => '',
      );
      // 任一片段无可用地址都会让播放层拿到残缺序列却无从察觉（播到该段
      // 才断），故整条流判为不可用，而不是跳过后返回缺片的列表。
      if (url.isEmpty) return [];
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
