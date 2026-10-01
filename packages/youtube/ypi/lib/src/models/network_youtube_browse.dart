import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Channel header returned by an InnerTube `/youtubei/v1/browse` response.
///
/// 2026-03: YouTube serves channel headers in two shapes. A live channel gets
/// `c4TabbedHeaderRenderer`; a channel without a classic tab layout gets
/// `pageHeaderRenderer`, whose `pageHeaderViewModel` sub-object no longer
/// exists — the title is a plain `pageTitle` string and the channel ID lives in
/// the response's `metadata.channelMetadataRenderer.externalId`. The measured
/// values behind those statements are recorded in `testing/browse.json`.
final class NetworkYouTubeChannelHeader {
  const NetworkYouTubeChannelHeader({
    required this.channelId,
    this.title,
    this.avatar,
    this.banner,
    this.subscriberCountText,
  });

  factory NetworkYouTubeChannelHeader.fromJson(
    Map<String, dynamic> json, {
    String? externalChannelId,
  }) {
    final c4 = _map(json['c4TabbedHeaderRenderer']);
    if (c4 != null) {
      final channelId = _string(c4['channelId']);
      if (channelId == null || channelId.isEmpty) {
        throw const FormatException(
          'c4TabbedHeaderRenderer is missing channelId',
        );
      }
      return NetworkYouTubeChannelHeader(
        channelId: channelId,
        title: _string(c4['title']),
        avatar: NetworkYouTubeThumbnail.fromJson(c4['avatar']),
        banner: NetworkYouTubeThumbnail.fromJson(c4['banner']),
        subscriberCountText: NetworkYouTubeText.fromJson(
          c4['subscriberCountText'],
        ),
      );
    }

    final pageHeader = _map(json['pageHeaderRenderer']);
    if (pageHeader != null) {
      // `channelId` is not optional for a caller: it is the handle used to
      // request the channel again. Rather than hand back an empty string that
      // silently breaks the next browse, require it and let a header without
      // one be reported as unparseable.
      final channelId = externalChannelId;
      if (channelId == null || channelId.isEmpty) {
        throw const FormatException(
          'pageHeaderRenderer has no channel ID: the response carries no '
          'metadata.channelMetadataRenderer.externalId',
        );
      }
      return NetworkYouTubeChannelHeader(
        channelId: channelId,
        title: _string(pageHeader['pageTitle']),
      );
    }

    throw const FormatException(
      'Header json does not contain recognized header renderer',
    );
  }

  final String channelId;
  final String? title;
  final NetworkYouTubeThumbnail? avatar;
  final NetworkYouTubeThumbnail? banner;
  final NetworkYouTubeText? subscriberCountText;
}

/// A tab of a channel page. YouTube uses `tabRenderer` for the fixed tabs and
/// `expandableTabRenderer` for the search entry; only the former carries
/// content in the browse response.
final class NetworkYouTubeTab {
  const NetworkYouTubeTab({this.title, this.selected = false, this.content});

  factory NetworkYouTubeTab.fromJson(Map<String, dynamic> json) {
    final tab =
        _map(json['tabRenderer']) ?? _map(json['expandableTabRenderer']);
    if (tab == null) {
      throw const FormatException('Tab json has no recognized tab renderer');
    }
    return NetworkYouTubeTab(
      title: _string(tab['title']),
      selected: tab['selected'] == true,
      content: _map(tab['content']),
    );
  }

  final String? title;
  final bool selected;
  final Map<String, dynamic>? content;
}

/// A `lockupViewModel` entry, the shape YouTube uses for videos inside a
/// channel's rich grid.
final class NetworkYouTubeLockupItem {
  const NetworkYouTubeLockupItem({
    required this.contentId,
    required this.contentType,
    this.title,
    this.thumbnail,
    this.metadataRows = const [],
  });

