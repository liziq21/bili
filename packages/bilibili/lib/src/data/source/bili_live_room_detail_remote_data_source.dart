import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

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
          coverUrl: roomInfo.cover,
          isLive: isLive,
          areaName: roomInfo.parentAreaName ?? roomInfo.areaName,
        ),
      );
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) async {
    try {
      final playInfo = await network.getLiveRoomPlayInfo(roomId: roomId);
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
      final videoUrl = '${urlInfo.host}${codec.baseUrl}${urlInfo.extra}';

      return Result.success(MediaStream(videoUrl: videoUrl, headers: _headers));
    } catch (e) {
      return Result.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}
