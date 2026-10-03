import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ypi/ypi.dart';

import 'package:ypi/src/protobuf/yt_protobuf_encoder.dart';

final class _CapturedResponse {
  const _CapturedResponse(this.response, this.bodyBytes);

  final http.Response response;
  final List<int> bodyBytes;
}

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final client = http.Client();

  final testingDir = Directory('testing');
  if (!testingDir.existsSync()) {
    testingDir.createSync(recursive: true);
  }

  void saveResponse(String path, _CapturedResponse captured) {
    final file = File(path);
    if (file.existsSync() && !force) {
      print('Skipped (already exists, pass --force to overwrite): $path');
      return;
    }
    file.writeAsBytesSync(captured.bodyBytes);
    print('Saved: $path (HTTP ${captured.response.statusCode})');
  }

  bool shouldFetch(String path) => !File(path).existsSync() || force;

  void skipNote(String path) {
    print('Skipped (already exists, pass --force to overwrite): $path');
  }

  try {
    const requestTimeout = Duration(seconds: 30);

    print('1. Fetching search video JSON...');
    if (!shouldFetch('testing/search_video.json')) {
      skipNote('testing/search_video.json');
    } else {
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
      (json) => _validateSearchResponse(
        json,
        containsItem: _rendererItem('videoRenderer'),
      ),
    );
    saveResponse('testing/search_video.json', video);
    }

    print('2. Fetching search channel JSON...');
    if (!shouldFetch('testing/search_channel.json')) {
      skipNote('testing/search_channel.json');
    } else {
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
      (json) => _validateSearchResponse(
        json,
        containsItem: _rendererItem('channelRenderer'),
      ),
    );
    saveResponse('testing/search_channel.json', channel);
    }

    print('3. Fetching search playlist JSON...');
    if (!shouldFetch('testing/search_playlist.json')) {
      skipNote('testing/search_playlist.json');
    } else {
    final playlistSearchResponse = await client
        .post(
          Uri.parse('https://www.youtube.com/youtubei/v1/search'),
          headers: _headers,
          body: jsonEncode({
            'context': _clientContext,
            'query': 'Flutter',
            'params': YoutubeProtobufEncoder.encodeSearchParams(contentType: 3),
          }),
        )
        .timeout(requestTimeout);
    final playlist = _captureJson(
      playlistSearchResponse,
      'search playlist',
      (json) =>
          _validateSearchResponse(json, containsItem: _containsPlaylistLockup),
    );
    saveResponse('testing/search_playlist.json', playlist);
    }

    print('4. Fetching search suggest JSON...');
    if (!shouldFetch('testing/search_suggest.json')) {
      skipNote('testing/search_suggest.json');
    } else {
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
    }

    // Browse + continuation are captured as a pair: the continuation token
    // comes from the same response body that is saved to browse.json.
    // If browse.json is skipped (already exists, no --force), the
    // continuation fetch is skipped too so the two fixtures stay consistent.
    final browseNeedsFetch = shouldFetch('testing/browse.json');
    final contNeedsFetch = shouldFetch('testing/browse_continuation.json');

    if (!browseNeedsFetch && !contNeedsFetch) {
      skipNote('testing/browse.json');
      skipNote('testing/browse_continuation.json');
    } else {
      print('5. Fetching channel browse JSON...');
      final browseResponse = await client
          .post(
            Uri.parse('https://www.youtube.com/youtubei/v1/browse'),
            headers: _headers,
            body: jsonEncode(<String, dynamic>{
              'context': _clientContext,
              'browseId': _browseChannelId,
              'params': _browseVideosParams,
            }),
          )
          .timeout(requestTimeout);
      final browse = _captureJson(
        browseResponse,
        'channel browse',
        _validateBrowseResponse,
      );
      saveResponse('testing/browse.json', browse);

      // The continuation page is a separate request carrying the token the
      // same response body hands back. Capturing it here keeps both pages on
      // the same write path, so the redaction in _captureJson applies to it
      // as well. When browse.json was just saved (or --force), the token
      // below is extracted from the freshly fetched body, matching what was
      // written to disk.
      print('6. Fetching channel browse continuation JSON...');
      final continuationToken = _continuationTokenFrom(
        jsonDecode(utf8.decode(browse.bodyBytes)),
      );
      if (continuationToken == null) {
        throw const FormatException(
          'channel browse carried no continuation token: the second page '
          'could not be captured, and testing/browse_continuation.json '
          'would keep whatever it last held',
        );
      }
      final continuationResponse = await client
          .post(
            Uri.parse('https://www.youtube.com/youtubei/v1/browse'),
            headers: _headers,
            body: jsonEncode(<String, dynamic>{
              'context': _clientContext,
              'continuation': continuationToken,
            }),
          )
          .timeout(requestTimeout);
      final continuation = _captureJson(
        continuationResponse,
        'channel browse continuation',
        (dynamic decoded) => _validateBrowseContinuationResponse(
          Map<String, dynamic>.from(decoded as Map),
        ),
      );
      saveResponse('testing/browse_continuation.json', continuation);
    }

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

/// Channel whose `/videos` tab is captured into `testing/browse.json`.
///
/// The previous capture used `UCwXdFgeE9KYzlDUR7te5Suq`, which by 2026-10-01
/// answers HTTP 200 with an `alerts[].alertRenderer` of type `ERROR`. The
/// validator below rejected it only after the fact, so the failure had already
/// been written to disk by then.
const _browseChannelId = 'UCuAXFkgsw1L7xaCfnd5JJOw';

