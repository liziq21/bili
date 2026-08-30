import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoInfoBase asModel() => .new(
    arcurl: arcurl,
    author: author,
    aid: aid,
    bvid: bvid,
    title: title.parsedTitle(),
    picUrl: 'https:$pic',
    play: '$play',
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
    play: '$play',
    pubdate: pubdate,
    duration: duration,
    desc: desc,
  );
}
