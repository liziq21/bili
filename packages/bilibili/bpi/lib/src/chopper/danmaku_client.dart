import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api.dart';
import '../error/bpi_exception.dart';
import '../model/video/network_bili_danmaku.dart';

/// Fetches the public XML danmaku document for a video.
///
/// The endpoint answers with XML instead of the JSON envelope every other
/// endpoint returns, so it stays on the raw client and outside the Chopper
/// converter pipeline.
final class BiliDanmakuClient(final http.Client _client) {
  Future<NetworkBiliDanmakuDocument> fetch({required int cid}) async {
    if (cid <= 0) {
      throw const BpiSerializationException('Danmaku cid must be positive');
    }

    final uri = Uri.parse(DanmakuApi.comment(cid));
    late final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://www.bilibili.com/',
        },
      );
    } on Object catch (error) {
      throw BpiNetworkException(
        'Bilibili danmaku request failed.',
        uri: uri,
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BpiHttpException(
        'Bilibili danmaku request returned HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
        uri: uri,
      );
    }

    try {
      return NetworkBiliDanmakuDocument.fromXml(
        utf8.decode(_decodeBody(response)),
      );
    } on BpiException {
      rethrow;
    } on Object catch (error) {
      throw BpiSerializationException(
        'Bilibili danmaku response is not valid XML.',
        uri: uri,
        cause: error,
      );
    }
  }

  List<int> _decodeBody(http.Response response) {
    return switch (response.headers['content-encoding']?.toLowerCase()) {
      'deflate' => _decodeDeflate(response.bodyBytes),
      'gzip' => GZipCodec().decode(response.bodyBytes),
      _ => response.bodyBytes,
    };
  }

  List<int> _decodeDeflate(List<int> bytes) {
    try {
      return ZLibCodec().decode(bytes);
    } on Object {
      // Some CDN edges label a raw DEFLATE stream as `deflate`.
      return ZLibCodec(raw: true).decode(bytes);
    }
  }
}
