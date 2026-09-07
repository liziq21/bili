import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title.parsedTitle(),
    url: arcurl,
    thumbnailUrl: 'https:$pic',
    viewCount: play,
    uploadDate: DateTime.fromMillisecondsSinceEpoch(pubdate * 1000),
    duration: int.tryParse(duration),
    desc: desc,
    creatorProfileName: author,
  );
}

extension NetworkBiliUserResX on NetworkBiliUserRes {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title,
    url: arcurl,
    thumbnailUrl: 'https:$pic',
    viewCount: int.tryParse(play),
    uploadDate: DateTime.fromMillisecondsSinceEpoch(pubdate * 1000),
    duration: int.tryParse(duration),
    desc: desc,
  );
}
