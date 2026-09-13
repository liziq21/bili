import 'model/reply/network_reply_data.dart';
import 'model/reply/network_reply_reply_data.dart';
import 'model/video/network_play_url.dart';
import 'model/video/network_related_video.dart';
import 'model/video/network_video_relation.dart';
import 'model/video/video_detail_data.dart';

abstract interface class NetworkVideoDataSource {
  Future<VideoDetailData> getVideoDetail({required String bvid});

  Future<NetworkVideoRelation> getVideoRelation({required String bvid});

  Future<List<NetworkRelatedVideo>> getRelatedVideos({required String bvid});

  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int page = 1,
    int sort = 1,
    String? nextOffset,
  });

  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int page = 1,
  });

  Future<NetworkPlayUrl> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  });
}