  factory NetworkYouTubeLockupItem.fromJson(Map<String, dynamic> json) {
    final metadataViewModel = _map(
      _map(json['metadata'])?['lockupMetadataViewModel'],
    );
    final title = _string(_map(metadataViewModel?['title'])?['content']);
    if (title == null) {
      throw const FormatException('lockupViewModel is missing a title');
    }

    // A caller cannot open, deduplicate or request an entry without this ID,
    // so an entry lacking it is discarded rather than reported with an empty
    // one. Throwing is what drops it: `_lockupFromJson` catches this and the
    // surrounding collection keeps going.
    final contentId = _string(json['contentId']);
    if (contentId == null) {
      throw const FormatException('lockupViewModel is missing a contentId');
    }

    final rows = <String>[];
    final metadataRows = _map(
      _map(metadataViewModel?['metadata'])?['contentMetadataViewModel'],
    )?['metadataRows'];
    for (final rawRow in _list(metadataRows).map(_map).nonNulls) {
      for (final rawPart in _list(rawRow['metadataParts']).map(_map).nonNulls) {
        final text = _string(_map(rawPart['text'])?['content']);
        if (text != null) rows.add(text);
      }
    }

    return NetworkYouTubeLockupItem(
      contentId: contentId,
      contentType: _string(json['contentType']) ?? '',
      title: title,
      thumbnail: _lockupThumbnail(json['contentImage']),
      metadataRows: List.unmodifiable(rows),
    );
  }

  final String contentId;
  final String contentType;
  final String? title;
  final NetworkYouTubeThumbnail? thumbnail;
  final List<String> metadataRows;
}

/// Response returned by YouTube InnerTube `/youtubei/v1/browse`.
final class NetworkYouTubeBrowseResponse {
  const NetworkYouTubeBrowseResponse({
    this.responseContext,
    this.header,
    this.tabs = const [],
    this.items = const [],
    this.continuationToken,
  });

  factory NetworkYouTubeBrowseResponse.fromJson(Map<String, dynamic> json) {
    _throwInnerTubeError(json);
    _throwAlertError(json);

    final externalChannelId = _string(
      _map(_map(json['metadata'])?['channelMetadataRenderer'])?['externalId'],
    );

    NetworkYouTubeChannelHeader? header;
    final headerMap = _map(json['header']);
    if (headerMap != null) {
      try {
        header = NetworkYouTubeChannelHeader.fromJson(
          headerMap,
          externalChannelId: externalChannelId,
        );
      } on FormatException {
        header = null;
      }
    }

    final tabs = <NetworkYouTubeTab>[];
    final items = <NetworkYouTubeLockupItem>[];
    String? continuationToken;

    final contentsMap = _map(json['contents']);
    if (contentsMap != null) {
      final twoCol = _map(contentsMap['twoColumnBrowseResultsRenderer']);
      final singleCol = _map(contentsMap['singleColumnBrowseResultsRenderer']);
      final activeCol = twoCol ?? singleCol;

      for (final rawTab in _list(activeCol?['tabs']).map(_map).nonNulls) {
        final tab = NetworkYouTubeTab.fromJson(rawTab);
        tabs.add(tab);

        final tabContent = tab.content;
        if (tabContent == null) continue;

        final richGrid = _map(tabContent['richGridRenderer']);
        if (richGrid != null) {
          _collectRichGrid(richGrid, items, (token) {
            continuationToken ??= token;
          });
        }

        final sectionList = _map(tabContent['sectionListRenderer']);
        if (sectionList != null) {
          for (final rawSection in _list(
            sectionList['contents'],
          ).map(_map).nonNulls) {
            final itemSection = _map(rawSection['itemSectionRenderer']);
            if (itemSection != null) {
              for (final rawEntry in _list(
                itemSection['contents'],
              ).map(_map).nonNulls) {
                final lockup = _lockupFromJson(rawEntry);
                if (lockup != null) items.add(lockup);
              }
              continue;
            }
            final continuation = _continuationTokenFromJson(
              _map(rawSection['continuationItemRenderer']),
            );
            if (continuation != null) continuationToken ??= continuation;
          }
        }
      }
    }

    for (final rawAction in _list(
      json['onResponseReceivedActions'],
    ).map(_map).nonNulls) {
      final appendAction = _map(rawAction['appendContinuationItemsAction']);
      if (appendAction == null) continue;
      for (final rawItem in _list(
        appendAction['continuationItems'],
      ).map(_map).nonNulls) {
        // A continuation page returns the same `richItemRenderer` entries as
        // the rich grid it came from. Handling only sections here would keep
        // the token and drop every entry, so later pages would look empty.
        final lockup = _lockupFromJson(rawItem);
        if (lockup != null) {
          items.add(lockup);
          continue;
        }
        final continuation = _continuationTokenFromJson(
          _map(rawItem['continuationItemRenderer']),
        );
        if (continuation != null) continuationToken ??= continuation;
      }
    }

    return NetworkYouTubeBrowseResponse(
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(
              _map(json['responseContext'])!,
            ),
      header: header,
      tabs: List.unmodifiable(tabs),
      items: List.unmodifiable(items),
      continuationToken: continuationToken,
    );
  }

