import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../api/yt_api.dart';
import '../api/yt_interceptor.dart';
import '../client/youtube_client_config.dart';
import '../exception/ypi_exception.dart';
import '../models/network_youtube_search.dart';
import '../protobuf/yt_protobuf_encoder.dart';

final class YoutubeService {
  YoutubeService({
    http.Client? httpClient,
    YoutubeClientConfig config = const YoutubeClientConfig(),
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _config = config {
    _validateConfig();
    _chopperClient = ChopperClient(
      client: _httpClient,
      converter: YoutubeRequestConverter(config),
      interceptors: [YoutubeInnerTubeInterceptor(config)],
    );
    _api = YoutubeApi.create(_chopperClient);
  }

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final YoutubeClientConfig _config;
  late final ChopperClient _chopperClient;
  late final YoutubeApi _api;

  void close() {
    _chopperClient.dispose();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<NetworkYouTubeVideoSearchResponse> searchVideos(
    String query, {
    int? sort,
    int? uploadDate,
    int? duration,
    Set<int> features = const {},
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = query;
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: sort,
        uploadDate: uploadDate,
        contentType: 1,
        duration: duration,
        features: features,
      );
      if (params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _sendSearch(body);
    return _parseResponse(response, NetworkYouTubeVideoSearchResponse.fromJson);
  }

  Future<NetworkYouTubeChannelSearchResponse> searchChannels(
    String query, {
    int? sort,
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = query;
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: sort,
        contentType: 2,
      );
      if (params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _sendSearch(body);
    return _parseResponse(
      response,
      NetworkYouTubeChannelSearchResponse.fromJson,
    );
  }

  Future<NetworkYouTubeSearchSuggestions> getSearchSuggestions(
    String query,
  ) async {
    final Response<String> response;
    try {
      response = await _api.getSearchSuggestions(query);
    } on YpiException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        YpiNetworkException('Google Suggest request failed: $error'),
        stackTrace,
      );
    }

    _throwForStatus(response);
    final body = response.body;
    if (body == null) {
      throw const YpiJsonException('Google Suggest response body is empty');
    }
    return NetworkYouTubeSearchSuggestions.fromResponse(
      query: query,
      responseBody: body,
    );
  }

  Future<Response<Map<String, dynamic>>> _sendSearch(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _api.search(body);
      _throwForStatus(response);
      return response;
    } on YpiException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        YpiNetworkException('YouTube search request failed: $error'),
        stackTrace,
      );
    }
  }

  T _parseResponse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) parser,
  ) {
    final body = response.body;
    if (body == null) {
      throw const YpiJsonException('YouTube search response body is empty');
    }
    try {
      return parser(body);
    } on YpiException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        YpiJsonException('Could not parse YouTube search response: $error'),
        stackTrace,
      );
    }
  }

  void _throwForStatus(Response<Object?> response) {
    if (response.isSuccessful) {
      return;
    }
    throw YpiHttpException(response.statusCode);
  }

  void _validateConfig() {
    final fields = <String, String>{
      'clientName': _config.clientName,
      'clientNameId': _config.clientNameId,
      'clientVersion': _config.clientVersion,
      'language': _config.language,
      'country': _config.country,
      'userAgent': _config.userAgent,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        throw YpiClientContextException(
          'YoutubeClientConfig.${entry.key} must not be empty',
        );
      }
    }
  }
}
