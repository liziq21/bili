import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../bili_utils.dart';
import 'bili_remote_data_source.dart';

/// B站直播间详情与直播流地址数据源。
///
/// 把 B 站的直播间详情 DTO（`NetworkLiveRoomDetail`）与播放信息
/// （`NetworkLiveRoomPlayInfo`）收敛为中立的 [LiveRoomDetail] 与
/// [MediaStream]，app 层不感知 B 站的 roomInfo/anchorInfo/watchedShow
/// 与 playurl 嵌套结构。
final class BiliLiveRoomDetailRemoteDataSource({
  required final NetworkLiveDataSource network,
  required final String browserUserAgent,
}) extends LiveRoomDetailRemoteDataSource with BiliRemoteDataSource {
  Map<String, String> get _headers => {
    'User-Agent': browserUserAgent,
    'Referer': 'https://www.bilibili.com/',
  };

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    try {
      if (roomId <= 0) {
        return Result.error(Exception('Live room ID must be positive'));
      }
      final detail = await network.getLiveRoomDetail(roomId: roomId);
      final roomInfo = detail.roomInfo;
      if (roomInfo == null) {
        return Result.error(Exception('直播间 $roomId 未返回房间信息'));
      }
      final anchorName = detail.anchorInfo?.baseInfo?.uname ?? '未知主播';
      final online = detail.watchedShow?.num ?? roomInfo.online ?? 0;
      final isLive = roomInfo.liveStatus == 1;
      return Result.success(
        LiveRoomDetail(
          roomId: roomId,
          title: roomInfo.title ?? '未知标题',
          anchorName: anchorName,
          online: online,
          coverUrl: normalizeBiliUrl(roomInfo.cover),
          isLive: isLive,
          areaName: roomInfo.parentAreaName ?? roomInfo.areaName,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(
    int roomId, {
    int? preferQn,
  }) async {
    try {
      if (roomId <= 0) {
        return Result.error(Exception('Live room ID must be positive'));
      }
      // 切清晰度 = 带 qn 重新请求：响应里对应档的 codec 条目带着该档的
      // 流地址（其 currentQn 即目标档）。preferQn 为 null 时沿用默认档。
      final playInfo = await network.getLiveRoomPlayInfo(
        roomId: roomId,
        qn: preferQn ?? 10000,
      );
      final playurl = playInfo.playurlInfo?.playurl;
      if (playurl == null || playurl.stream.isEmpty) {
        return Result.error(Exception('直播间 $roomId 未返回可用流'));
      }

      // 优先 HLS（mpv 原生支持），退回第一个可用流。
      final hlsStream = playurl.stream.firstWhere(
        (s) => s.protocolName == 'http_hls',
        orElse: () => playurl.stream.first,
      );
      final format = hlsStream.format.first;
      final codec = format.codec.first;
      if (codec.baseUrl == null || codec.urlInfo.isEmpty) {
        return Result.error(Exception('直播间 $roomId 未返回流地址'));
      }
      final urlInfo = codec.urlInfo.first;
      final rawVideoUrl = '${urlInfo.host}${codec.baseUrl}${urlInfo.extra}';
      final videoUrl = normalizeBiliUrl(rawVideoUrl) ?? rawVideoUrl;

      final currentQn = codec.currentQn;
      return Result.success(
        MediaStream(
          videoUrl: videoUrl,
          headers: _headers,
          // qn 是直播档的源侧身份：记忆「上次选了哪一档」与界面标记当前
          // 档都用它，与点播的 dash video id 同位。
          streamId: currentQn,
          qualityLabel: _qualityLabel(playurl.gQnDesc, currentQn),
          alternatives: _qualityOptions(
            gQnDesc: playurl.gQnDesc,
            acceptQn: codec.acceptQn,
            currentQn: currentQn,
          ),
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// gQnDesc 里 qn → 可读描述。找不到时退回 `{qn}`，保证标签非空。
  String _qualityLabel(List<NetworkLiveQualityDescription> gQnDesc, int? qn) {
    if (qn == null) return '';
    final description = gQnDesc.firstWhere(
      (item) => item.qn == qn,
      orElse: () => NetworkLiveQualityDescription(qn: qn, desc: null),
    );
    return description.desc ?? '$qn';
  }

  /// 可切换档位列表：acceptQn 与 gQnDesc 的交集，排除当前档，保持
  /// gQnDesc 顺序（源侧即清晰度降序）。
  List<MediaQualityOption> _qualityOptions({
    required List<NetworkLiveQualityDescription> gQnDesc,
    required List<int> acceptQn,
    required int? currentQn,
  }) {
    return gQnDesc
        .where(
          (item) =>
              item.qn != null &&
              item.qn != currentQn &&
              acceptQn.contains(item.qn),
        )
        .map(
          (item) => MediaQualityOption(
            streamId: item.qn,
            label: item.desc ?? '${item.qn}',
          ),
        )
        .toList();
  }
}
