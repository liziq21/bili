import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import '../../bili_utils.dart';

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title.parsedTitle(),
    url: normalizeBiliUrl(arcurl) ?? buildBiliWatchUrl(bvid),
    thumbnailUrl: normalizeBiliUrl(pic),
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
    url: normalizeBiliUrl(arcurl) ?? buildBiliWatchUrl(bvid),
    thumbnailUrl: normalizeBiliUrl(pic),
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
    url: buildBiliWatchUrl(bvid),
    thumbnailUrl: normalizeBiliUrl(pic),
    viewCount: stat?.view,
    uploadDate: pubdate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(pubdate! * 1000),
    duration: duration,
    creatorProfileName: owner?.name,
    creatorProfileId: owner?.mid?.toString(),
  );
}

extension NetworkBiliUserVideoItemX on NetworkBiliUserVideoItem {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title ?? bvid,
    url: buildBiliWatchUrl(bvid),
    thumbnailUrl: normalizeBiliUrl(pic),
    viewCount: play,
    uploadDate: created == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(created! * 1000),
    duration: _parseDuration(length),
    desc: description,
    creatorProfileName: author,
    creatorProfileId: mid?.toString(),
  );
}

extension NetworkBiliPlaylistVideoItemX on NetworkBiliPlaylistVideoItem {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title ?? bvid,
    url: buildBiliWatchUrl(bvid),
    thumbnailUrl: normalizeBiliUrl(pic),
    viewCount: play,
    uploadDate: switch (pubdate ?? created) {
      final timestamp? => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      null => null,
    },
    duration: _parseDuration(length),
    desc: description,
    creatorProfileName: author,
    creatorProfileId: mid?.toString(),
  );
}

int? _parseDuration(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length == 1) return int.tryParse(value);

  var seconds = 0;
  for (final part in parts) {
    final component = int.tryParse(part);
    if (component == null) return null;
    seconds = seconds * 60 + component;
  }
  return seconds;
}
