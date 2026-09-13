import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:bpi/src/utils/wbi_utils.dart';

Future<void> main() async {
  final client = http.Client();
  final encoder = const JsonEncoder.withIndent('  ');

  final fixturesDir = Directory('test/fixtures');
  if (!fixturesDir.existsSync()) {
    fixturesDir.createSync(recursive: true);
  }

  final testingSearchDir = Directory('../testing/network/fakes/search');
  if (!testingSearchDir.existsSync()) {
    testingSearchDir.createSync(recursive: true);
  }

  final testingSuggestDir = Directory(
    '../testing/network/fakes/search_suggest',
  );
  if (!testingSuggestDir.existsSync()) {
    testingSuggestDir.createSync(recursive: true);
  }

  print('Fetching WBI mixin key...');
  final mixinKey = await WbiUtils.fetchMixinKey(client);
  print('WBI mixin key obtained: $mixinKey');

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    print('Fetching: $uri');
    final response = await client.get(
      uri,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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
    // 1. Search suggest
    final suggestUri = Uri.parse(
      'https://s.search.bilibili.com/main/suggest?term=free&highlight=free&main_ver=v1',
    );
    final suggestJson = await getJson(suggestUri);
    NetworkSearchSuggest.fromJson(suggestJson);
    saveJson('test/fixtures/search_suggest.json', suggestJson);
    saveJson(
      '../testing/network/fakes/search_suggest/search_suggest.json',
      suggestJson,
    );

    // 2. Search all
    final searchAllJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/all/v2',
      {'keyword': 'Flutter'},
    );
    if (searchAllJson['data'] != null &&
        searchAllJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchAllJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_all.json', searchAllJson);
    saveJson('../testing/network/fakes/search/search.json', searchAllJson);

    // 3. Search type: video
    final searchVideoJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': 'Flutter', 'search_type': 'video'},
    );
    if (searchVideoJson['data'] != null &&
        searchVideoJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchVideoJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_video.json', searchVideoJson);
    saveJson(
      '../testing/network/fakes/search/type_search.json',
      searchVideoJson,
    );

    // 4. Search type: bili_user
    final searchUserJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': 'Flutter', 'search_type': 'bili_user'},
    );
    if (searchUserJson['data'] != null &&
        searchUserJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchUserJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_bili_user.json', searchUserJson);

    // 5. Search type: live
    final searchLiveJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': 'Flutter', 'search_type': 'live'},
    );
    if (searchLiveJson['data'] != null &&
        searchLiveJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchLiveJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_live.json', searchLiveJson);
    saveJson(
      '../testing/network/fakes/search/live_search.json',
      searchLiveJson,
    );

    // 6. Search type: article
    final searchArticleJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': 'Flutter', 'search_type': 'article'},
    );
    if (searchArticleJson['data'] != null &&
        searchArticleJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchArticleJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_article.json', searchArticleJson);

    // 7. Search type: media_bangumi
    final searchBangumiJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': '凡人修仙传', 'search_type': 'media_bangumi'},
    );
    if (searchBangumiJson['data'] != null &&
        searchBangumiJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchBangumiJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_media_bangumi.json', searchBangumiJson);

    // 8. Search type: media_ft
    final searchFtJson = await getWbiJson(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      {'keyword': '流浪地球', 'search_type': 'media_ft'},
    );
    if (searchFtJson['data'] != null &&
        searchFtJson['data'] is Map<String, dynamic>) {
      NetworkSearchResult.fromJson(
        searchFtJson['data'] as Map<String, dynamic>,
      );
    }
    saveJson('test/fixtures/search_media_ft.json', searchFtJson);

    // 9. Video detail
    final videoDetailUri = Uri.parse(
      'https://api.bilibili.com/x/web-interface/view?bvid=BV1GJ411x7vy',
    );
    final videoDetailJson = await getJson(videoDetailUri);
    BaseResponse.fromJson(videoDetailJson);
    saveJson('test/fixtures/video_detail.json', videoDetailJson);

    print('All API fixtures fetched and saved successfully!');
  } catch (e, st) {
    print('Error fetching fixtures: $e\n$st');
    exitCode = 1;
  } finally {
    client.close();
  }
}
