import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:bpi/src/utils/wbi_utils.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final client = http.Client();
  final encoder = const JsonEncoder.withIndent('  ');

  final testingDir = Directory('testing');
  if (!testingDir.existsSync()) {
    testingDir.createSync(recursive: true);
  }

  print('Fetching WBI mixin key...');
  final mixinKey = await WbiUtils.fetchMixinKey(client);
  print('WBI mixin key obtained: $mixinKey');

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    print('Fetching: $uri');
    final response = await client.get(
      uri,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/',
      },
    );
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} for $uri');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWbiJson(
    String baseUrl,
    Map<String, dynamic> params,
  ) async {
    final signedParams = WbiUtils.encWbi(params, mixinKey);
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: signedParams.map((k, v) => MapEntry(k, v.toString())),
    );
    return getJson(uri);
  }

  void saveJson(String path, Map<String, dynamic> jsonMap) {
    final file = File(path);
    file.writeAsStringSync('${encoder.convert(jsonMap)}\n');
    print('Saved: $path');
  }

  try {
    const sampleBvid = 'BV1GJ411x7vy';
    const sampleAid = 80431228;
    const sampleCid = 137646676;

    // 1. Search suggest
    final suggestUri = Uri.parse(
      'https://s.search.bilibili.com/main/suggest?term=free&highlight=free&main_ver=v1',
    );
    final suggestJson = await getJson(suggestUri);
    NetworkSearchSuggest.fromJson(suggestJson);
    saveJson('testing/search_suggest.json', suggestJson);

    // 2. Search all
    final searchAllJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/all/v2',
      {'keyword': 'Flutter'},
    );
    if (searchAllJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchAllJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/search_all.json', searchAllJson);

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
      final typeStr = entry.value;
      final kw = keywords[typeStr] ?? 'Flutter';

      final jsonResult = await getWbiJson(
        'https://api.bilibili.com/x/web-interface/wbi/search/type',
        {'keyword': kw, 'search_type': typeStr},
      );
      if (jsonResult['data'] is Map<String, dynamic>) {
        NetworkSearchResult.fromJson(
          jsonResult['data'] as Map<String, dynamic>,
        );
      }
      saveJson('testing/$fileName', jsonResult);
    }

    // 4. Video detail
    final videoDetailUri = Uri.parse(
      'https://api.bilibili.com/x/web-interface/view?bvid=$sampleBvid',
    );
    final videoDetailJson = await getJson(videoDetailUri);
    BaseResponse.fromJson(videoDetailJson);
    if (videoDetailJson['data'] is Map<String, dynamic>) {
      VideoDetailData.fromJson(
        videoDetailJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/video_detail.json', videoDetailJson);

    // 5. Video relation
    final videoRelationUri = Uri.parse(
      'https://api.bilibili.com/x/web-interface/archive/relation?bvid=$sampleBvid',
    );
    final videoRelationJson = await getJson(videoRelationUri);
    if (videoRelationJson['data'] is Map<String, dynamic>) {
      NetworkVideoRelation.fromJson(
        videoRelationJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/video_relation.json', videoRelationJson);

    // 6. Related videos
    final relatedVideosUri = Uri.parse(
      'https://api.bilibili.com/x/web-interface/archive/related?bvid=$sampleBvid',
    );
    final relatedVideosJson = await getJson(relatedVideosUri);
    if (relatedVideosJson['data'] is List) {
      NetworkRelatedVideosList.fromJson({'items': relatedVideosJson['data']});
    }
    saveJson('testing/related_videos.json', relatedVideosJson);

    // 7. Reply list main
    final replyMainUri = Uri.parse(
      'https://api.bilibili.com/x/v2/reply/main?oid=$sampleAid&type=1',
    );
    final replyMainJson = await getJson(replyMainUri);
    if (replyMainJson['data'] is Map<String, dynamic>) {
      NetworkReplyData.fromJson(
        replyMainJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/reply_list_main.json', replyMainJson);

    // 8. Reply list
    final replyListUri = Uri.parse(
      'https://api.bilibili.com/x/v2/reply?oid=$sampleAid&type=1&pn=1&sort=1',
    );
    final replyListJson = await getJson(replyListUri);
    int rootRpid = 2202965009;
    if (replyListJson['data'] is Map<String, dynamic>) {
      final replyData = NetworkReplyData.fromJson(
        replyListJson['data'] as Map<String, dynamic>,
      );
      if (replyData.replies != null && replyData.replies!.isNotEmpty) {
        rootRpid = replyData.replies!.first.rpid;
      }
    }
    saveJson('testing/reply_list.json', replyListJson);

    // 9. Reply reply list
    final replyReplyUri = Uri.parse(
      'https://api.bilibili.com/x/v2/reply/reply?oid=$sampleAid&type=1&root=$rootRpid&pn=1&sort=1',
    );
    final replyReplyJson = await getJson(replyReplyUri);
    if (replyReplyJson['data'] is Map<String, dynamic>) {
      NetworkReplyReplyData.fromJson(
        replyReplyJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/reply_reply_list.json', replyReplyJson);

    // 10. Play URL (WBI)
    final playUrlJson = await getWbiJson(
      'https://api.bilibili.com/x/player/wbi/playurl',
      {
        'bvid': sampleBvid,
        'cid': sampleCid,
        'qn': 80,
        'fnval': 4048,
        'fourk': 1,
      },
    );
    if (playUrlJson['data'] is Map<String, dynamic>) {
      NetworkPlayUrl.fromJson(
        playUrlJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('testing/play_url.json', playUrlJson);

    print('All API fixtures fetched and saved successfully!');
  } catch (e, st) {
    print('Error fetching fixtures: $e\n$st');
    exitCode = 1;
  } finally {
    client.close();
  }
}
