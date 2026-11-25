import 'dart:convert';

import '../device/bili_device_fingerprint.dart';
import '../model/reply/network_reply_data.dart';
import '../model/reply/network_reply_reply_data.dart';
import '../model/video/network_bangumi_play_url_v2.dart';
import '../model/video/network_bangumi_season.dart';
import '../model/video/network_bili_danmaku.dart';
import '../model/video/network_bili_player_info.dart';
import '../model/video/network_bili_video_parts.dart';
import '../model/video/network_bili_video_snapshot.dart';
import '../model/video/network_bili_video_tags.dart';
import '../model/video/network_play_url.dart';
import '../model/video/network_related_video.dart';
import '../model/video/network_video_relation.dart';
import '../model/video/video_detail_data.dart';
import '../network_video_data_source.dart';
import 'bili_network_client.dart';

mixin VideoEndpoints on BiliNetworkClient implements NetworkVideoDataSource {
  @override
  Future<NetworkBiliVideoParts> getVideoParts({required String bvid}) =>
      api.getVideoParts(bvid: bvid);

  @override
  Future<NetworkBiliVideoSnapshot> getVideoSnapshot({required String bvid}) =>
      api.getVideoSnapshot(bvid: bvid);

  @override
  Future<NetworkBiliVideoTags> getVideoTags({required String bvid}) =>
      api.getVideoTags(bvid: bvid);

  @override
  Future<NetworkBangumiPlayUrlV2> getBangumiPlayUrlV2({
    int? epId,
    int? cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) => api.getBangumiPlayUrlV2(
    epId: epId,
    cid: cid,
    qn: qn,
    fnval: fnval,
    fourk: fourk,
  );

  @override
  Future<NetworkBangumiSeasonData> getBangumiSeason({
    int? seasonId,
    int? epId,
  }) => api.getBangumiSeason(seasonId: seasonId, epId: epId);

  @override
  Future<NetworkPlayUrl> getBangumiPlayUrl({
    int? epId,
    int? cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) => api.getBangumiPlayUrl(
    epId: epId,
    cid: cid,
    qn: qn,
    fnval: fnval,
    fourk: fourk,
  );

  @override
  Future<VideoDetailData> getVideoDetail({required String bvid}) =>
      api.videoIntro(bvid: bvid);

  @override
  Future<NetworkVideoRelation> getVideoRelation({required String bvid}) =>
      api.getVideoRelation(bvid: bvid);

  @override
  Future<List<NetworkRelatedVideo>> getRelatedVideos({
    required String bvid,
  }) async {
    final response = await api.getRelatedVideos(bvid: bvid);
    return response.items;
  }

  @override
  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int page = 1,
    int sort = 1,
    String? nextOffset,
  }) {
    if (nextOffset != null && nextOffset.isNotEmpty) {
      // Built through jsonEncode rather than interpolation: the offset comes
      // from the server and may carry backslashes or control characters, and
      // escaping quotes alone leaves those producing a malformed parameter.
      final paginationStr = jsonEncode(<String, String>{'offset': nextOffset});
      return api.getReplyListMain(
        oid: oid,
        type: type,
        paginationStr: paginationStr,
        mode: sort + 2,
      );
    }
    return api.getReplyList(oid: oid, type: type, page: page, sort: sort);
  }

  @override
  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int page = 1,
  }) => api.getReplyReplyList(
    oid: oid,
    root: root,
    type: type,
    page: page,
    sort: 1,
  );

  @override
  Future<NetworkPlayUrl> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) => api.getPlayUrl(
    bvid,
    cid,
    qn: qn,
    fnval: fnval,
    fourk: fourk,
    dmImgList: BiliDeviceFingerprint.dmImgList,
    dmImgStr: device.dmImgStr,
    dmCoverImgStr: device.dmCoverImgStr,
    dmImgInter: device.dmImgInter,
  );

  @override
  Future<NetworkBiliPlayerInfo> getPlayerInfo({
    required String bvid,
    required int cid,
  }) => api.getPlayerInfo(bvid: bvid, cid: cid);

  @override
  Future<NetworkBiliDanmakuDocument> getDanmaku({required int cid}) =>
      danmaku.fetch(cid: cid);
}
