import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Playlist header returned by an InnerTube `/youtubei/v1/browse` response.
///
/// YouTube serves playlist headers either as `playlistHeaderRenderer` (classic)
/// or through a combination of `pageHeaderRenderer` / `sidebar.playlistSidebarRenderer`
/// and `metadata.playlistMetadataRenderer` (modern).
final class NetworkYouTubePlaylistHeader {
  const NetworkYouTubePlaylistHeader({
    required this.playlistId,
    this.title,
    this.description,
    this.owner,
    this.videoCountText,
    this.viewCountText,
    this.thumbnail,
  });

  factory NetworkYouTubePlaylistHeader.fromJson(
    Map<String, dynamic> json, {
    String? requestedPlaylistId,
    Map<String, dynamic>? sidebar,
    Map<String, dynamic>? metadata,
  }) {
    final playlistHeader = _map(json['playlistHeaderRenderer']);
    if (playlistHeader != null) {
      final playlistId =
          _string(playlistHeader['playlistId']) ??
          _stripVlPrefix(requestedPlaylistId);
      if (playlistId == null || playlistId.isEmpty) {
        throw const FormatException(
          'playlistHeaderRenderer is missing playlistId',
        );
      }

      final title =
          _string(_map(playlistHeader['title'])?['simpleText']) ??
          NetworkYouTubeText.fromJson(playlistHeader['title']).value;

      final description =
          _string(_map(playlistHeader['descriptionText'])?['simpleText']) ??
          NetworkYouTubeText.fromJson(playlistHeader['descriptionText']).value;

      final numVideosText =
          NetworkYouTubeText.fromJson(playlistHeader['numVideosText']).value ??
          _string(_map(playlistHeader['numVideosText'])?['simpleText']);

      final viewCountText =
          _string(_map(playlistHeader['viewCountText'])?['simpleText']) ??
          NetworkYouTubeText.fromJson(playlistHeader['viewCountText']).value;

      final owner = NetworkYouTubeOwner.fromJson(playlistHeader['ownerText']);

      final thumbnail = _extractThumbnail(playlistHeader, sidebar);

      return NetworkYouTubePlaylistHeader(
        playlistId: playlistId,
        title: title,
        description: description,
        owner: owner,
        videoCountText: numVideosText,
        viewCountText: viewCountText,
        thumbnail: thumbnail,
      );
    }

    // Modern fallback: pageHeaderRenderer or sidebar / metadata
    final pageHeader = _map(json['pageHeaderRenderer']);
    final sidebarRenderer = _map(sidebar?['playlistSidebarRenderer']);
    final metadataRenderer = _map(metadata?['playlistMetadataRenderer']);

    final playlistId = _stripVlPrefix(requestedPlaylistId);
    if (playlistId == null || playlistId.isEmpty) {
      throw const FormatException(
        'Header json does not contain recognized playlist header renderer and no playlistId provided',
      );
    }

    String? title;
    String? description;
    String? videoCountText;
    String? viewCountText;
    NetworkYouTubeOwner? owner;
    NetworkYouTubeThumbnail? thumbnail;

    if (sidebarRenderer != null) {
      final items = _list(sidebarRenderer['items']);
      for (final rawItem in items.map(_map).nonNulls) {
        final primary = _map(rawItem['playlistSidebarPrimaryInfoRenderer']);
        if (primary != null) {
          title ??= NetworkYouTubeText.fromJson(primary['title']).value;
          final stats = _list(primary['stats']);
          if (stats.isNotEmpty) {
            videoCountText ??= NetworkYouTubeText.fromJson(stats.first).value;
          }
          if (stats.length > 1) {
            viewCountText ??= NetworkYouTubeText.fromJson(stats[1]).value;
          }
          final thumbRenderer = _map(primary['thumbnailRenderer']);
          final videoThumb = _map(
            thumbRenderer?['playlistVideoThumbnailRenderer'],
          );
          final customThumb = _map(
            thumbRenderer?['playlistCustomThumbnailRenderer'],
          );
          final activeThumb = videoThumb ?? customThumb;
          if (activeThumb != null) {
            thumbnail ??= NetworkYouTubeThumbnail.fromJson(
              activeThumb['thumbnail'],
            );
          }
        }

        final secondary = _map(rawItem['playlistSidebarSecondaryInfoRenderer']);
        if (secondary != null) {
          final videoOwner = _map(
            _map(secondary['videoOwner'])?['videoOwnerRenderer'],
          );
          if (videoOwner != null) {
            final ownerText = NetworkYouTubeText.fromJson(videoOwner['title']);
            final browseEndpoint = _map(
              _map(videoOwner['navigationEndpoint'])?['browseEndpoint'],
            );
            owner ??= NetworkYouTubeOwner(
              text: ownerText,
              browseId: _string(browseEndpoint?['browseId']),
            );
          }
        }
      }
    }

    if (pageHeader != null) {
      title ??= _string(pageHeader['pageTitle']);
    }

    if (metadataRenderer != null) {
      title ??= _string(metadataRenderer['title']);
      description ??= _string(metadataRenderer['description']);
    }

    return NetworkYouTubePlaylistHeader(
      playlistId: playlistId,
      title: title,
      description: description,
      owner: owner,
      videoCountText: videoCountText,
      viewCountText: viewCountText,
      thumbnail: thumbnail,
    );
  }

