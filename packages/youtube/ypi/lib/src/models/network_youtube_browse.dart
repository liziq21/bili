import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Channel header data returned in InnerTube browse response.
final class NetworkYouTubeChannelHeader {
  const NetworkYouTubeChannelHeader({
    required this.channelId,
    this.title,
    this.avatar,
    this.banner,
    this.subscriberCountText,
  });

  factory NetworkYouTubeChannelHeader.fromJson(Map<String, dynamic> json) {
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
    final viewModel = _map(pageHeader?['pageHeaderViewModel']);
    if (viewModel != null) {
      final titleVM = _map(viewModel['title']);
      final headerTitleVM = _map(titleVM?['headerTitleViewModel']);
      final titleText = _string(_map(headerTitleVM?['title'])?['content']);

      final imageVM = _map(viewModel['image']);
      final sources = _list(
        _map(
          _map(
            _map(imageVM?['decoratedAvatarViewModel'])?['avatar'],
          )?['avatarViewModel'],
        )?['image']?['sources'],
      );

      return NetworkYouTubeChannelHeader(
        channelId: _string(viewModel['channelId']) ?? '',
        title: titleText,
        avatar: sources.isEmpty
            ? null
            : NetworkYouTubeThumbnail(
                thumbnails: List.unmodifiable(
                  sources
                      .map(_map)
                      .nonNulls
                      .map(
                        (s) => NetworkYouTubeThumbnailSize(
                          url: _string(s['url']),
                          width: _integer(s['width']),
                          height: _integer(s['height']),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
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

/// Tab entry inside browse results.
final class NetworkYouTubeTab {
  const NetworkYouTubeTab({this.title, this.selected = false, this.content});

  factory NetworkYouTubeTab.fromJson(Map<String, dynamic> json) {
    final tab = _map(json['tabRenderer']);
    if (tab == null) {
      return const NetworkYouTubeTab();
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

/// Response returned by YouTube InnerTube `/youtubei/v1/browse` endpoint.
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

    NetworkYouTubeChannelHeader? header;
    final headerMap = _map(json['header']);
    if (headerMap != null) {
      try {
        header = NetworkYouTubeChannelHeader.fromJson(headerMap);
      } on FormatException {
        header = null;
      }
    }

    final tabs = <NetworkYouTubeTab>[];
    final items = <NetworkYouTubeSearchItem>[];
    String? continuationToken;

    final contentsMap = _map(json['contents']);
    if (contentsMap != null) {
      final twoCol = _map(contentsMap['twoColumnBrowseResultsRenderer']);
      final singleCol = _map(contentsMap['singleColumnBrowseResultsRenderer']);
      final activeCol = twoCol ?? singleCol;

      final rawTabs = _list(activeCol?['tabs']);
      for (final rawTab in rawTabs.map(_map).nonNulls) {
        tabs.add(NetworkYouTubeTab.fromJson(rawTab));
      }

      // Collect items from primary contents or rich grid if available
      for (final tab in tabs) {
        final tabContent = tab.content;
        if (tabContent == null) continue;

        final richGrid = _map(tabContent['richGridRenderer']);
        if (richGrid != null) {
          final gridContents = _list(richGrid['contents']);
          for (final rawGridItem in gridContents.map(_map).nonNulls) {
            final richItem = _map(rawGridItem['richItemRenderer']);
            if (richItem != null) {
              final content = _map(richItem['content']);
              if (content != null) {
                final item = _searchItemFromJson(content);
                if (item != null) {
                  items.add(item);
                }
              }
            }
            final continuation = _map(rawGridItem['continuationItemRenderer']);
            if (continuation != null) {
              try {
                final cont = NetworkYouTubeContinuationItemRenderer.fromJson(
                  continuation,
                );
                continuationToken ??= cont.token;
              } on FormatException {
                // Ignore invalid continuation item
              }
            }
          }
        }

        final sectionList = _map(tabContent['sectionListRenderer']);
        if (sectionList != null) {
          final sectionListRenderer =
              NetworkYouTubeSectionListRenderer.fromJson(sectionList);
          for (final section in sectionListRenderer.contents) {
            if (section is NetworkYouTubeItemSectionRenderer) {
              items.addAll(section.contents);
            } else if (section is NetworkYouTubeContinuationSection) {
              continuationToken ??= section.renderer.token;
            }
          }
        }
      }
    }

    // Process continuation response commands if any
    final rawActions = _list(json['onResponseReceivedActions']);
    for (final rawAction in rawActions.map(_map).nonNulls) {
      final appendAction = _map(rawAction['appendContinuationItemsAction']);
      if (appendAction != null) {
        final rawItems = _list(appendAction['continuationItems']);
        for (final rawItem in rawItems.map(_map).nonNulls) {
          final section = _searchSectionFromJson(rawItem);
          if (section is NetworkYouTubeItemSectionRenderer) {
            items.addAll(section.contents);
          } else if (section is NetworkYouTubeContinuationSection) {
            continuationToken ??= section.renderer.token;
          }
        }
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
  final List<NetworkYouTubeSearchItem> items;
  final String? continuationToken;
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

int? _integer(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

NetworkYouTubeSearchItem? _searchItemFromJson(Map<String, dynamic> json) {
  final video = _map(json['videoRenderer']);
  if (video != null) {
    try {
      return NetworkYouTubeVideoSearchItem(
        NetworkYouTubeVideoRenderer.fromJson(video),
      );
    } on FormatException {
      return null;
    }
  }

  final channel = _map(json['channelRenderer']);
  if (channel != null) {
    try {
      return NetworkYouTubeChannelSearchItem(
        NetworkYouTubeChannelRenderer.fromJson(channel),
      );
    } on FormatException {
      return null;
    }
  }

  final lockup = _map(json['lockupViewModel']);
  if (lockup != null) {
    try {
      return NetworkYouTubePlaylistSearchItem(
        NetworkYouTubePlaylistLockup.fromJson(lockup),
      );
    } on FormatException {
      return null;
    }
  }

  final continuation = _map(json['continuationItemRenderer']);
  if (continuation != null) {
    try {
      return NetworkYouTubeContinuationSearchItem(
        NetworkYouTubeContinuationItemRenderer.fromJson(continuation),
      );
    } on FormatException {
      return null;
    }
  }

  return null;
}

NetworkYouTubeSearchSection? _searchSectionFromJson(Map<String, dynamic> json) {
  final itemSection = _map(json['itemSectionRenderer']);
  if (itemSection != null) {
    return NetworkYouTubeItemSectionRenderer.fromJson(json);
  }

  final continuation = _map(json['continuationItemRenderer']);
  if (continuation != null) {
    try {
      return NetworkYouTubeContinuationSection(
        NetworkYouTubeContinuationItemRenderer.fromJson(continuation),
      );
    } on FormatException {
      return null;
    }
  }

  return null;
}

void _throwInnerTubeError(Map<String, dynamic> json) {
  final error = _map(json['error']);
  if (error == null) {
    return;
  }
  throw YpiInnerTubeException(
    code: _integer(error['code']),
    continuation: _string(error['continuation']),
    reason: _string(error['message']) ?? _string(error['status']),
  );
}

extension _NonNulls<T> on Iterable<T?> {
  Iterable<T> get nonNulls => where((value) => value != null).cast<T>();
}
