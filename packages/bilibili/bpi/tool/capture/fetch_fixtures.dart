import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:bpi/src/utils/wbi_utils.dart';
import 'package:http/http.dart' as http;

final class _CapturedResponse {
  const _CapturedResponse({required this.response, required this.json});

  final http.Response response;
  final Map<String, dynamic> json;
}

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final client = http.Client();

  final testingDir = Directory('testing');
  if (!testingDir.existsSync()) {
    testingDir.createSync(recursive: true);
  }

  print('Fetching Bili fixtures...');

  Future<_CapturedResponse> getJson(Uri uri, String label) async {
    final response = await client.get(
      uri,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}');
    }

    final decoded = _decodeJsonObject(response, label);
    _requireBiliSuccess(decoded, label);
    return _CapturedResponse(response: response, json: decoded);
  }

  late final String mixinKey;

  Future<_CapturedResponse> getWbiJson(
    String baseUrl,
    Map<String, dynamic> params,
    String label,
  ) async {
    final signedParams = WbiUtils.encWbi(params, mixinKey);
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: signedParams.map((k, v) => MapEntry(k, v.toString())),
    );
    return getJson(uri, label);
  }

  void saveResponse(String path, _CapturedResponse captured) {
    final file = File(path);
    if (file.existsSync() && !force) {
      print('Skipped (already exists, pass --force to overwrite): $path');
      return;
    }
    _requireNoSensitiveFields(captured.json, path);
    file.writeAsBytesSync(captured.response.bodyBytes);
    print('Saved: $path (HTTP ${captured.response.statusCode})');
  }

  bool shouldFetch(String path) => !File(path).existsSync() || force;

  void skipNote(String path) {
    print('Skipped (already exists, pass --force to overwrite): $path');
  }

  try {
    if (Platform.environment['CAPTURE_POPULAR_ONLY'] == '1') {
      final popular = await getJson(
        Uri.https('api.bilibili.com', '/x/web-interface/popular', {
          'pn': '1',
          'ps': '20',
        }),
        'popular',
      );
      _requirePopularItems(popular.json, 'popular');
      saveResponse('testing/popular.json', popular);
      print('Popular fixture fetched successfully.');
      return;
    }

    if (Platform.environment['CAPTURE_RANKING_ONLY'] == '1') {
      final ranking = await getJson(
        Uri.https('api.bilibili.com', '/x/web-interface/ranking/v2', {
          'rid': '0',
          'type': 'all',
        }),
        'ranking',
      );
      _requireRankingItems(ranking.json, 'ranking');
      saveResponse('testing/ranking.json', ranking);
      print('Ranking fixture fetched successfully.');
      return;
    }

    if (Platform.environment['CAPTURE_LIVE_ROOM_DETAIL_ONLY'] == '1') {
      final liveRoomDetail = await getJson(
        Uri.parse(
          'https://api.live.bilibili.com/xlive/web-room/v1/index/getH5InfoByRoom?room_id=21144080',
        ),
        'live room detail',
      );
      _requireLiveRoomDetail(liveRoomDetail.json, 'live room detail');
      saveResponse('testing/live_room_detail.json', liveRoomDetail);
      print('Live room detail fixture fetched successfully.');
      return;
    }

    if (Platform.environment['CAPTURE_LIVE_ROOM_PLAY_INFO_ONLY'] == '1') {
      final liveRoomPlayInfo = await getJson(
        Uri.parse(
          'https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo?room_id=21144080&protocol=0,1&format=0,1,2&codec=0,1&qn=10000&platform=web&ptype=8',
        ),
        'live room play info',
      );
      _requireLiveRoomPlayInfo(liveRoomPlayInfo.json, 'live room play info');
      saveResponse('testing/live_room_play_info.json', liveRoomPlayInfo);
      print('Live room play info fixture fetched successfully.');
      return;
    }

    mixinKey = await WbiUtils.fetchMixinKey(client);

    const sampleBvid = 'BV1GJ411x7vy';
    const sampleAid = 80431228;
    const sampleCid = 137646676;

    // 1. Search suggest
    if (!shouldFetch('testing/search_suggest.json')) {
      skipNote('testing/search_suggest.json');
    } else {
      final suggest = await getJson(
        Uri.parse(
          'https://s.search.bilibili.com/main/suggest?term=free&highlight=free&main_ver=v1',
        ),
        'search suggest',
      );
      NetworkSearchSuggest.fromJson(suggest.json);
      saveResponse('testing/search_suggest.json', suggest);
    }

    // 2. Search all
    if (!shouldFetch('testing/search_all.json')) {
      skipNote('testing/search_all.json');
    } else {
      final searchAll = await getWbiJson(
        'https://api.bilibili.com/x/web-interface/wbi/search/all/v2',
        {'keyword': 'Flutter'},
        'search all',
      );
      NetworkSearchResult.fromJson(
        _requireDataObject(searchAll.json, 'search all'),
      );
      saveResponse('testing/search_all.json', searchAll);
    }

    // 3. Search type endpoints
    final searchTypes = <String, String>{
      'search_video.json': 'video',
      'search_bili_user.json': 'bili_user',
      'search_live.json': 'live',
      'search_live_room.json': 'live_room',
      'search_live_user.json': 'live_user',
      'search_article.json': 'article',
      'search_media_bangumi.json': 'media_bangumi',
      'search_media_ft.json': 'media_ft',
      'search_photo.json': 'photo',
      'search_topic.json': 'topic',
    };

    final keywords = <String, String>{
      'media_bangumi': '凡人修仙传',
      'media_ft': '流浪地球',
      'photo': '壁纸',
      'topic': '游戏',
    };

    for (final entry in searchTypes.entries) {
      final fileName = entry.key;
      final type = entry.value;
      final label = 'search $type';
      if (!shouldFetch('testing/$fileName')) {
        skipNote('testing/$fileName');
        continue;
      }
      final captured = await getWbiJson(
        'https://api.bilibili.com/x/web-interface/wbi/search/type',
        {'keyword': keywords[type] ?? 'Flutter', 'search_type': type},
        label,
      );
      NetworkSearchResult.fromJson(_requireDataObject(captured.json, label));
      saveResponse('testing/$fileName', captured);
    }

    // 4. Video detail
    if (!shouldFetch('testing/video_detail.json')) {
      skipNote('testing/video_detail.json');
    } else {
      final videoDetail = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/web-interface/view?bvid=$sampleBvid',
        ),
        'video detail',
      );
      BaseResponse.fromJson(videoDetail.json);
      saveResponse('testing/video_detail.json', videoDetail);
    }

    // 5. Video relation
    if (!shouldFetch('testing/video_relation.json')) {
      skipNote('testing/video_relation.json');
    } else {
      final videoRelation = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/web-interface/archive/relation?bvid=$sampleBvid',
        ),
        'video relation',
      );
      NetworkVideoRelation.fromJson(
        _requireDataObject(videoRelation.json, 'video relation'),
      );
      saveResponse('testing/video_relation.json', videoRelation);
    }

    // 6. Related videos
    if (!shouldFetch('testing/related_videos.json')) {
      skipNote('testing/related_videos.json');
    } else {
      final relatedVideos = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/web-interface/archive/related?bvid=$sampleBvid',
        ),
        'related videos',
      );
      final relatedItems = relatedVideos.json['data'];
      if (relatedItems is! List) {
        throw const FormatException('related videos data is not a list');
      }
      NetworkRelatedVideosList.fromJson({'items': relatedItems});
      saveResponse('testing/related_videos.json', relatedVideos);
    }

    // 7. Reply list main
    if (!shouldFetch('testing/reply_list_main.json')) {
      skipNote('testing/reply_list_main.json');
    } else {
      final replyMain = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/v2/reply/main?oid=$sampleAid&type=1',
        ),
        'reply list main',
      );
      NetworkReplyData.fromJson(
        _requireDataObject(replyMain.json, 'reply list main'),
      );
      saveResponse('testing/reply_list_main.json', replyMain);
    }

    // 8. Reply list
    // rootRpid is extracted from the reply list and feeds the reply-reply
    // request below. When reply_list.json is skipped (already exists), we
    // fall back to the default rpid so the reply-reply fetch still works.
    late int rootRpid;
    if (!shouldFetch('testing/reply_list.json')) {
      skipNote('testing/reply_list.json');
      rootRpid = 2202965009;
    } else {
      final replyList = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/v2/reply?oid=$sampleAid&type=1&pn=1&sort=1',
        ),
        'reply list',
      );
      final replyData = NetworkReplyData.fromJson(
        _requireDataObject(replyList.json, 'reply list'),
      );
      rootRpid = replyData.replies?.firstOrNull?.rpid ?? 2202965009;
      saveResponse('testing/reply_list.json', replyList);
    }

    // 9. Reply reply list
    if (!shouldFetch('testing/reply_reply_list.json')) {
      skipNote('testing/reply_reply_list.json');
    } else {
      final replyReply = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/v2/reply/reply?oid=$sampleAid&type=1&root=$rootRpid&pn=1&sort=1',
        ),
        'reply reply list',
      );
      NetworkReplyReplyData.fromJson(
        _requireDataObject(replyReply.json, 'reply reply list'),
      );
      saveResponse('testing/reply_reply_list.json', replyReply);
    }

    // 10. Play URL (WBI)
    if (!shouldFetch('testing/play_url.json')) {
      skipNote('testing/play_url.json');
    } else {
      final playUrl = await getWbiJson(
        'https://api.bilibili.com/x/player/wbi/playurl',
        {
          'bvid': sampleBvid,
          'cid': sampleCid,
          'qn': 80,
          'fnval': 4048,
          'fourk': 1,
        },
        'play URL',
      );
      final parsedPlayUrl = NetworkPlayUrl.fromJson(
        _requireDataObject(playUrl.json, 'play URL'),
      );
      final dashVideo = parsedPlayUrl.dash?.video;
      final dashAudio = parsedPlayUrl.dash?.audio;
      final hasDash =
          dashVideo != null &&
          dashVideo.isNotEmpty &&
          dashAudio != null &&
          dashAudio.isNotEmpty &&
          dashVideo.any(
            (stream) => stream.playUrls.any((url) => url.isNotEmpty),
          );
      final hasDurl =
          parsedPlayUrl.durl?.any(
            (stream) => stream.playUrls.any((url) => url.isNotEmpty),
          ) ??
          false;
      if (!hasDash && !hasDurl) {
        throw const FormatException('play URL has no playable streams');
      }
      saveResponse('testing/play_url.json', playUrl);
    }

    // 11. Player v2 (Video Player Info & Subtitles)
    if (!shouldFetch('testing/player_v2.json')) {
      skipNote('testing/player_v2.json');
    } else {
      final playerV2 = await getJson(
        Uri.parse(
          'https://api.bilibili.com/x/player/v2?bvid=$sampleBvid&cid=$sampleCid',
        ),
        'player v2',
      );
      NetworkBiliPlayerInfo.fromJson(
        _requireDataObject(playerV2.json, 'player v2'),
      );
      saveResponse('testing/player_v2.json', playerV2);
    }

    // 12. Live Room Play Info
    if (!shouldFetch('testing/live_room_play_info.json')) {
      skipNote('testing/live_room_play_info.json');
    } else {
      final liveRoomPlayInfo = await getJson(
        Uri.parse(
          'https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo?room_id=21144080&protocol=0,1&format=0,1,2&codec=0,1&qn=10000&platform=web&ptype=8',
        ),
        'live room play info',
      );
      _requireLiveRoomPlayInfo(liveRoomPlayInfo.json, 'live room play info');
      saveResponse('testing/live_room_play_info.json', liveRoomPlayInfo);
    }

    print('All Bili fixtures fetched and saved successfully!');
  } on HttpException catch (error) {
    stderr.writeln('Error fetching Bili fixtures: ${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Error fetching Bili fixtures: ${error.message}');
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Error fetching Bili fixtures: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    client.close();
  }
}

