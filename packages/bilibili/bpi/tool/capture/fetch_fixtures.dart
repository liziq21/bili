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

Future<void> main() async {
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
    file.writeAsBytesSync(captured.response.bodyBytes);
    print('Saved: $path (HTTP ${captured.response.statusCode})');
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

    mixinKey = await WbiUtils.fetchMixinKey(client);

    const sampleBvid = 'BV1GJ411x7vy';
    const sampleAid = 80431228;
    const sampleCid = 137646676;

    // 1. Search suggest
    final suggest = await getJson(
      Uri.parse(
        'https://s.search.bilibili.com/main/suggest?term=free&highlight=free&main_ver=v1',
      ),
      'search suggest',
    );
    NetworkSearchSuggest.fromJson(suggest.json);
    saveResponse('testing/search_suggest.json', suggest);

    // 2. Search all
    final searchAll = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/all/v2',
      {'keyword': 'Flutter'},
      'search all',
    );
    NetworkSearchResult.fromJson(
      _requireDataObject(searchAll.json, 'search all'),
    );
    saveResponse('testing/search_all.json', searchAll);

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
      final captured = await getWbiJson(
        'https://api.bilibili.com/x/web-interface/wbi/search/type',
        {'keyword': keywords[type] ?? 'Flutter', 'search_type': type},
        label,
      );
      NetworkSearchResult.fromJson(_requireDataObject(captured.json, label));
      saveResponse('testing/$fileName', captured);
    }

    // 4. Video detail
    final videoDetail = await getJson(
      Uri.parse(
        'https://api.bilibili.com/x/web-interface/view?bvid=$sampleBvid',
      ),
      'video detail',
    );
    BaseResponse.fromJson(videoDetail.json);
    saveResponse('testing/video_detail.json', videoDetail);

    // 5. Video relation
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

    // 6. Related videos
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

    // 7. Reply list main
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

    // 8. Reply list
    final replyList = await getJson(
      Uri.parse(
        'https://api.bilibili.com/x/v2/reply?oid=$sampleAid&type=1&pn=1&sort=1',
      ),
      'reply list',
    );
    final replyData = NetworkReplyData.fromJson(
      _requireDataObject(replyList.json, 'reply list'),
    );
    final rootRpid = replyData.replies?.firstOrNull?.rpid ?? 2202965009;
    saveResponse('testing/reply_list.json', replyList);

    // 9. Reply reply list
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

    // 10. Play URL (WBI)
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
        dashVideo.any((stream) => stream.playUrls.any((url) => url.isNotEmpty));
    final hasDurl =
        parsedPlayUrl.durl?.any(
          (stream) => stream.playUrls.any((url) => url.isNotEmpty),
        ) ??
        false;
    if (!hasDash && !hasDurl) {
      throw const FormatException('play URL has no playable streams');
    }
    saveResponse('testing/play_url.json', playUrl);

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
