import 'package:freezed_annotation/freezed_annotation.dart';

import '../../network/model/search/concrete_results/network_video_search_result.dart'
import '../../network/model/search/common/network_bili_user_res.dart'

part 'video_info_base.freezed.dart';

@freezed
abstract class VideoInfoBase with _$VideoInfoBase {
  const factory VideoInfoBase({
    required String arcurl,
    required int aid,
    required String bvid,
    required String title,
    required String pic,
    required int play,
    required int pubdate,
    required String duration,
    required String desc,
    required String url,
    String? author,
  }) = _VideoInfoBase;
}

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoInfoBase asModel() => VideoInfoBase(
    arcurl: arcurl,
    author: author,
    aid: aid,
    bvid: bvid,
    title: title.parsedTitle(),
    pic: pic,
    play: play,
    pubdate: pubdate,
    duration: duration,
    isUnionVideo: isUnionVideo,
    desc: desc,
  );
}

extension NetworkBiliUserResX on NetworkBiliUserRes {
  VideoInfoBase asModel() => VideoInfoBase(
    arcurl: arcurl,
    aid: aid,
    bvid: bvid,
    title: title,
    pic: pic,
    play: play,
    pubdate: pubdate,
    duration: duration,
    isUnionVideo: isUnionVideo,
    desc: desc,
  );
}