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
import '../models/network_youtube_resolve_url.dart';
import '../models/network_youtube_search.dart';
import '../models/network_youtube_live_directory.dart';
import '../models/network_youtube_watch_next.dart';
import '../models/network_youtube_music.dart';

final class YoutubeService {
  YoutubeService({
    http.Client? httpClient,
    YoutubeClientConfig config = const YoutubeClientConfig(),
    YoutubeClientConfig playerConfig = const YoutubeClientConfig.ios(),
    YoutubeClientConfig musicConfig = const YoutubeClientConfig.music(),
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _playerConfig = playerConfig {
    _validateConfig(config);
    _validateConfig(playerConfig);
    _validateConfig(musicConfig);
    _chopperClient = ChopperClient(
      client: _httpClient,
      converter: YoutubeRequestConverter(config),
      interceptors: [YoutubeInnerTubeInterceptor(config)],
    );
    _api = YoutubeApi.create(_chopperClient);
    _playerChopperClient = ChopperClient(
      client: _httpClient,
      converter: YoutubeRequestConverter(playerConfig),
      interceptors: [YoutubeInnerTubeInterceptor(playerConfig)],
    );
    _playerApi = YoutubeApi.create(_playerChopperClient);
    _musicChopperClient = ChopperClient(
      client: _httpClient,
      converter: YoutubeRequestConverter(musicConfig),
      interceptors: [YoutubeInnerTubeInterceptor(musicConfig)],
    );
    _musicApi = YoutubeApi.create(_musicChopperClient);
  }

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final YoutubeClientConfig _playerConfig;
  late final ChopperClient _chopperClient;
  late final ChopperClient _playerChopperClient;
  late final ChopperClient _musicChopperClient;
  late final YoutubeApi _api;
  late final YoutubeApi _playerApi;
  late final YoutubeApi _musicApi;

  /// The user agent used for player requests.
  ///
  /// Stream URLs returned by the player endpoint are requested by the media
  /// player rather than this HTTP client, so the adapter layer forwards this
  /// value as the playback request's `User-Agent`.
  String get playerUserAgent => _playerConfig.userAgent;

  void close() {
    _chopperClient.dispose();
    _playerChopperClient.dispose();
    _musicChopperClient.dispose();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  /// Searches videos.
  ///
  /// The `params` filter string is an opaque, already-encoded InnerTube search
  /// filter: callers build it from their own filter model and this package
  /// never interprets it. Content-type filtering is left to the caller so that
  /// the same request shape serves every search tab.
  Future<NetworkYouTubeVideoSearchResponse> searchVideos(
    String query, {
    String? params,
    String? continuation,
  }) async {
    final body = _searchBody(query, params: params, continuation: continuation);
    final response = await _sendSearch(body);
    return _parseResponse(response, NetworkYouTubeVideoSearchResponse.fromJson);
  }

  Future<NetworkYouTubeChannelSearchResponse> searchChannels(
    String query, {
    String? params,
    String? continuation,
  }) async {
    final body = _searchBody(query, params: params, continuation: continuation);
    final response = await _sendSearch(body);
    return _parseResponse(
      response,
      NetworkYouTubeChannelSearchResponse.fromJson,
    );
  }

  Future<NetworkYouTubePlaylistSearchResponse> searchPlaylists(
    String query, {
    String? params,
    String? continuation,
  }) async {
    final body = _searchBody(query, params: params, continuation: continuation);
    final response = await _sendSearch(body);
    return _parseResponse(
      response,
      NetworkYouTubePlaylistSearchResponse.fromJson,
    );
  }

  /// Builds a search body: a continuation request on later pages, otherwise a
  /// fresh query with the opaque [params] filter string when one is given.
  Map<String, dynamic> _searchBody(
    String query, {
    String? params,
    String? continuation,
  }) {
    final body = <String, dynamic>{};
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
      return body;
    }
    body['query'] = query.replaceAll(_controlChars, '');
    final sanitizedParams = params?.replaceAll(_controlChars, '');
    if (sanitizedParams != null && sanitizedParams.isNotEmpty) {
      body['params'] = sanitizedParams;
    }
    return body;
  }

  Future<NetworkYouTubeWatchNextResponse> getWatchNext({
    String? videoId,
    String? playlistId,
    String? params,
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    final sanitizedVideoId = videoId?.replaceAll(_controlChars, '');
    final sanitizedPlaylistId = playlistId?.replaceAll(_controlChars, '');
    final sanitizedParams = params?.replaceAll(_controlChars, '');
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
    } else {
      if (sanitizedVideoId == null || sanitizedVideoId.isEmpty) {
        throw const YpiJsonException(
          'getWatchNext requires either videoId or continuation',
        );
      }
      body['videoId'] = sanitizedVideoId;
      if (sanitizedPlaylistId != null && sanitizedPlaylistId.isNotEmpty) {
        body['playlistId'] = sanitizedPlaylistId;
      }
      if (sanitizedParams != null && sanitizedParams.isNotEmpty) {
        body['params'] = sanitizedParams;
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
    final sanitizedContinuation = continuation
        .replaceAll(_controlChars, '')
        .trim();
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

    final response = await _send(_playerApi.player, body);
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
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    final sanitizedParams = params?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
    } else {
      final id = browseId?.replaceAll(_controlChars, '');
      if (id == null || id.isEmpty) {
        throw const YpiJsonException(
          'browseChannel requires either browseId or continuation',
        );
      }
      body['browseId'] = id;
      if (sanitizedParams != null && sanitizedParams.isNotEmpty) {
        body['params'] = sanitizedParams;
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
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    final sanitizedParams = params?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
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
      if (sanitizedParams != null && sanitizedParams.isNotEmpty) {
        body['params'] = sanitizedParams;
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
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
    } else {
      body['browseId'] = 'FEwhat_to_watch';
    }

    final response = await _send(_api.browse, body);
    return _parseResponse(response, NetworkYouTubeBrowseResponse.fromJson);
  }

  /// Resolves a YouTube URL to the InnerTube endpoint that serves it.
  ///
  /// This is the supported way to classify a shared link without matching URL
  /// patterns locally: the response names a `videoId`, `playlistId`, or
  /// `browseId` (channel, handle, or music page).
  Future<NetworkYouTubeResolveUrlResponse> resolveUrl(String url) async {
    final sanitized = url.replaceAll(_controlChars, '').trim();
    if (sanitized.isEmpty) {
      throw const YpiJsonException('resolveUrl requires url');
    }
    final body = <String, dynamic>{'url': sanitized};
    final response = await _send(_api.resolveUrl, body);
    return _parseResponse(response, NetworkYouTubeResolveUrlResponse.fromJson);
  }

  /// Fetches the YouTube Live directory, or the next page of it.
  ///
  /// The general Trending page is not available to anonymous clients, so this
  /// browses `browseId=UC4R8DWoMoI7CAwX8_LjQHig` instead. Its entries are
  /// `videoRenderer` items, unlike a channel grid's `lockupViewModel`.
  Future<NetworkYouTubeLiveDirectoryResponse> browseLiveDirectory({
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
    } else {
      body['browseId'] = 'UC4R8DWoMoI7CAwX8_LjQHig';
    }
    final response = await _send(_api.browse, body);
    return _parseResponse(
      response,
      NetworkYouTubeLiveDirectoryResponse.fromJson,
    );
  }

  /// Fetches YouTube Music search suggestions for [query].
  Future<NetworkYouTubeMusicSearchSuggestions> getMusicSearchSuggestions(
    String query,
  ) async {
    final sanitized = query.replaceAll(_controlChars, '');
    final body = <String, dynamic>{'input': sanitized};
    final response = await _send(_musicApi.getMusicSearchSuggestions, body);
    return _parseResponse(
      response,
      (json) =>
          NetworkYouTubeMusicSearchSuggestions.fromJson(json, query: sanitized),
    );
  }

  /// Searches YouTube Music.
  ///
  /// Music results only come back for the `WEB_REMIX` client context, which
  /// this method sends through its own client rather than [config].
  Future<NetworkYouTubeMusicSearchResponse> searchMusic(
    String query, {
    String? params,
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    final sanitizedContinuation = continuation?.replaceAll(_controlChars, '');
    if (sanitizedContinuation != null && sanitizedContinuation.isNotEmpty) {
      body['continuation'] = sanitizedContinuation;
    } else {
      body['query'] = query.replaceAll(_controlChars, '');
      final sanitizedParams = params?.replaceAll(_controlChars, '');
      if (sanitizedParams != null && sanitizedParams.isNotEmpty) {
        body['params'] = sanitizedParams;
      }
    }
    final response = await _send(_musicApi.musicSearch, body);
    return _parseResponse(response, NetworkYouTubeMusicSearchResponse.fromJson);
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

  void _validateConfig(YoutubeClientConfig config) {
    final fields = <String, String>{
      'clientName': config.clientName,
      'clientNameId': config.clientNameId,
      'clientVersion': config.clientVersion,
      'language': config.language,
      'country': config.country,
      'userAgent': config.userAgent,
      if (config.osName != null) 'osName': config.osName!,
      if (config.osVersion != null) 'osVersion': config.osVersion!,
      if (config.deviceMake != null) 'deviceMake': config.deviceMake!,
      if (config.deviceModel != null) 'deviceModel': config.deviceModel!,
    };
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        throw YpiClientContextException(
          'YoutubeClientConfig.${entry.key} must not be empty',
        );
      }
    }
    final sdk = config.androidSdkVersion;
    if (sdk != null && sdk <= 0) {
      throw const YpiClientContextException(
        'YoutubeClientConfig.androidSdkVersion must be positive',
      );
    }
  }
}
