import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ypi/ypi.dart';

Future<void> main() async {
  final client = http.Client();
  final service = YoutubeService(httpClient: client);
  final encoder = const JsonEncoder.withIndent('  ');

  final testingDir = Directory('testing');
  if (!testingDir.existsSync()) {
    testingDir.createSync(recursive: true);
  }

  void saveJson(String path, dynamic jsonData) {
    final file = File(path);
    file.writeAsStringSync('${encoder.convert(jsonData)}\n');
    print('Saved: $path');
  }

  try {
    print('1. Fetching search video JSON...');
    final videoSearchResponse = await client.post(
      Uri.parse('https://www.youtube.com/youtubei/v1/search'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
        'X-YouTube-Client-Name': '1',
        'X-YouTube-Client-Version': '2.20230818.00.00',
      },
      body: jsonEncode({
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20230818.00.00',
            'hl': 'zh-CN',
            'gl': 'US',
          },
        },
        'query': 'Flutter',
        'params': YoutubeProtobufEncoder.encodeSearchParams(
          contentType: YoutubeContentTypeFilter.video,
        ),
      }),
    );

    if (videoSearchResponse.statusCode == 200) {
      final videoJson = jsonDecode(videoSearchResponse.body);
      saveJson('testing/search_video.json', videoJson);
    } else {
      print('Failed search_video: ${videoSearchResponse.statusCode}');
    }

    print('2. Fetching search channel JSON...');
    final channelSearchResponse = await client.post(
      Uri.parse('https://www.youtube.com/youtubei/v1/search'),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
        'X-YouTube-Client-Name': '1',
        'X-YouTube-Client-Version': '2.20230818.00.00',
      },
      body: jsonEncode({
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20230818.00.00',
            'hl': 'zh-CN',
            'gl': 'US',
          },
        },
        'query': 'Flutter',
        'params': YoutubeProtobufEncoder.encodeSearchParams(
          contentType: YoutubeContentTypeFilter.channel,
        ),
      }),
    );

    if (channelSearchResponse.statusCode == 200) {
      final channelJson = jsonDecode(channelSearchResponse.body);
      saveJson('testing/search_channel.json', channelJson);
    } else {
      print('Failed search_channel: ${channelSearchResponse.statusCode}');
    }

    print('3. Fetching search suggest JSON...');
    final suggestUri = Uri.parse(
      'https://suggestqueries.google.com/complete/search?q=Flutter&client=youtube&ds=yt',
    );
    final suggestResponse = await client.get(suggestUri);
    if (suggestResponse.statusCode == 200) {
      var jsonText = suggestResponse.body;
      if (jsonText.startsWith('window.google.ac.h(')) {
        jsonText = jsonText
            .substring('window.google.ac.h('.length, jsonText.length - 1)
            .trim();
      }
      final suggestJson = jsonDecode(jsonText);
      saveJson('testing/search_suggest.json', suggestJson);
    } else {
      print('Failed search_suggest: ${suggestResponse.statusCode}');
    }

    print('All API fixtures fetched and saved successfully!');
  } catch (e, st) {
    print('Error fetching fixtures: $e\n$st');
    exitCode = 1;
  } finally {
    service.close();
  }
}