/// `params` that selects the Videos tab, whose content is a `richGridRenderer`.
const _browseVideosParams = 'EgZ2aWRlb3PyBgQKAjoA';

/// Rejects a browse capture the DTO cannot parse.
///
/// Two shapes pass a naive "is `contents` an object" check and must not be
/// saved: a missing channel answers HTTP 200 with an `ERROR` alert and no
/// content, and a channel that no longer uses the rich grid has no video
/// entries at all.
void _validateBrowseResponse(dynamic json) {
  if (json is! Map<String, dynamic>) {
    throw const FormatException('InnerTube browse response is not an object');
  }
  for (final rawAlert in (json['alerts'] as List? ?? const [])) {
    if (rawAlert is! Map) continue;
    final alert = rawAlert['alertRenderer'];
    if (alert is! Map) continue;
    final type = alert['type'];
    if (type is String && type.isNotEmpty && type != 'OK') {
      throw FormatException(
        'InnerTube browse returned alert type "$type": '
        '${alert['text']}',
      );
    }
  }
  // Count what the parser will actually return, not what the grid holds. A
  // grid of unknown renderers, or one holding only a continuation entry, is
  // non-empty on the wire yet yields no items, so counting raw objects would
  // admit a capture the parser reads as an empty channel.
  final items = NetworkYouTubeBrowseResponse.fromJson(json).items;
  if (items.isEmpty) {
    throw const FormatException(
      'InnerTube browse yields no video items: the capture would record a '
      'channel the parser reads as empty',
    );
  }
}

/// Reads the continuation token out of a channel browse response.
String? _continuationTokenFrom(Map<String, dynamic> json) {
  final tabs = json['contents'] is Map
      ? (json['contents']
            as Map<String, dynamic>)['twoColumnBrowseResultsRenderer']
      : null;
  final tabList = tabs is Map ? tabs['tabs'] : null;
  if (tabList is List) {
    for (final rawTab in tabList) {
      if (rawTab is! Map) continue;
      final content = rawTab['tabRenderer'] is Map
          ? (rawTab as Map<String, dynamic>)['tabRenderer']['content']
          : null;
      if (content is! Map) continue;
      final grid = content['richGridRenderer'];
      if (grid is! Map) continue;
      final token = _continuationTokenIn(
        grid as Map<String, dynamic>,
        'contents',
      );
      if (token != null) return token;
    }
  }
  for (final action in json['onResponseReceivedActions'] ?? const <Object>[]) {
    if (action is! Map) continue;
    final append = action['appendContinuationItemsAction'];
    if (append is! Map) continue;
    final token = _continuationTokenIn(
      append as Map<String, dynamic>,
      'continuationItems',
    );
    if (token != null) return token;
  }
  return null;
}

/// Finds the token among a page's items. A rich grid lists them under
/// `contents`; a continuation page carries them under `continuationItems`.
/// The command sits below `continuationEndpoint`, one level under the
/// renderer, which is where the measured responses put it.
String? _continuationTokenIn(Map<String, dynamic> node, String itemsKey) {
  final contents = node[itemsKey];
  if (contents is! List) return null;
  for (final rawItem in contents) {
    if (rawItem is! Map) continue;
    final renderer = rawItem['continuationItemRenderer'];
    if (renderer is! Map) continue;
    final endpoint = (renderer as Map<String, dynamic>)['continuationEndpoint'];
    if (endpoint is! Map) continue;
    final token =
        (endpoint as Map<String, dynamic>)['continuationCommand']?['token'];
    if (token is String) return token;
  }
  return null;
}

/// Rejects a continuation page the parser would read as empty, using the same
/// DTO the channel fixture is checked against.
void _validateBrowseContinuationResponse(Map<String, dynamic> json) {
  final items = NetworkYouTubeBrowseResponse.fromJson(json).items;
  if (items.isEmpty) {
    throw const FormatException(
      'InnerTube browse continuation yields no video items: the capture would '
      'record a page the parser reads as empty',
    );
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
  'serviceTrackingParams',
  'trackingParam',
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

void _validateSearchResponse(
  dynamic json, {
  required bool Function(Map<String, dynamic> item) containsItem,
}) {
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
  if (!_itemSectionsContain(sections, containsItem)) {
    throw const FormatException(
      'InnerTube search response has no item matching the expected shape',
    );
  }
}

bool Function(Map<String, dynamic> item) _rendererItem(String renderer) {
  return (item) => item[renderer] is Map;
}

/// Playlist results arrive as `lockupViewModel` with a `PL`-prefixed
/// [contentId], not as `playlistRenderer` (verified against the live
/// InnerTube WEB endpoint on 2026-09-30: 0 occurrences of `playlistRenderer`).
bool _containsPlaylistLockup(Map<String, dynamic> item) {
  final lockup = item['lockupViewModel'];
  if (lockup is! Map) {
    return false;
  }
  final contentId = lockup['contentId'];
  return contentId is String && contentId.startsWith('PL');
}

bool _itemSectionsContain(
  dynamic sections,
  bool Function(Map<String, dynamic> item) containsItem,
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
    return items.any((item) => item is Map && containsItem(item.cast()));
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
