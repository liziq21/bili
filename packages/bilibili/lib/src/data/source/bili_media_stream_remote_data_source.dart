import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import 'bili_remote_data_source.dart';

/// B站播放地址数据源
///
/// 把 B站的两类地址形态（DASH 分离流与 durl 分段）收敛成中立的
/// [MediaStream]：分离流给出 audioUrl 由播放层拼虚拟媒体；durl 形态取
/// 首段并把已含声音的地址放进 videoUrl，播放层无需区分。
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
        return Result.error(
          Exception('视频 $videoId 没有可用分P，无法解析播放地址'),
        );
      }
      final cid = pages.first.cid;

      final playUrl = await network.getPlayUrl(bvid: videoId, cid: cid);

      final dash = playUrl.dash;
      final durl = playUrl.durl;

      if (dash != null && (dash.video?.isNotEmpty ?? false)) {
        final video = _pickVideo(dash.video!, preferHeight);
        final audio = _pickAudio(dash.audio);
        if (video == null) {
          return Result.error(Exception('视频 $videoId 没有可用的视频流'));
        }
        final videoUrls = video.playUrls.toList();
        if (videoUrls.isEmpty) {
          return Result.error(Exception('视频 $videoId 的视频流缺少地址'));
        }
        return Result.ok(
          MediaStream(
            videoUrl: videoUrls.first,
            audioUrl: audio?.playUrls.firstOrNull,
            headers: _headers,
            width: video.width,
            height: video.height,
            bitrate: video.bandwidth,
            codecs: video.codecs,
            duration: dash.duration == null
                ? null
                : Duration(milliseconds: dash.duration!),
          ),
        );
      }

      if (durl != null && durl.isNotEmpty) {
        final urls = durl
            .expand((item) => item.playUrls)
            .where((url) => url.isNotEmpty)
            .toList();
        if (urls.isEmpty) {
          return Result.error(Exception('视频 $videoId 没有可用的播放地址'));
        }
        return Result.ok(
          MediaStream(
            videoUrl: urls.first,
            headers: _headers,
            duration: durl.first.length == null
                ? null
                : Duration(seconds: durl.first.length!),
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

  /// 按期望高度就近选取视频流，缺省取码率最高的一路。
  MediaStreamItem? _pickVideo(List<MediaStreamItem> items, int? preferHeight) {
    if (items.isEmpty) return null;
    if (preferHeight != null) {
      final notTaller = items
          .where((item) => (item.height ?? 0) <= preferHeight)
          .toList();
      if (notTaller.isNotEmpty) {
        notTaller.sort((a, b) => (a.height ?? 0).compareTo(b.height ?? 0));
        return notTaller.last;
      }
      // 全部高于期望时退而求其次取最低的一路。
      final sorted = [...items]
        ..sort((a, b) => (a.height ?? 0).compareTo(b.height ?? 0));
      return sorted.first;
    }
    final byBandwidth = [...items]
      ..sort(
        (a, b) => (a.bandwidth ?? 0).compareTo(b.bandwidth ?? 0),
      );
    return byBandwidth.last;
  }

  /// 取音频流；有 Dolby/FLAC 等更高级编码时仍优先取主音轨，此处按码率
  /// 最高择一，保证在解码能力有限的设备上能出声。
  MediaStreamItem? _pickAudio(List<MediaStreamItem>? items) {
    if (items == null || items.isEmpty) return null;
    final sorted = [...items]
      ..sort(
        (a, b) => (a.bandwidth ?? 0).compareTo(b.bandwidth ?? 0),
      );
    return sorted.last;
  }
}