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

extension NetworkBiliPopularVideoX on NetworkBiliPopularVideo {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title ?? bvid,
    url: 'https://www.bilibili.com/video/$bvid',
    thumbnailUrl: _normalizeBiliUrl(pic),
    viewCount: stat?.view,
    uploadDate: pubdate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(pubdate! * 1000),
    duration: duration,
    creatorProfileName: owner?.name,
    creatorProfileId: owner?.mid?.toString(),
  );
}

String? _normalizeBiliUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  return value.startsWith('http://') ? 'https://${value.substring(7)}' : value;
}