const _sensitiveKeys = <String>{
  'access_key',
  'access_token',
  'authorization',
  'bili_jct',
  'cookie',
  'csrf',
  'img_key',
  'sessdata',
  'sub_key',
  'token',
};

void _requireNoSensitiveFields(Object? value, String path) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = '${entry.key}'.toLowerCase();
      if (_sensitiveKeys.contains(key)) {
        throw FormatException(
          'refusing to write $path: response contains sensitive key "$key"',
        );
      }
      _requireNoSensitiveFields(entry.value, path);
    }
  } else if (value is List) {
    for (final item in value) {
      _requireNoSensitiveFields(item, path);
    }
  }
}

Map<String, dynamic> _decodeJsonObject(http.Response response, String label) {
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } on FormatException {
    throw FormatException('$label returned invalid JSON');
  }
  throw FormatException('$label returned a non-object JSON response');
}

void _requireBiliSuccess(Map<String, dynamic> json, String label) {
  final code = json['code'];
  if (code is! int || code != 0) {
    throw FormatException('$label returned Bilibili code $code');
  }
}

Map<String, dynamic> _requireDataObject(
  Map<String, dynamic> json,
  String label,
) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw FormatException('$label data is not an object');
}

/// Rejects a code-zero live room response the DTO cannot parse.
///
/// `getH5InfoByRoom` returns code 0 with `room_info` absent when the room is
/// offline or gone, so a `data` object alone is not proof of a usable capture.
/// Checking the types of `room_id`, `live_status` and `title` is not enough
/// either: the check restates field types that the model already declares, so
/// it drifts whenever the model changes. Parse the DTO instead, so this guard
/// cannot disagree with what `fromJson` accepts.
///
/// Parsing alone is still not enough, because `room_info` is nullable: an empty
/// `data` or an explicit `room_info: null` parses cleanly and would leave a
/// fixture no test can read anything from. Require the field itself.
void _requireLiveRoomDetail(Map<String, dynamic> json, String label) {
  final data = _requireDataObject(json, label);
  try {
    final detail = NetworkLiveRoomDetail.fromJson(data);
    if (detail.roomInfo == null) {
      throw const FormatException('data.room_info is missing');
    }
  } on FormatException catch (error) {
    throw FormatException(
      '$label data is not a usable live room: ${error.message}',
    );
  } on Object catch (error) {
    throw FormatException(
      '$label data does not parse as NetworkLiveRoomDetail: $error',
    );
  }
}

