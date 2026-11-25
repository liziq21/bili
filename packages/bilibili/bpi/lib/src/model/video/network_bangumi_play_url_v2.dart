import 'package:meta/meta.dart';

import '../bili_json_readers.dart';
import 'network_play_url.dart';

/// 番剧播放地址 v2 (`/pgc/player/web/v2/playurl`)。
///
/// v2 把 v1 的 `result` 拆成 `result.video_info`（播放流信息，与 v1 的
/// `result` 同构）和 `result.play_view_business_info`（剧集与付费状态）。
@immutable
final class NetworkBangumiPlayUrlV2 {
  const NetworkBangumiPlayUrlV2({
    required this.videoInfo,
    this.episodeInfo,
    this.playDetail,
    this.isPreview,
  });

  factory NetworkBangumiPlayUrlV2.fromJson(Map<String, dynamic> json) {
    final rawVideoInfo = json['video_info'];
    if (rawVideoInfo is! Map) {
      throw const FormatException(
        'Bangumi v2 playurl result is missing an object video_info field.',
      );
    }

    final business = json['play_view_business_info'];
    final rawEpisode = business is Map ? business['episode_info'] : null;
    final playCheck = json['play_check'];
    final rawPlayDetail = playCheck is Map ? playCheck['play_detail'] : null;

    return NetworkBangumiPlayUrlV2(
      videoInfo: NetworkPlayUrl.fromJson(
        Map<String, dynamic>.from(rawVideoInfo),
      ),
      episodeInfo: biliReadObject(
        rawEpisode,
        NetworkBangumiEpisodeInfo.tryFromJson,
      ),
      playDetail: biliReadString(rawPlayDetail),
      isPreview: switch (biliReadInt(rawVideoInfo['is_preview'])) {
        0 => false,
        1 => true,
        _ => null,
      },
    );
  }

  final NetworkPlayUrl videoInfo;
  final NetworkBangumiEpisodeInfo? episodeInfo;

  /// `play_check.play_detail`, for example `PLAY_PREVIEW` when only a preview
  /// stream is available. `video_info.timelength` still reports the full
  /// episode length in that case.
  final String? playDetail;

  /// `video_info.is_preview`, the same trial-play flag as an explicit bool.
  final bool? isPreview;
}

@immutable
final class NetworkBangumiEpisodeInfo {
  const NetworkBangumiEpisodeInfo({
    this.aid,
    this.bvid,
    this.cid,
    this.epId,
    this.title,
    this.longTitle,
    this.epStatus,
  });

  static NetworkBangumiEpisodeInfo? tryFromJson(Map<dynamic, dynamic> json) {
    final info = NetworkBangumiEpisodeInfo(
      aid: biliReadInt(json['aid']),
      bvid: biliReadString(json['bvid']),
      cid: biliReadInt(json['cid']),
      epId: biliReadInt(json['ep_id']),
      title: biliReadString(json['title']),
      longTitle: biliReadString(json['long_title']),
      epStatus: biliReadInt(json['ep_status']),
    );
    if (info.aid == null && info.bvid == null && info.epId == null) {
      return null;
    }
    return info;
  }

  final int? aid;
  final String? bvid;
  final int? cid;
  final int? epId;
  final String? title;
  final String? longTitle;
  final int? epStatus;
}
