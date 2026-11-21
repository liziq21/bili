import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:ypi/ypi.dart';

import 'youtube_remote_data_source.dart';

/// YouTube 播放地址桥接：InnerTube `player` 端点 → [MediaStream]。
///
/// player 默认使用 iOS client，其 `adaptiveFormats` 直接携带 `url`，无需执行
/// player JS 解密签名。音视频在该响应里是分离的，故按 DASH 形态返回
/// `audioUrl`，由播放层拼虚拟媒体。拿不到可用的分离流时退回 `hlsManifestUrl`。
final class YouTubeMediaStreamRemoteDataSource(
  final YoutubeService _youtubeService,
  final String _userAgent,
) extends MediaStreamRemoteDataSource with YouTubeRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _codecsPattern = RegExp(r'codecs="([^"]+)"');

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

      final response = await _youtubeService.getPlayer(sanitizedVideoId);
      final streamingData = response.streamingData;
      if (streamingData == null) {
        return Result.error(
          Exception('Video $sanitizedVideoId returned no streaming data'),
        );
      }

      final videoFormats = _playable(streamingData.adaptiveFormats, 'video/');
      final audioFormats = _playable(streamingData.adaptiveFormats, 'audio/');

      if (videoFormats.isNotEmpty && audioFormats.isNotEmpty) {
        final video = _pickVideo(
          videoFormats,
          preferHeight: preferHeight,
          preferStreamId: preferStreamId,
        );
        final audio = _pickAudio(audioFormats);
        return Result.success(
          MediaStream(
            videoUrl: video.url!,
            audioUrl: audio.url,
            headers: _headers,
            width: video.width,
            height: video.height,
            bitrate: video.bitrate,
            streamId: video.itag,
            qualityLabel: _qualityLabel(video),
            codecs: _codecsOf(video.mimeType),
            duration: _durationOf(response.videoDetails?.lengthSeconds),
            alternatives: _qualityOptions(videoFormats, current: video),
          ),
        );
      }

      final hlsManifestUrl = streamingData.hlsManifestUrl;
      if (hlsManifestUrl != null && hlsManifestUrl.isNotEmpty) {
        return Result.success(
          MediaStream(
            videoUrl: hlsManifestUrl,
            headers: _headers,
            duration: _durationOf(response.videoDetails?.lengthSeconds),
          ),
        );
      }

      return Result.error(
        Exception('Video $sanitizedVideoId returned no playable stream'),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  Map<String, String> get _headers => {'User-Agent': _userAgent};

  List<NetworkYouTubeStreamFormat> _playable(
    List<NetworkYouTubeStreamFormat> formats,
    String mimePrefix,
  ) {
    return formats
        .where(
          (format) =>
              format.mimeType?.startsWith(mimePrefix) == true &&
              (format.url?.isNotEmpty ?? false),
        )
        .toList(growable: false);
  }

  /// 选取视频轨：优先按记忆的 itag 精确匹配，其次按期望高度就近。
  ///
  /// 未指定偏好时优先选 h264（`avc1`）中分辨率最高的一档：h264 的解码支持
  /// 面最广，而 2160P 档位通常只有 VP9/AV1。所有档位仍会出现在
  /// [MediaStream.alternatives] 里，用户可主动选择更高画质。
  NetworkYouTubeStreamFormat _pickVideo(
    List<NetworkYouTubeStreamFormat> formats, {
    int? preferHeight,
    int? preferStreamId,
  }) {
    if (preferStreamId != null) {
      for (final format in formats) {
        if (format.itag == preferStreamId) return format;
      }
    }

    if (preferHeight != null) {
      return formats.reduce((best, format) {
        final gap = _heightGap(format, preferHeight);
        final bestGap = _heightGap(best, preferHeight);
        if (gap != bestGap) return gap < bestGap ? format : best;
        return _isBetterFormat(format, best) ? format : best;
      });
    }

    final avcFormats = formats
        .where((format) => format.mimeType?.contains('avc1') == true)
        .toList(growable: false);
    final pool = avcFormats.isEmpty ? formats : avcFormats;
    return pool.reduce((best, format) {
      final height = format.height ?? 0;
      final bestHeight = best.height ?? 0;
      if (height != bestHeight) return height > bestHeight ? format : best;
      return _isBetterFormat(format, best) ? format : best;
    });
  }

  NetworkYouTubeStreamFormat _pickAudio(
    List<NetworkYouTubeStreamFormat> formats,
  ) => formats.reduce(
    (best, format) =>
        (format.bitrate ?? 0) > (best.bitrate ?? 0) ? format : best,
  );

  int _heightGap(NetworkYouTubeStreamFormat format, int preferHeight) =>
      format.height == null ? 1 << 30 : (format.height! - preferHeight).abs();

  bool _isBetterFormat(
    NetworkYouTubeStreamFormat candidate,
    NetworkYouTubeStreamFormat current,
  ) {
    final candidateIsAvc = candidate.mimeType?.contains('avc1') == true;
    final currentIsAvc = current.mimeType?.contains('avc1') == true;
    if (candidateIsAvc != currentIsAvc) return candidateIsAvc;
    return (candidate.bitrate ?? 0) > (current.bitrate ?? 0);
  }

  /// 把可选视频轨收敛成 UI 画质列表：同一高度只保留最优的一路，去掉当前档。
  List<MediaQualityOption> _qualityOptions(
    List<NetworkYouTubeStreamFormat> formats, {
    required NetworkYouTubeStreamFormat current,
  }) {
    final bestByHeight = <int, NetworkYouTubeStreamFormat>{};
    for (final format in formats) {
      final height = format.height;
      if (height == null || height == current.height) continue;
      final existing = bestByHeight[height];
      if (existing == null || _isBetterFormat(format, existing)) {
        bestByHeight[height] = format;
      }
    }

    final options = [
      for (final entry in bestByHeight.entries)
        MediaQualityOption(
          height: entry.key,
          label: _qualityLabel(entry.value),
          streamId: entry.value.itag,
          bitrate: entry.value.bitrate,
        ),
    ];
    options.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return options;
  }

  String _qualityLabel(NetworkYouTubeStreamFormat format) {
    final label = format.qualityLabel;
    if (label != null && label.isNotEmpty) return label;
    return format.height == null ? '' : '${format.height}P';
  }

  String? _codecsOf(String? mimeType) {
    if (mimeType == null) return null;
    return _codecsPattern.firstMatch(mimeType)?.group(1);
  }

  Duration? _durationOf(String? lengthSeconds) {
    final seconds = int.tryParse(lengthSeconds ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