  final String playlistId;
  final String? title;
  final String? description;
  final NetworkYouTubeOwner? owner;
  final String? videoCountText;
  final String? viewCountText;
  final NetworkYouTubeThumbnail? thumbnail;

  static String? _stripVlPrefix(String? id) {
    if (id == null) return null;
    return id.startsWith('VL') ? id.substring(2) : id;
  }

  static NetworkYouTubeThumbnail? _extractThumbnail(
    Map<String, dynamic> playlistHeader,
    Map<String, dynamic>? sidebar,
  ) {
    // Check playlistHeaderBanner
    final banner = _map(playlistHeader['playlistHeaderBanner']);
    final bannerThumb = _map(banner?['heroImage']);
    if (bannerThumb != null) {
      final sources = _list(
        _map(
          _map(bannerThumb['contentPreviewImageViewModel'])?['image'],
        )?['sources'],
      );
      if (sources.isNotEmpty) {
        return _sourcesToThumbnail(sources);
      }
    }

    // Check sidebar
    final sidebarRenderer = _map(sidebar?['playlistSidebarRenderer']);
    if (sidebarRenderer != null) {
      final items = _list(sidebarRenderer['items']);
      for (final rawItem in items.map(_map).nonNulls) {
        final primary = _map(rawItem['playlistSidebarPrimaryInfoRenderer']);
        if (primary != null) {
          final thumbRenderer = _map(primary['thumbnailRenderer']);
          final videoThumb = _map(
            thumbRenderer?['playlistVideoThumbnailRenderer'],
          );
          final customThumb = _map(
            thumbRenderer?['playlistCustomThumbnailRenderer'],
          );
          final activeThumb = videoThumb ?? customThumb;
          if (activeThumb != null) {
            return NetworkYouTubeThumbnail.fromJson(activeThumb['thumbnail']);
          }
        }
      }
    }

    return null;
  }

