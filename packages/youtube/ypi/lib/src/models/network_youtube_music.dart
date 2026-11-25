import 'package:meta/meta.dart';

import '../exception/ypi_exception.dart';

/// Response of `music/get_search_suggestions`.
@immutable
final class NetworkYouTubeMusicSearchSuggestions {
  const NetworkYouTubeMusicSearchSuggestions({
    required this.query,
    required this.suggestions,
  });

  factory NetworkYouTubeMusicSearchSuggestions.fromJson(
    Map<String, dynamic> json, {
    required String query,
  }) {
    _throwError(json);
    final suggestions = <NetworkYouTubeMusicSuggestion>[];
    for (final section in _list(json['contents'])) {
      final renderer = _map(_map(section)?['searchSuggestionsSectionRenderer']);
      for (final entry in _list(renderer?['contents'])) {
        final suggestion = _map(_map(entry)?['searchSuggestionRenderer']);
        if (suggestion == null) continue;
        final text = _runsText(_map(suggestion['suggestion'])?['runs']);
        if (text == null) continue;
        final endpoint = _map(
          _map(suggestion['navigationEndpoint'])?['searchEndpoint'],
        );
        suggestions.add(
          NetworkYouTubeMusicSuggestion(
            text: text,
            searchQuery: _string(endpoint?['query']),
          ),
        );
      }
    }
    return NetworkYouTubeMusicSearchSuggestions(
      query: query,
      suggestions: List.unmodifiable(suggestions),
    );
  }

  final String query;
  final List<NetworkYouTubeMusicSuggestion> suggestions;
}

@immutable
final class NetworkYouTubeMusicSuggestion {
  const NetworkYouTubeMusicSuggestion({required this.text, this.searchQuery});

  final String text;
  final String? searchQuery;
}

/// Response of the YouTube Music search endpoint (`music.youtube.com`).
///
/// Entries are `musicResponsiveListItemRenderer` items nested in item
/// sections. The top result can be a `musicCardShelfRenderer`, which is not a
/// list item and is intentionally skipped.
@immutable
final class NetworkYouTubeMusicSearchResponse {
  const NetworkYouTubeMusicSearchResponse({
    required this.items,
    this.continuationToken,
  });

  factory NetworkYouTubeMusicSearchResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    _throwError(json);
    final items = <NetworkYouTubeMusicItem>[];
    _collectItems(json, items);
    return NetworkYouTubeMusicSearchResponse(
      items: List.unmodifiable(items),
      continuationToken: _findContinuation(json),
    );
  }

  final List<NetworkYouTubeMusicItem> items;
  final String? continuationToken;
}

@immutable
final class NetworkYouTubeMusicItem {
  const NetworkYouTubeMusicItem({
    this.title,
    this.subtitle,
    this.videoId,
    this.browseId,
    this.pageType,
    this.thumbnailUrl,
  });

  final String? title;
  final String? subtitle;
  final String? videoId;
  final String? browseId;
  final String? pageType;
  final String? thumbnailUrl;
}

void _collectItems(Object? value, List<NetworkYouTubeMusicItem> items) {
  if (value is Map) {
    final renderer = _map(value['musicResponsiveListItemRenderer']);
    if (renderer != null) {
      final item = _parseItem(renderer);
      if (item != null) items.add(item);
    }
    for (final child in value.values) {
      _collectItems(child, items);
    }
  } else if (value is List) {
    for (final child in value) {
      _collectItems(child, items);
    }
  }
}

NetworkYouTubeMusicItem? _parseItem(Map<String, dynamic> renderer) {
  final columns = _list(renderer['flexColumns'])
      .map(_map)
      .nonNulls
      .map(
        (column) => _map(column['musicResponsiveListItemFlexColumnRenderer']),
      )
      .nonNulls
      .toList(growable: false);
  if (columns.isEmpty) return null;

  final title = _runsText(_map(columns.first['text'])?['runs']);
  if (title == null) return null;

  final subtitle = columns.length > 1
      ? _runsText(_map(columns[1]['text'])?['runs'])
      : null;

  final playlistItem = _map(renderer['playlistItemData']);
  final navigation = _map(renderer['navigationEndpoint']);
  final watch = _map(navigation?['watchEndpoint']);
  final browse = _map(navigation?['browseEndpoint']);
  final pageType = _string(
    _map(
      browse?['browseEndpointContextSupportedConfigs'],
    )?['browseEndpointContextMusicConfig']?['pageType'],
  );

  final thumbnails = _list(
    _map(
      _map(renderer['thumbnail'])?['musicThumbnailRenderer'],
    )?['thumbnail']?['thumbnails'],
  );
  final thumbnailUrl = thumbnails.isEmpty
      ? null
      : _string(_map(thumbnails.last)?['url']);

  return NetworkYouTubeMusicItem(
    title: title,
    subtitle: subtitle,
    videoId: _string(playlistItem?['videoId']) ?? _string(watch?['videoId']),
    browseId: _string(browse?['browseId']),
    pageType: pageType,
    thumbnailUrl: thumbnailUrl,
  );
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

String? _runsText(Object? value) {
  if (value is! List || value.isEmpty) return null;
  final text = value
      .map(_map)
      .nonNulls
      .map((run) => _string(run['text']) ?? '')
      .join();
  return text.isEmpty ? null : text;
}

void _throwError(Map<String, dynamic> json) {
  final error = _map(json['error']);
  if (error == null) return;
  throw YpiInnerTubeException(
    code: error['code'] is int ? error['code'] as int : null,
    continuation: null,
    reason: _string(error['message']) ?? _string(error['status']),
  );
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

String? _string(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}

List<Object?> _list(Object? value) {
  if (value is! List) return const [];
  return value;
}
