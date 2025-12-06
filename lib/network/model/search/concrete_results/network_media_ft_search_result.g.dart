// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_media_ft_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkMediaFtSearchResult _$NetworkMediaFtSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkMediaFtSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkMediaFtSearchResult(
      mediaId: $checkedConvert('media_id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => HtmlTitle.fromJson(v)),
      orgTitle: $checkedConvert('org_title', (v) => v as String),
      mediaType: $checkedConvert('media_type', (v) => (v as num).toInt()),
      cv: $checkedConvert('cv', (v) => v as String),
      staff: $checkedConvert('staff', (v) => v as String),
      seasonId: $checkedConvert('season_id', (v) => (v as num).toInt()),
      isAvid: $checkedConvert('is_avid', (v) => v as bool),
      hitEpids: $checkedConvert('hit_epids', (v) => v as String),
      seasonType: $checkedConvert('season_type', (v) => (v as num).toInt()),
      seasonTypeName: $checkedConvert('season_type_name', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      buttonText: $checkedConvert('button_text', (v) => v as String),
      isSelection: $checkedConvert('is_selection', (v) => (v as num).toInt()),
      cover: $checkedConvert('cover', (v) => v as String),
      areas: $checkedConvert('areas', (v) => v as String),
      styles: $checkedConvert('styles', (v) => v as String),
      gotoUrl: $checkedConvert('goto_url', (v) => v as String),
      desc: $checkedConvert('desc', (v) => v as String),
      pubtime: $checkedConvert('pubtime', (v) => (v as num).toInt()),
      mediaMode: $checkedConvert('media_mode', (v) => (v as num).toInt()),
      mediaScore: $checkedConvert(
        'media_score',
        (v) => NetworkMediaScore.fromJson(v as Map<String, dynamic>),
      ),
      indexShow: $checkedConvert('index_show', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'mediaId': 'media_id',
    'orgTitle': 'org_title',
    'mediaType': 'media_type',
    'seasonId': 'season_id',
    'isAvid': 'is_avid',
    'hitEpids': 'hit_epids',
    'seasonType': 'season_type',
    'seasonTypeName': 'season_type_name',
    'buttonText': 'button_text',
    'isSelection': 'is_selection',
    'gotoUrl': 'goto_url',
    'mediaMode': 'media_mode',
    'mediaScore': 'media_score',
    'indexShow': 'index_show',
  },
);
