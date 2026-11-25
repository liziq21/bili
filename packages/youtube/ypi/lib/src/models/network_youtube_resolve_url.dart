import '../exception/ypi_exception.dart';

/// Response of `navigation/resolve_url`, which turns a YouTube URL into the
/// InnerTube endpoint that serves it.
final class NetworkYouTubeResolveUrlResponse {
  const NetworkYouTubeResolveUrlResponse({
    this.browseId,
    this.videoId,
    this.playlistId,
    this.canonicalUrl,
    this.webPageType,
  });

  factory NetworkYouTubeResolveUrlResponse.fromJson(Map<String, dynamic> json) {
    final error = _map(json['error']);
    if (error != null) {
      throw YpiInnerTubeException(
        code: error['code'] is int ? error['code'] as int : null,
        continuation: null,
        reason: _string(error['message']) ?? _string(error['status']),
      );
    }

    final endpoint = _map(json['endpoint']);
    if (endpoint == null) {
      throw const FormatException(
        'resolve_url response is missing an endpoint object',
      );
    }

    final commandMetadata = _map(endpoint['commandMetadata']);
    final webCommandMetadata = _map(commandMetadata?['webCommandMetadata']);
    final browse = _map(endpoint['browseEndpoint']);
    final watch = _map(endpoint['watchEndpoint']);
    final playlist = _map(endpoint['watchPlaylistEndpoint']);

    final response = NetworkYouTubeResolveUrlResponse(
      browseId: _string(browse?['browseId']),
      videoId: _string(watch?['videoId']),
      playlistId:
          _string(playlist?['playlistId']) ??
          _string(browse?['playlistId']) ??
          _string(watch?['playlistId']),
      canonicalUrl: _string(webCommandMetadata?['url']),
      webPageType: _string(webCommandMetadata?['webPageType']),
    );
    if (response.browseId == null &&
        response.videoId == null &&
        response.playlistId == null) {
      throw const FormatException(
        'resolve_url endpoint carries no browse, video, or playlist id',
      );
    }
    return response;
  }

  final String? browseId;
  final String? videoId;
  final String? playlistId;
  final String? canonicalUrl;
  final String? webPageType;
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

String? _string(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}
