import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:ypi/src/protobuf/yt_protobuf_encoder.dart';

final class _CapturedResponse {
  const _CapturedResponse(this.response, this.bodyBytes);

  final http.Response response;
  final List<int> bodyBytes;
}

Future<void> main() async {
  final client = http.Client();

  final testingDir = Directory('testing');
  if (!testingDir.existsSync()) {
    testingDir.createSync(recursive: true);
  }

  void saveResponse(String path, _CapturedResponse captured) {
    final file = File(path);
    file.writeAsBytesSync(captured.bodyBytes);
    print('Saved: $path (HTTP ${captured.response.statusCode})');
  }

  try {
    const requestTimeout = Duration(seconds: 30);

    print('1. Fetching search video JSON...');
    final videoSearchResponse = await client
        .post(
          Uri.parse('https://www.youtube.com/youtubei/v1/search'),
          headers: _headers,
          body: jsonEncode({
            'context': _clientContext,
            'query': 'Flutter',
            'params': YoutubeProtobufEncoder.encodeSearchParams(contentType: 1),
          }),
        )
        .timeout(requestTimeout);
    final video = _captureJson(
      videoSearchResponse,
      'search video',
      (json) =>
          _validateSearchResponse(json, requiredRenderer: 'videoRenderer'),
    );
    saveResponse('testing/search_video.json', video);

    print('2. Fetching search channel JSON...');
    final channelSearchResponse = await client
        .post(
          Uri.parse('https://www.youtube.com/youtubei/v1/search'),
          headers: _headers,
          body: jsonEncode({
            'context': _clientContext,
            'query': 'Flutter',
            'params': YoutubeProtobufEncoder.encodeSearchParams(contentType: 2),
          }),
        )
        .timeout(requestTimeout);
    final channel = _captureJson(
      channelSearchResponse,
      'search channel',
      (json) =>
          _validateSearchResponse(json, requiredRenderer: 'channelRenderer'),
    );
    saveResponse('testing/search_channel.json', channel);

    print('3. Fetching search suggest JSON...');
    final suggestResponse = await client
        .get(
          Uri.parse(
            'https://suggestqueries.google.com/complete/search?q=Flutter&client=youtube&ds=yt',
          ),
        )
        .timeout(requestTimeout);
    final suggest = _captureJson(
      suggestResponse,
      'search suggest',
      _validateSuggestResponse,
    );
    saveResponse('testing/search_suggest.json', suggest);

    print('All YouTube fixtures fetched and saved successfully!');
  } on HttpException catch (error) {
    stderr.writeln('Error fetching YouTube fixtures: ${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Error fetching YouTube fixtures: ${error.message}');
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Error fetching YouTube fixtures: ${error.runtimeType}');
    exitCode = 1;
  } finally {
    client.close();
  }
}

const _headers = <String, String>{
  'Content-Type': 'application/json',
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
  'X-YouTube-Client-Name': '1',
  'X-YouTube-Client-Version': '2.20230818.00.00',
};

const _clientContext = <String, dynamic>{
  'client': {
    'clientName': 'WEB',
    'clientVersion': '2.20230818.00.00',
    'hl': 'zh-CN',
    'gl': 'US',
  },
};

_CapturedResponse _captureJson(
  http.Response response,
  String label,
  void Function(dynamic) validate,
) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException('HTTP ${response.statusCode}');
  }

  final dynamic decoded;
  try {
    decoded = _decodeBody(response.body);
  } on FormatException {
    throw FormatException('$label returned invalid JSON');
  }
  validate(decoded);
  final redacted = _redactTrackingFields(decoded);
  final prefix = response.body.startsWith('window.google.ac.h(')
      ? 'window.google.ac.h('
      : '';
  final suffix = prefix.isEmpty ? '' : ')';
  return _CapturedResponse(
    response,
    utf8.encode('$prefix${jsonEncode(redacted)}$suffix'),
  );
}

const _prohibitedFixtureFields = {
  'trackingParams',
  'clickTrackingParams',
  'visitorData',
};

dynamic _redactTrackingFields(dynamic value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        if (!_prohibitedFixtureFields.contains(entry.key))
          entry.key as String: _redactTrackingFields(entry.value),
    };
  }
  if (value is List) {
    return value.map(_redactTrackingFields).toList();
  }
  return value;
}

dynamic _decodeBody(String body) {
  var jsonText = body;
  if (jsonText.startsWith('window.google.ac.h(')) {
    if (!jsonText.endsWith(')')) {
      throw const FormatException('Google suggest response is not closed');
    }
    jsonText = jsonText
        .substring('window.google.ac.h('.length, jsonText.length - 1)
        .trim();
  }
  return jsonDecode(jsonText);
}

void _validateSearchResponse(dynamic json, {required String requiredRenderer}) {
  if (json is! Map<String, dynamic>) {
    throw const FormatException('InnerTube search response is not an object');
  }
  final contents = json['contents'];
  if (contents is! Map<String, dynamic>) {
    throw const FormatException('InnerTube search response has no contents');
  }
  final twoColumn = contents['twoColumnSearchResultsRenderer'];
  if (twoColumn is! Map<String, dynamic>) {
    throw const FormatException(
      'InnerTube search response has no twoColumnSearchResultsRenderer',
    );
  }
  final primaryContents = twoColumn['primaryContents'];
  if (primaryContents is! Map<String, dynamic>) {
    throw const FormatException(
      'InnerTube search response has no primary contents',
    );
  }
  final sectionList = primaryContents['sectionListRenderer'];
  if (sectionList is! Map<String, dynamic>) {
    throw const FormatException(
      'InnerTube search response has no sectionListRenderer',
    );
  }
  final sections = sectionList['contents'];
  if (sections is! List || sections.isEmpty) {
    throw const FormatException(
      'InnerTube search response has no result sections',
    );
  }
  if (!_containsRendererInItemSections(sections, requiredRenderer)) {
    throw FormatException('InnerTube search response has no $requiredRenderer');
  }
}

bool _containsRendererInItemSections(
  dynamic sections,
  String requiredRenderer,
) {
  if (sections is! Iterable) {
    return false;
  }
  return sections.any((section) {
    if (section is! Map) {
      return false;
    }
    final itemSection = section['itemSectionRenderer'];
    if (itemSection is! Map) {
      return false;
    }
    final items = itemSection['contents'];
    if (items is! Iterable) {
      return false;
    }
    return items.any((item) => item is Map && item[requiredRenderer] is Map);
  });
}

void _validateSuggestResponse(dynamic json) {
  if (json is! List || json.length < 2 || json[1] is! List) {
    throw const FormatException('Google suggest response has an invalid shape');
  }
  final suggestions = json[1] as List;
  if (suggestions.isEmpty) {
    throw const FormatException('Google suggest response has no suggestions');
  }
  if (suggestions.any((item) {
    if (item is! List || item.isEmpty) {
      return true;
    }
    final text = item[0];
    return text is! String || text.isEmpty;
  })) {
    throw const FormatException(
      'Google suggest response has an invalid suggestion',
    );
  }
}
