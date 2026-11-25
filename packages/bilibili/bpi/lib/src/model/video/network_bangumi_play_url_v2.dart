import '../bili_json_readers.dart';
import 'network_play_url.dart';

/// 番剧播放地址 v2 (`/pgc/player/web/v2/playurl`)。
///
/// v2 把 v1 的 `result` 拆成 `result.video_info`（播放流信息，与 v1 的
/// `result` 同构）和 `result.play_view_business_info`（剧集与付费状态）。
final class NetworkBangumiPlayUrlV2 {
  const NetworkBangumiPlayUrlV2({required this.videoInfo, this.episodeInfo});

  factory NetworkBangumiPlayUrlV2.fromJson(Map<String, dynamic> json) {
    final rawVideoInfo = json['video_info'];
    if (rawVideoInfo is! Map) {
      throw const FormatException(
        'Bangumi v2 playurl result is missing an object video_info field.',
      );
    }

    final business = json['play_view_business_info'];
    final rawEpisode = business is Map ? business['episode_info'] : null;

    return NetworkBangumiPlayUrlV2(
      videoInfo: NetworkPlayUrl.fromJson(
        Map<String, dynamic>.from(rawVideoInfo),
      ),
      episodeInfo: biliReadObject(
        rawEpisode,
        NetworkBangumiEpisodeInfo.tryFromJson,
      ),
    );
  }

  final NetworkPlayUrl videoInfo;
  final NetworkBangumiEpisodeInfo? episodeInfo;
}

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
