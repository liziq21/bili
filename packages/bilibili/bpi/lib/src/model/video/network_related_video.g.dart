// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_related_video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkRelatedVideosList _$NetworkRelatedVideosListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkRelatedVideosList', json, ($checkedConvert) {
  final val = NetworkRelatedVideosList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => NetworkRelatedVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

NetworkRelatedVideo _$NetworkRelatedVideoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkRelatedVideo',
  json,
  ($checkedConvert) {
    final val = NetworkRelatedVideo(
      aid: $checkedConvert('aid', (v) => (v as num).toInt()),
      bvid: $checkedConvert('bvid', (v) => v as String),
      cid: $checkedConvert('cid', (v) => (v as num?)?.toInt()),
      title: $checkedConvert('title', (v) => v as String?),
      pic: $checkedConvert('pic', (v) => v as String?),
      desc: $checkedConvert('desc', (v) => v as String?),
      duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
      pubdate: $checkedConvert('pubdate', (v) => (v as num?)?.toInt()),
      ctime: $checkedConvert('ctime', (v) => (v as num?)?.toInt()),
      owner: $checkedConvert(
        'owner',
        (v) => v == null ? null : Owner.fromJson(v as Map<String, dynamic>),
      ),
      stat: $checkedConvert(
        'stat',
        (v) => v == null ? null : VideoStat.fromJson(v as Map<String, dynamic>),
      ),
      dimension: $checkedConvert(
        'dimension',
        (v) => v == null ? null : Dimension.fromJson(v as Map<String, dynamic>),
      ),
      firstFrame: $checkedConvert('first_frame', (v) => v as String?),
      shortLink: $checkedConvert('short_link', (v) => v as String?),
      redirectUrl: $checkedConvert('redirect_url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstFrame': 'first_frame',
    'shortLink': 'short_link',
    'redirectUrl': 'redirect_url',
  },
);