void _requirePopularItems(Map<String, dynamic> json, String label) {
  final data = _requireDataObject(json, label);
  final items = data['list'];
  if (items is! List || items.isEmpty) {
    throw FormatException('$label data.list is not a non-empty list');
  }
  final hasVideo = items.any((item) {
    if (item is! Map) {
      return false;
    }
    final value = item['bvid'] ?? item['aid'];
    return value is String && value.isNotEmpty || value is int;
  });
  if (!hasVideo) {
    throw FormatException('$label has no item with bvid or aid');
  }
}

void _requireLiveRoomPlayInfo(Map<String, dynamic> json, String label) {
  final data = _requireDataObject(json, label);
  final playurlInfo = data['playurl_info'];
  if (playurlInfo is! Map) {
    throw FormatException('$label data.playurl_info is not an object');
  }
}

void _requireRankingItems(Map<String, dynamic> json, String label) {
  final data = _requireDataObject(json, label);
  final items = data['list'];
  if (items is! List || items.isEmpty) {
    throw FormatException('$label data.list is not a non-empty list');
  }
  final videoItems = items.whereType<Map>().where((item) {
    final bvid = item['bvid'];
    final aid = item['aid'];
    return aid is int && bvid is String && bvid.isNotEmpty;
  }).length;
  if (videoItems == 0) {
    throw FormatException('$label has no video item with aid and bvid');
  }
}