  static NetworkYouTubeThumbnail _sourcesToThumbnail(List<dynamic> sources) {
    return NetworkYouTubeThumbnail(
      thumbnails: List.unmodifiable(
        sources
            .map(_map)
            .nonNulls
            .map(
              (source) => NetworkYouTubeThumbnailSize(
                url: _string(source['url']),
                width: source['width'] is int ? source['width'] as int : null,
                height:
                    source['height'] is int ? source['height'] as int : null,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

/// A video item within a playlist.
///
/// Supports both modern `lockupViewModel` and traditional `playlistVideoRenderer`.
final class NetworkYouTubePlaylistVideoItem {
  const NetworkYouTubePlaylistVideoItem({
    required this.videoId,
    this.title,
    this.thumbnail,
    this.author,
    this.lengthText,
    this.metadataRows = const [],
  });

  factory NetworkYouTubePlaylistVideoItem.fromLockupViewModel(
    Map<String, dynamic> json,
  ) {
    final videoId = _string(json['contentId']);
    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('lockupViewModel is missing a contentId');
    }

    final metadataViewModel = _map(
      _map(json['metadata'])?['lockupMetadataViewModel'],
    );
    final title = _string(_map(metadataViewModel?['title'])?['content']);
    if (title == null || title.isEmpty) {
      throw const FormatException('lockupViewModel is missing a title');
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

    // Extract lengthText from overlay badge if present
    String? lengthText;
    final overlays = _list(
      _map(_map(json['contentImage'])?['thumbnailViewModel'])?['overlays'],
    );
    for (final overlay in overlays.map(_map).nonNulls) {
      final bottomOverlay = _map(overlay['thumbnailBottomOverlayViewModel']);
      if (bottomOverlay != null) {
        for (final badge in _list(bottomOverlay['badges']).map(_map).nonNulls) {
          final text = _string(
            _map(badge['thumbnailBadgeViewModel'])?['text'],
          );
          if (text != null && text.isNotEmpty) {
            lengthText = text;
            break;
          }
        }
      }
      if (lengthText != null) break;
    }

    return NetworkYouTubePlaylistVideoItem(
      videoId: videoId,
      title: title,
      thumbnail: _lockupThumbnail(json['contentImage']),
      lengthText: lengthText,
      metadataRows: List.unmodifiable(rows),
    );
  }

  factory NetworkYouTubePlaylistVideoItem.fromPlaylistVideoRenderer(
    Map<String, dynamic> json,
  ) {
    final videoId = _string(json['videoId']);
    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('playlistVideoRenderer is missing videoId');
    }

    final title = NetworkYouTubeText.fromJson(json['title']).value;
    final author = NetworkYouTubeOwner.fromJson(json['shortBylineText']);
    final lengthText = NetworkYouTubeText.fromJson(json['lengthText']).value;
    final thumbnail = NetworkYouTubeThumbnail.fromJson(json['thumbnail']);

    final rows = <String>[];
    final videoInfo = NetworkYouTubeText.fromJson(json['videoInfo']).value;
    if (videoInfo != null && videoInfo.isNotEmpty) {
      rows.add(videoInfo);
    }

    return NetworkYouTubePlaylistVideoItem(
      videoId: videoId,
      title: title,
      thumbnail: thumbnail,
      author: author,
      lengthText: lengthText,
      metadataRows: List.unmodifiable(rows),
    );
  }

  final String videoId;
  final String? title;
  final NetworkYouTubeThumbnail? thumbnail;
  final NetworkYouTubeOwner? author;
  final String? lengthText;
  final List<String> metadataRows;
}

/// Response returned by YouTube InnerTube `/youtubei/v1/browse` when browsing a playlist.
final class NetworkYouTubePlaylistBrowseResponse {
  const NetworkYouTubePlaylistBrowseResponse({
    this.responseContext,
    this.header,
    this.items = const [],
    this.continuationToken,
  });

  factory NetworkYouTubePlaylistBrowseResponse.fromJson(
    Map<String, dynamic> json, {
    String? requestedPlaylistId,
  }) {
    _throwInnerTubeError(json);
    _throwAlertError(json);

    NetworkYouTubePlaylistHeader? header;
    final headerMap = _map(json['header']);
    final sidebarMap = _map(json['sidebar']);
    final metadataMap = _map(json['metadata']);

    if (headerMap != null || sidebarMap != null || metadataMap != null) {
      try {
        header = NetworkYouTubePlaylistHeader.fromJson(
          headerMap ?? const {},
          requestedPlaylistId: requestedPlaylistId,
          sidebar: sidebarMap,
          metadata: metadataMap,
        );
      } on FormatException {
        header = null;
      }
    }

    final items = <NetworkYouTubePlaylistVideoItem>[];
    String? continuationToken;

    final contentsMap = _map(json['contents']);
    if (contentsMap != null) {
      final twoCol = _map(contentsMap['twoColumnBrowseResultsRenderer']);
      final singleCol = _map(contentsMap['singleColumnBrowseResultsRenderer']);
      final activeCol = twoCol ?? singleCol;

      for (final rawTab in _list(activeCol?['tabs']).map(_map).nonNulls) {
        final tabRenderer = _map(rawTab['tabRenderer']);
        final tabContent = _map(tabRenderer?['content']);
        if (tabContent == null) continue;

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
                // Could be playlistVideoListRenderer wrapping items
                final videoList = _map(rawEntry['playlistVideoListRenderer']);
                if (videoList != null) {
                  for (final rawVideo in _list(
                    videoList['contents'],
                  ).map(_map).nonNulls) {
                    final item = _videoItemFromJson(rawVideo);
                    if (item != null) {
                      items.add(item);
                      continue;
                    }
                    final token = _continuationTokenFromJson(rawVideo);
                    if (token != null) continuationToken ??= token;
                  }
                  continue;
                }

                final item = _videoItemFromJson(rawEntry);
                if (item != null) {
                  items.add(item);
                  continue;
                }
                final token = _continuationTokenFromJson(rawEntry);
                if (token != null) continuationToken ??= token;
              }
              continue;
            }

            final token = _continuationTokenFromJson(rawSection);
            if (token != null) continuationToken ??= token;
          }
        }
      }
    }

    // Check continuation actions
    for (final rawAction in _list(
      json['onResponseReceivedActions'],
    ).map(_map).nonNulls) {
      final appendAction = _map(rawAction['appendContinuationItemsAction']);
      if (appendAction == null) continue;
      for (final rawItem in _list(
        appendAction['continuationItems'],
      ).map(_map).nonNulls) {
        final itemSection = _map(rawItem['itemSectionRenderer']);
        if (itemSection != null) {
          for (final rawEntry in _list(
            itemSection['contents'],
          ).map(_map).nonNulls) {
            final item = _videoItemFromJson(rawEntry);
            if (item != null) {
              items.add(item);
              continue;
            }
            final token = _continuationTokenFromJson(rawEntry);
            if (token != null) continuationToken ??= token;
          }
          continue;
        }

        final item = _videoItemFromJson(rawItem);
        if (item != null) {
          items.add(item);
          continue;
        }
        final token = _continuationTokenFromJson(rawItem);
        if (token != null) continuationToken ??= token;
      }
    }

    return NetworkYouTubePlaylistBrowseResponse(
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(
              _map(json['responseContext'])!,
            ),
      header: header,
      items: List.unmodifiable(items),
      continuationToken: continuationToken,
    );
  }

  final NetworkYouTubeResponseContext? responseContext;
  final NetworkYouTubePlaylistHeader? header;
  final List<NetworkYouTubePlaylistVideoItem> items;
  final String? continuationToken;
}

NetworkYouTubePlaylistVideoItem? _videoItemFromJson(Map<String, dynamic> json) {
  final richItem = _map(json['richItemRenderer']);
  final content = _map(richItem?['content']);
  final lockup =
      _map(content?['lockupViewModel']) ??
      _map(json['lockupViewModel']) ??
      (json['contentType'] != null && json['contentId'] != null ? json : null);
  if (lockup != null) {
    try {
      return NetworkYouTubePlaylistVideoItem.fromLockupViewModel(lockup);
    } on FormatException {
      return null;
    }
  }

  final pvr = _map(json['playlistVideoRenderer']);
  if (pvr != null) {
    try {
      return NetworkYouTubePlaylistVideoItem.fromPlaylistVideoRenderer(pvr);
    } on FormatException {
      return null;
    }
  }

  return null;
}

String? _continuationTokenFromJson(Map<String, dynamic>? renderer) {
  if (renderer == null) return null;

  // 1. continuationItemRenderer
  final contItem = _map(renderer['continuationItemRenderer']) ?? renderer;
  final endpoint = _map(contItem['continuationEndpoint']);
  final token1 = _string(
    _map(endpoint?['continuationCommand'])?['token'],
  );
  if (token1 != null) return token1;

  // 2. continuationItemViewModel
  final contViewModel =
      _map(renderer['continuationItemViewModel']) ?? renderer;
  final contCmd = _map(contViewModel['continuationCommand']);
  final token2 =
      _string(_map(contCmd?['continuationCommand'])?['token']) ??
      _string(
        _map(
          _map(contCmd?['innertubeCommand'])?['continuationCommand'],
        )?['token'],
      );
  if (token2 != null) return token2;

  return null;
}

void _throwInnerTubeError(Map<String, dynamic> json) {
  final error = _map(json['error']);
  if (error == null) return;
  throw YpiInnerTubeException(
    code: error['code'] is int ? error['code'] as int : null,
    continuation: _string(error['continuation']),
    reason: _string(error['message']) ?? _string(error['status']),
  );
}

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
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
