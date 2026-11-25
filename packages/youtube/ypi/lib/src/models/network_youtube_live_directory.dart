import 'package:meta/meta.dart';

import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Response of the YouTube Live directory browse
/// (`browseId=UC4R8DWoMoI7CAwX8_LjQHig`).
///
/// YouTube's general Trending page is not reachable by anonymous clients
/// (`FEtrending` answers `INVALID_ARGUMENT`), so this is the Live tab: sections
/// such as "live now", "recent live" and "upcoming". Its entries are plain
/// `videoRenderer`s inside `richGridRenderer`, not the `lockupViewModel` a
/// channel grid returns, so it needs its own collector.
@immutable
final class NetworkYouTubeLiveDirectoryResponse {
  const NetworkYouTubeLiveDirectoryResponse({
    required this.videos,
    this.continuationToken,
  });

  factory NetworkYouTubeLiveDirectoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final error = _map(json['error']);
    if (error != null) {
      throw YpiInnerTubeException(
        code: error['code'] is int ? error['code'] as int : null,
        continuation: null,
        reason: _string(error['message']) ?? _string(error['status']),
      );
    }

    final videos = <NetworkYouTubeVideoRenderer>[];
    final seen = <String>{};
    _collectVideos(json, videos, seen);

    if (videos.isEmpty) {
      throw const FormatException(
        'live directory response carries no videoRenderer entries',
      );
    }

    return NetworkYouTubeLiveDirectoryResponse(
      videos: List.unmodifiable(videos),
      continuationToken: _findContinuation(json),
    );
  }

  final List<NetworkYouTubeVideoRenderer> videos;
  final String? continuationToken;
}

void _collectVideos(
  Object? value,
  List<NetworkYouTubeVideoRenderer> videos,
  Set<String> seen,
) {
  if (value is Map) {
    final renderer = _map(value['videoRenderer']);
    if (renderer != null) {
      try {
        final video = NetworkYouTubeVideoRenderer.fromJson(renderer);
        if (seen.add(video.videoId)) {
          videos.add(video);
        }
      } on FormatException {
        // A video without an id cannot be opened; skip it like other entries.
      }
    }
    for (final child in value.values) {
      _collectVideos(child, videos, seen);
    }
  } else if (value is List) {
    for (final child in value) {
      _collectVideos(child, videos, seen);
    }
  }
}

String? _findContinuation(Object? value) {
  if (value is Map) {
    final renderer = _map(value['continuationItemRenderer']);
    final endpoint = _map(renderer?['continuationEndpoint']);
    final command = _map(endpoint?['continuationCommand']);
    final token = _string(command?['token']);
    if (token != null) return token;
    for (final child in value.values) {
      final token = _findContinuation(child);
      if (token != null) return token;
    }
  } else if (value is List) {
    for (final child in value) {
      final token = _findContinuation(child);
      if (token != null) return token;
    }
  }
  return null;
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

String? _string(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}
