import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../api/yt_api.dart';
import '../api/yt_interceptor.dart';
import '../client/youtube_client_config.dart';
import '../exception/ypi_exception.dart';
import '../models/network_youtube_browse.dart';
import '../models/network_youtube_comments.dart';
import '../models/network_youtube_player.dart';
import '../models/network_youtube_playlist_browse.dart';
import '../models/network_youtube_search.dart';
import '../models/network_youtube_watch_next.dart';
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

  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  Future<NetworkYouTubeVideoSearchResponse> searchVideos(
    String query, {
    int? sort,
    int? uploadDate,
    int? duration,
    Set<int> features = const {},
    String? continuation,
  }) async {
    final sanitizedQuery = query.replaceAll(_controlChars, '');
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = sanitizedQuery;
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
    final sanitizedQuery = query.replaceAll(_controlChars, '');
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = sanitizedQuery;
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

  Future<NetworkYouTubePlaylistSearchResponse> searchPlaylists(
    String query, {
    int? sort,
    String? continuation,
  }) async {
    final sanitizedQuery = query.replaceAll(_controlChars, '');
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = sanitizedQuery;
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: sort,
        contentType: 3,
      );
      if (params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _sendSearch(body);
    return _parseResponse(
      response,
      NetworkYouTubePlaylistSearchResponse.fromJson,
    );
  }

  Future<NetworkYouTubeWatchNextResponse> getWatchNext({
    String? videoId,
    String? playlistId,
    String? params,
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    final sanitizedVideoId = videoId?.replaceAll(_controlChars, '');
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      if (sanitizedVideoId == null || sanitizedVideoId.isEmpty) {
        throw const YpiJsonException(
          'getWatchNext requires either videoId or continuation',
        );
      }
      body['videoId'] = sanitizedVideoId;
      if (playlistId != null && playlistId.isNotEmpty) {
        body['playlistId'] = playlistId;
      }
      if (params != null && params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _send(_api.next, body);
    return _parseResponse(
      response,
      (json) => NetworkYouTubeWatchNextResponse.fromJson(
        json,
        requestedVideoId: sanitizedVideoId,
      ),
    );
  }

  /// Fetches comment threads for a video using a comment [continuation] token.
  Future<NetworkYouTubeCommentsResponse> getComments(
    String continuation,
  ) async {
    final sanitizedContinuation = continuation.trim();
    if (sanitizedContinuation.isEmpty) {
      throw const YpiJsonException('getComments requires continuation');
    }
    final body = <String, dynamic>{'continuation': sanitizedContinuation};

    final response = await _send(_api.next, body);
    return _parseResponse(response, NetworkYouTubeCommentsResponse.fromJson);
  }

  /// Fetches video player data including details and streaming formats for a [videoId].
  Future<NetworkYouTubePlayerResponse> getPlayer(String videoId) async {
    final sanitizedVideoId = videoId.replaceAll(_controlChars, '').trim();
    if (sanitizedVideoId.isEmpty) {
      throw const YpiJsonException('getPlayer requires videoId');
    }
    final body = <String, dynamic>{'videoId': sanitizedVideoId};

    final response = await _send(_api.player, body);
    return _parseResponse(
      response,
      (json) => NetworkYouTubePlayerResponse.fromJson(
        json,
        requestedVideoId: sanitizedVideoId,
      ),
    );
  }

  Future<NetworkYouTubeSearchSuggestions> getSearchSuggestions(
    String query,
  ) async {
    final sanitizedQuery = query.replaceAll(_controlChars, '');
    final Response<String> response;
    try {
      response = await _api.getSearchSuggestions(sanitizedQuery);
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
      query: sanitizedQuery,
      responseBody: body,
    );
  }

  /// Fetches a channel page, or the next page of one.
  ///
  /// Pass a [continuation] from a previous response instead of [browseId] to
  /// page through a channel's videos. The response merges the first page's
  /// `richGridRenderer` entries with those in
  /// `appendContinuationItemsAction.continuationItems`, because a continuation
  /// page returns the same entry shape the grid it came from uses.
  Future<NetworkYouTubeBrowseResponse> browseChannel({
    String? browseId,
    String? continuation,
    String? params,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      final id = browseId?.replaceAll(_controlChars, '');
      if (id == null || id.isEmpty) {
        throw const YpiJsonException(
          'browseChannel requires either browseId or continuation',
        );
      }
      body['browseId'] = id;
      if (params != null && params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _send(_api.browse, body);
    return _parseResponse(response, NetworkYouTubeBrowseResponse.fromJson);
  }

  /// Fetches a playlist page, or the next page of one.
  ///
  /// Pass a [continuation] from a previous response instead of [playlistId] or
  /// [browseId] to page through a playlist's items.
  Future<NetworkYouTubePlaylistBrowseResponse> browsePlaylist({
    String? playlistId,
    String? browseId,
    String? continuation,
    String? params,
  }) async {
    final body = <String, dynamic>{};
    // Sanitise once here so the id echoed back through `requestedPlaylistId`
    // is the same one actually sent to the endpoint.
    final targetId = (playlistId ?? browseId)?.replaceAll(_controlChars, '');
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      if (targetId == null || targetId.isEmpty) {
        throw const YpiJsonException(
          'browsePlaylist requires either playlistId, browseId, or continuation',
        );
      }
      final formattedBrowseId = targetId.startsWith('VL')
          ? targetId
          : 'VL$targetId';
      body['browseId'] = formattedBrowseId;
      if (params != null && params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _send(_api.browse, body);
    return _parseResponse(
      response,
      (json) => NetworkYouTubePlaylistBrowseResponse.fromJson(
        json,
        requestedPlaylistId: targetId,
      ),
    );
  }

  /// Fetches the home feed (recommendations), or the next page of it.
  ///
  /// Pass a [continuation] from a previous response to page through the feed.
  Future<NetworkYouTubeBrowseResponse> browseHomeFeed({
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['browseId'] = 'FEwhat_to_watch';
    }

    final response = await _send(_api.browse, body);
    return _parseResponse(response, NetworkYouTubeBrowseResponse.fromJson);
  }

  /// Runs an InnerTube POST against a path that takes the shared client body.
  Future<Response<Map<String, dynamic>>> _send(
    Future<Response<Map<String, dynamic>>> Function(Map<String, dynamic>) call,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await call(body);
      _throwForStatus(response);
      return response;
    } on YpiException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        YpiNetworkException('YouTube request failed: $error'),
        stackTrace,
      );
    }
  }

  Future<Response<Map<String, dynamic>>> _sendSearch(
    Map<String, dynamic> body,
  ) async {
    return _send(_api.search, body);
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