  final NetworkYouTubeResponseContext? responseContext;
  final NetworkYouTubeChannelHeader? header;
  final List<NetworkYouTubeTab> tabs;
  final List<NetworkYouTubeLockupItem> items;
  final String? continuationToken;
}

/// Walks a `richGridRenderer`, collecting every lockup entry and reporting the
/// first continuation token it finds.
void _collectRichGrid(
  Map<String, dynamic> richGrid,
  List<NetworkYouTubeLockupItem> items,
  void Function(String token) onToken,
) {
  for (final rawGridItem in _list(richGrid['contents']).map(_map).nonNulls) {
    final lockup = _lockupFromJson(rawGridItem);
    if (lockup != null) {
      items.add(lockup);
      continue;
    }
    final token = _continuationTokenFromJson(
      _map(rawGridItem['continuationItemRenderer']),
    );
    if (token != null) onToken(token);
  }
}

/// Unwraps `richItemRenderer.content` into a lockup item, or returns null when
/// the entry is not a lockup.
NetworkYouTubeLockupItem? _lockupFromJson(Map<String, dynamic> json) {
  // `richItemRenderer.content` wraps the entry one level deeper: it holds a
  // single `lockupViewModel` key, so it needs unwrapping before it is a lockup.
  final richItem = _map(json['richItemRenderer']);
  final content = _map(richItem?['content']);
  final lockup =
      _map(content?['lockupViewModel']) ??
      _map(json['lockupViewModel']) ??
      content;
  if (lockup == null) return null;
  try {
    return NetworkYouTubeLockupItem.fromJson(lockup);
  } on FormatException {
    // A lockup without a title carries nothing a caller can display.
    return null;
  }
}

String? _continuationTokenFromJson(Map<String, dynamic>? renderer) {
  if (renderer == null) return null;
  return _string(
    _map(renderer['continuationEndpoint'])?['continuationCommand'] == null
        ? null
        : _map(
            _map(renderer['continuationEndpoint'])?['continuationCommand'],
          )?['token'],
  );
}

/// Mirrors `network_youtube_search.dart`'s check of the top-level `error`
/// object. The helper there is library-private, so browse needs its own.
void _throwInnerTubeError(Map<String, dynamic> json) {
  final error = _map(json['error']);
  if (error == null) return;
  throw YpiInnerTubeException(
    code: error['code'] is int ? error['code'] as int : null,
    continuation: _string(error['continuation']),
    reason: _string(error['message']) ?? _string(error['status']),
  );
}

/// Rejects a response that reports failure through `alerts` instead of the
/// top-level `error` field.
///
/// YouTube answers a missing channel with HTTP 200, `code` absent and an
/// `alerts[].alertRenderer` of type `ERROR` ("此频道不存在。"). Without this
/// check such a response parses into an empty channel and the caller cannot
/// tell a failed lookup from a channel with no videos.
void _throwAlertError(Map<String, dynamic> json) {
  for (final rawAlert in _list(json['alerts']).map(_map).nonNulls) {
    final alert = _map(rawAlert['alertRenderer']);
    if (alert == null) continue;
    final type = _string(alert['type']);
    if (type == null || type == 'OK') continue;
    throw YpiInnerTubeException(
      code: null,
      continuation: null,
      reason:
          _string(_map(alert['text'])?['simpleText']) ??
          _string(alert['text']) ??
          'InnerTube alert: $type',
    );
  }
}

/// Reads the thumbnail of a channel video entry.
///
/// A channel grid stores it at `contentImage.thumbnailViewModel.image.sources`.
/// This is a different path from the one
/// `network_youtube_search.dart` reads for a lockup, which goes through
/// `collectionThumbnailViewModel.primaryThumbnail`.
NetworkYouTubeThumbnail? _lockupThumbnail(Object? contentImage) {
  final sources = _list(
    _map(_map(_map(contentImage)?['thumbnailViewModel'])?['image'])?['sources'],
  );
  if (sources.isEmpty) return null;
  return NetworkYouTubeThumbnail(
    thumbnails: List.unmodifiable(
      sources
          .map(_map)
          .nonNulls
          .map(
            (source) => NetworkYouTubeThumbnailSize(
              url: _string(source['url']),
              width: source['width'] is int ? source['width'] as int : null,
              height: source['height'] is int ? source['height'] as int : null,
            ),
          )
          .toList(growable: false),
    ),
  );
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
