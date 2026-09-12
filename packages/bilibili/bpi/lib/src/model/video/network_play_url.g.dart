// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_play_url.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkPlayUrl _$NetworkPlayUrlFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkPlayUrl',
  json,
  ($checkedConvert) {
    final val = NetworkPlayUrl(
      from: $checkedConvert('from', (v) => v as String?),
      result: $checkedConvert('result', (v) => v as String?),
      message: $checkedConvert('message', (v) => v as String?),
      quality: $checkedConvert('quality', (v) => (v as num?)?.toInt()),
      format: $checkedConvert('format', (v) => v as String?),
      timelength: $checkedConvert('timelength', (v) => (v as num?)?.toInt()),
      acceptFormat: $checkedConvert('accept_format', (v) => v as String?),
      acceptDescription: $checkedConvert(
        'accept_description',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      acceptQuality: $checkedConvert(
        'accept_quality',
        (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
      ),
      videoCodecid: $checkedConvert(
        'video_codecid',
        (v) => (v as num?)?.toInt(),
      ),
      dash: $checkedConvert(
        'dash',
        (v) => v == null ? null : DashData.fromJson(v as Map<String, dynamic>),
      ),
      durl: $checkedConvert(
        'durl',
        (v) => (v as List<dynamic>?)
            ?.map((e) => DurlData.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      supportFormats: $checkedConvert(
        'support_formats',
        (v) => (v as List<dynamic>?)
            ?.map((e) => FormatDescription.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      volume: $checkedConvert(
        'volume',
        (v) =>
            v == null ? null : VolumeData.fromJson(v as Map<String, dynamic>),
      ),
      lastPlayTime: $checkedConvert(
        'last_play_time',
        (v) => (v as num?)?.toInt(),
      ),
      lastPlayCid: $checkedConvert(
        'last_play_cid',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'acceptFormat': 'accept_format',
    'acceptDescription': 'accept_description',
    'acceptQuality': 'accept_quality',
    'videoCodecid': 'video_codecid',
    'supportFormats': 'support_formats',
    'lastPlayTime': 'last_play_time',
    'lastPlayCid': 'last_play_cid',
  },
);

DashData _$DashDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DashData', json, ($checkedConvert) {
      final val = DashData(
        duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
        minBufferTime: $checkedConvert(
          'min_buffer_time',
          (v) => (v as num?)?.toDouble(),
        ),
        video: $checkedConvert(
          'video',
          (v) => (v as List<dynamic>?)
              ?.map((e) => MediaStreamItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        audio: $checkedConvert(
          'audio',
          (v) => (v as List<dynamic>?)
              ?.map((e) => MediaStreamItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'minBufferTime': 'min_buffer_time'});

MediaStreamItem _$MediaStreamItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MediaStreamItem',
      json,
      ($checkedConvert) {
        final val = MediaStreamItem(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          baseUrl: $checkedConvert(
            'base_url',
            (v) => v as String?,
            readValue: _readBaseUrl,
          ),
          backupUrl: $checkedConvert(
            'backup_url',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
            readValue: _readBackupUrl,
          ),
          bandwidth: $checkedConvert('bandwidth', (v) => (v as num?)?.toInt()),
          mimeType: $checkedConvert('mime_type', (v) => v as String?),
          codecs: $checkedConvert('codecs', (v) => v as String?),
          width: $checkedConvert('width', (v) => (v as num?)?.toInt()),
          height: $checkedConvert('height', (v) => (v as num?)?.toInt()),
          frameRate: $checkedConvert('frame_rate', (v) => v as String?),
          sar: $checkedConvert('sar', (v) => v as String?),
          startWithSap: $checkedConvert(
            'start_with_sap',
            (v) => (v as num?)?.toInt(),
          ),
          codecid: $checkedConvert('codecid', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'baseUrl': 'base_url',
        'backupUrl': 'backup_url',
        'mimeType': 'mime_type',
        'frameRate': 'frame_rate',
        'startWithSap': 'start_with_sap',
      },
    );

DurlData _$DurlDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DurlData', json, ($checkedConvert) {
      final val = DurlData(
        order: $checkedConvert('order', (v) => (v as num?)?.toInt()),
        length: $checkedConvert('length', (v) => (v as num?)?.toInt()),
        size: $checkedConvert('size', (v) => (v as num?)?.toInt()),
        ahead: $checkedConvert('ahead', (v) => v as String?),
        vhead: $checkedConvert('vhead', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
        backupUrl: $checkedConvert(
          'backup_url',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          readValue: _readBackupUrl,
        ),
      );
      return val;
    }, fieldKeyMap: const {'backupUrl': 'backup_url'});

FormatDescription _$FormatDescriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'FormatDescription',
      json,
      ($checkedConvert) {
        final val = FormatDescription(
          quality: $checkedConvert('quality', (v) => (v as num?)?.toInt()),
          format: $checkedConvert('format', (v) => v as String?),
          newDescription: $checkedConvert(
            'new_description',
            (v) => v as String?,
          ),
          displayDesc: $checkedConvert('display_desc', (v) => v as String?),
          codecs: $checkedConvert(
            'codecs',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'newDescription': 'new_description',
        'displayDesc': 'display_desc',
      },
    );

VolumeData _$VolumeDataFromJson(Map<String, dynamic> json) => $checkedCreate(
  'VolumeData',
  json,
  ($checkedConvert) {
    final val = VolumeData(
      measuredI: $checkedConvert('measured_i', (v) => v as num?),
      measuredLra: $checkedConvert('measured_lra', (v) => v as num?),
      measuredTp: $checkedConvert('measured_tp', (v) => v as num?),
      measuredThreshold: $checkedConvert(
        'measured_threshold',
        (v) => v as num?,
      ),
      targetOffset: $checkedConvert('target_offset', (v) => v as num?),
      targetI: $checkedConvert('target_i', (v) => v as num?),
      targetTp: $checkedConvert('target_tp', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'measuredI': 'measured_i',
    'measuredLra': 'measured_lra',
    'measuredTp': 'measured_tp',
    'measuredThreshold': 'measured_threshold',
    'targetOffset': 'target_offset',
    'targetI': 'target_i',
    'targetTp': 'target_tp',
  },
);
