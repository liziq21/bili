import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_video_search_result.freezed.dart';

@freezed
abstract class VideoSearchResult with _$VideoSearchResult {
  const factory VideoSearchResult({
    required int id,
    required String author,
    required int mid,
    required String typeid,
    required String typename,
    required String arcurl,
    required int aid,
    required String bvid,
    required String title,
    required String description,
    required String pic,
    required int play,
    required int favorites,
    required String tag,
    required int review,
    required int pubdate,
    required int senddate,
    required String duration,
    required bool badgepay,
    required int isUnionVideo,
    required int like,
    required String upic,
    required String corner,
    required String cover,
    required String desc,
    required String url,
    required int danmaku,
  }) = _VideoSearchResult;
}

extension NetworkVideoSearchResultX on NetworkVideoSearchResult {
  VideoSearchResult asModel() => VideoSearchResult(
    id: id,
    author: author,
    mid: mid,
    typeid: typeid,
    typename: typename,
    arcurl: arcurl,
    aid: aid,
    bvid: bvid,
    title: title.parsedTitle(),
    description: description,
    pic: pic,
    play: play,
    favorites: favorites,
    tag: tag,
    review: review,
    pubdate: pubdate,
    senddate: senddate,
    duration: duration,
    badgepay: badgepay,
    isUnionVideo: isUnionVideo,
    like: like,
    upic: upic,
    corner: corner,
    cover: cover,
    desc: desc,
    url: url,
    danmaku: danmaku,
  );
}