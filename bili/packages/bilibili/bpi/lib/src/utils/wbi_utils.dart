import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';

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
  ];

  static final RegExp _chrFilter = RegExp(r"[!\'\(\)\*]");

  static Future<String> fetchMixinKey(Client client) async {
    final uri = Uri.parse('https://api.bilibili.com/x/web-interface/nav');
    final response = await client.get(uri);

    if (response.statusCode != 200) throw response;

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final {
      'data': {'wbi_img': {'img_url': String imgUrl, 'sub_url': String subUrl}},
    } = json;

    final String imgKey = Uri.parse(imgUrl).pathSegments.last.split('.').first;
    final String subKey = Uri.parse(subUrl).pathSegments.last.split('.').first;
    return generateMixinKey(imgKey + subKey);
  }

  static String generateMixinKey(String rawWbiKey) {
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(rawWbiKey[_mixinKeyEncTab[i]]);
    }
    return buffer.toString();
  }

  static Map<String, dynamic> encWbi(
    Map<String, dynamic> params,
    String mixinKey,
  ) {
    params.remove("w_rid");
    params["wts"] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var sortedKeys = params.keys.toList()..sort();
    var encodedParams = sortedKeys
        .map(
          (key) =>
              "${Uri.encodeComponent(key)}=${Uri.encodeComponent(params[key].toString().replaceAll(_chrFilter, ''))}",
        )
        .join("&");

    var wRid = md5.convert(utf8.encode(encodedParams + mixinKey)).toString();
    params["w_rid"] = wRid;
    return params;
  }
}
