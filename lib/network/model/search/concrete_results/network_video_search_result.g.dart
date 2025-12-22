// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_video_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkVideoSearchResult _$NetworkVideoSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkVideoSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkVideoSearchResult(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      author: $checkedConvert('author', (v) => v as String),
      mid: $checkedConvert('mid', (v) => (v as num).toInt()),
      typeid: $checkedConvert('typeid', (v) => v as String),
      typename: $checkedConvert('typename', (v) => v as String),
      arcurl: $checkedConvert('arcurl', (v) => v as String),
      aid: $checkedConvert('aid', (v) => (v as num).toInt()),
      bvid: $checkedConvert('bvid', (v) => v as String),
      title: $checkedConvert('title', (v) => HtmlTitle.fromJson(v)),
      description: $checkedConvert('description', (v) => v as String),
      pic: $checkedConvert('pic', (v) => v as String),
      play: $checkedConvert('play', (v) => (v as num).toInt()),
      favorites: $checkedConvert('favorites', (v) => (v as num).toInt()),
      tag: $checkedConvert('tag', (v) => v as String),
      review: $checkedConvert('review', (v) => (v as num).toInt()),
      pubdate: $checkedConvert('pubdate', (v) => (v as num).toInt()),
      senddate: $checkedConvert('senddate', (v) => (v as num).toInt()),
      duration: $checkedConvert('duration', (v) => v as String),
      badgepay: $checkedConvert('badgepay', (v) => v as bool),
      isUnionVideo: $checkedConvert(
        'is_union_video',
        (v) => (v as num).toInt(),
      ),
      like: $checkedConvert('like', (v) => (v as num).toInt()),
      upic: $checkedConvert('upic', (v) => v as String),
      corner: $checkedConvert('corner', (v) => v as String),
      cover: $checkedConvert('cover', (v) => v as String),
      desc: $checkedConvert('desc', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      danmaku: $checkedConvert('danmaku', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'isUnionVideo': 'is_union_video'},
);
