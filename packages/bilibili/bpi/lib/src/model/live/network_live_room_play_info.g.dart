// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_live_room_play_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkLiveRoomPlayInfo _$NetworkLiveRoomPlayInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveRoomPlayInfo',
  json,
  ($checkedConvert) {
    final val = NetworkLiveRoomPlayInfo(
      roomId: $checkedConvert('room_id', (v) => (v as num).toInt()),
      shortId: $checkedConvert('short_id', (v) => (v as num?)?.toInt()),
      uid: $checkedConvert('uid', (v) => (v as num?)?.toInt()),
      liveStatus: $checkedConvert('live_status', (v) => (v as num?)?.toInt()),
      liveTime: $checkedConvert('live_time', (v) => (v as num?)?.toInt()),
      playurlInfo: $checkedConvert(
        'playurl_info',
        (v) => v == null
            ? null
            : NetworkLivePlayurlInfo.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'roomId': 'room_id',
    'shortId': 'short_id',
    'liveStatus': 'live_status',
    'liveTime': 'live_time',
    'playurlInfo': 'playurl_info',
  },
);

NetworkLivePlayurlInfo _$NetworkLivePlayurlInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLivePlayurlInfo', json, ($checkedConvert) {
  final val = NetworkLivePlayurlInfo(
    confJson: $checkedConvert('conf_json', (v) => v as String?),
    playurl: $checkedConvert(
      'playurl',
      (v) => v == null
          ? null
          : NetworkLivePlayurlData.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'confJson': 'conf_json'});

NetworkLivePlayurlData _$NetworkLivePlayurlDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLivePlayurlData', json, ($checkedConvert) {
  final val = NetworkLivePlayurlData(
    cid: $checkedConvert('cid', (v) => (v as num?)?.toInt()),
    gQnDesc: $checkedConvert(
      'g_qn_desc',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => NetworkLiveQualityDescription.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    ),
    stream: $checkedConvert(
      'stream',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => NetworkLiveStream.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    ),
  );
  return val;
}, fieldKeyMap: const {'gQnDesc': 'g_qn_desc'});

NetworkLiveQualityDescription _$NetworkLiveQualityDescriptionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveQualityDescription', json, ($checkedConvert) {
  final val = NetworkLiveQualityDescription(
    qn: $checkedConvert('qn', (v) => (v as num?)?.toInt()),
    desc: $checkedConvert('desc', (v) => v as String?),
  );
  return val;
});

NetworkLiveStream _$NetworkLiveStreamFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkLiveStream', json, ($checkedConvert) {
      final val = NetworkLiveStream(
        protocolName: $checkedConvert('protocol_name', (v) => v as String?),
        format: $checkedConvert(
          'format',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => NetworkLiveStreamFormat.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              const [],
        ),
      );
      return val;
    }, fieldKeyMap: const {'protocolName': 'protocol_name'});

NetworkLiveStreamFormat _$NetworkLiveStreamFormatFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveStreamFormat', json, ($checkedConvert) {
  final val = NetworkLiveStreamFormat(
    formatName: $checkedConvert('format_name', (v) => v as String?),
    codec: $checkedConvert(
      'codec',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) =>
                    NetworkLiveStreamCodec.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    ),
  );
  return val;
}, fieldKeyMap: const {'formatName': 'format_name'});

NetworkLiveStreamCodec _$NetworkLiveStreamCodecFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveStreamCodec',
  json,
  ($checkedConvert) {
    final val = NetworkLiveStreamCodec(
      codecName: $checkedConvert('codec_name', (v) => v as String?),
      currentQn: $checkedConvert('current_qn', (v) => (v as num?)?.toInt()),
      acceptQn: $checkedConvert(
        'accept_qn',
        (v) =>
            (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
            const [],
      ),
      baseUrl: $checkedConvert('base_url', (v) => v as String?),
      urlInfo: $checkedConvert(
        'url_info',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => NetworkLiveUrlInfo.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'codecName': 'codec_name',
    'currentQn': 'current_qn',
    'acceptQn': 'accept_qn',
    'baseUrl': 'base_url',
    'urlInfo': 'url_info',
  },
);

NetworkLiveUrlInfo _$NetworkLiveUrlInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkLiveUrlInfo', json, ($checkedConvert) {
      final val = NetworkLiveUrlInfo(
        host: $checkedConvert('host', (v) => v as String?),
        extra: $checkedConvert('extra', (v) => v as String?),
        streamTtl: $checkedConvert('stream_ttl', (v) => (v as num?)?.toInt()),
      );
      return val;
    }, fieldKeyMap: const {'streamTtl': 'stream_ttl'});
