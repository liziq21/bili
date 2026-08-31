import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';

import '../error/bpi_exception.dart';

abstract final class WbiUtils {
  static const _mixinKeyEncTab = <int>[
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52,
  ];

  static final RegExp _chrFilter = RegExp(r"[!\'\(\)\*]");

  static Future<String> fetchMixinKey(Client client) async {
    final uri = Uri.parse('https://api.bilibili.com/x/web-interface/nav');
    late final Response response;
    try {
      response = await client.get(
        uri,
        headers: const {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://www.bilibili.com/',
        },
      );
    } on Object catch (error) {
      throw WbiException('Failed to fetch WBI keys.', uri: uri, cause: error);
    }

    if (response.statusCode != 200) {
      throw BpiHttpException(
        'The WBI key endpoint returned an unexpected status.',
        statusCode: response.statusCode,
        uri: uri,
      );
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on Object catch (error) {
      throw WbiException(
        'The WBI key endpoint returned invalid JSON.',
        uri: uri,
        cause: error,
      );
    }

    if (decoded is! Map) {
      throw WbiException(
        'The WBI key response must be a JSON object.',
        uri: uri,
      );
    }

    final json = Map<String, dynamic>.from(decoded);
    final code = _parseInt(json['code']);
    if (code != 0) {
      throw BiliApiException(
        (json['message'] ?? 'The WBI key endpoint returned an error.')
            .toString(),
        biliCode: code ?? -1,
        uri: uri,
      );
    }

    final data = json['data'];
    final wbiImg = data is Map ? data['wbi_img'] : null;
    final imgUrl = wbiImg is Map ? wbiImg['img_url'] : null;
    final subUrl = wbiImg is Map ? wbiImg['sub_url'] : null;
    if (imgUrl is! String || subUrl is! String) {
      throw WbiException(
        'The WBI key response is missing img_url or sub_url.',
        uri: uri,
      );
    }

    final imgKey = _extractKey(imgUrl, uri);
    final subKey = _extractKey(subUrl, uri);
    return generateMixinKey(imgKey + subKey);
  }

  static String generateMixinKey(String rawWbiKey) {
    if (rawWbiKey.length < 64) {
      throw WbiException('The combined WBI key is too short.');
    }
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(rawWbiKey[_mixinKeyEncTab[i]]);
    }
    return buffer.toString();
  }

  static Map<String, dynamic> encWbi(
    Map<String, dynamic> params,
    String mixinKey, {
    int? timestamp,
  }) {
    final signedParams = <String, dynamic>{
      for (final MapEntry(:key, :value) in params.entries)
        if (value != null && key != 'w_rid' && key != 'wts') key: value,
    };
    signedParams['wts'] =
        timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final sortedKeys = signedParams.keys.toList()..sort();
    final encodedParams = sortedKeys
        .map(
          (key) =>
              '${Uri.encodeQueryComponent(key)}='
              '${Uri.encodeQueryComponent(signedParams[key].toString().replaceAll(_chrFilter, ''))}',
        )
        .join("&");

    signedParams['w_rid'] = md5
        .convert(utf8.encode(encodedParams + mixinKey))
        .toString();
    return signedParams;
  }

  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value) : null;
  }

  static String _extractKey(String value, Uri uri) {
    final parsed = Uri.tryParse(value);
    final segments = parsed?.pathSegments;
    final lastSegment = segments == null || segments.isEmpty
        ? null
        : segments.last;
    final key = lastSegment?.split('.').first;
    if (key == null || key.isEmpty) {
      throw WbiException('The WBI key URL is invalid.', uri: uri);
    }
    return key;
  }
}
