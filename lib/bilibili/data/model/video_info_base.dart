import '../../network/model/search/concrete_results/network_video_search_result.dart';
import '../../network/model/search/common/network_bili_user_res.dart';
import '../../../data/model/video_info_base.dart';

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoInfoBase asModel() => .new(
    arcurl: arcurl,
    author: author,
    aid: aid,
    bvid: bvid,
    title: title.parsedTitle(),
    picUrl: 'https:$pic',
    play: play,
    pubdate: pubdate,
    duration: duration,
    desc: desc,
  );
}

extension NetworkBiliUserResX on NetworkBiliUserRes {
  VideoInfoBase asModel() => .new(
    arcurl: arcurl,
    aid: aid,
    bvid: bvid,
    title: title,
    picUrl: 'https:$pic',
    play: play,
    pubdate: pubdate,
    duration: duration,
    desc: desc,
  );
}
