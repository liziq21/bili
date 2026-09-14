// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'yt_api.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$YoutubeApi extends YoutubeApi {
  _$YoutubeApi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = YoutubeApi;

  @override
  Future<Response<Map<String, dynamic>>> search(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('https://www.youtube.com/youtubei/v1/search');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<Map<String, dynamic>>> getPlayer(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('https://www.youtube.com/youtubei/v1/player');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Map<String, dynamic>, Map<String, dynamic>>($request);
  }

  @override
  Future<Response<String>> getSearchSuggestions(
    String query, {
    String searchClient = 'youtube',
    String ds = 'yt',
  }) {
    final Uri $url = Uri.parse(
      'https://suggestqueries.google.com/complete/search',
    );
    final Map<String, dynamic> $params = <String, dynamic>{
      'q': query,
      'client': searchClient,
      'ds': ds,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<String, String>($request);
  }
}
