import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

final class NetworkYouTubeVideoOwner {
  const NetworkYouTubeVideoOwner({
    required this.channelId,
    this.title,
    this.avatar,
    this.subscriberCountText,
  });

  factory NetworkYouTubeVideoOwner.fromJson(Map<String, dynamic> json) {
    final videoOwner = _map(json['videoOwnerRenderer']);
    if (videoOwner == null) {
      throw const FormatException('json has no videoOwnerRenderer');
    }

    final navigationEndpoint = _map(videoOwner['navigationEndpoint']);
    final browseEndpoint = _map(navigationEndpoint?['browseEndpoint']);
    final channelId = _string(browseEndpoint?['browseId']);
    if (channelId == null || channelId.isEmpty) {
      throw const FormatException('videoOwnerRenderer missing channelId');
    }

    final titleObj = _map(videoOwner['title']);
    final titleRuns = _list(titleObj?['runs']);
    final title = titleRuns.isNotEmpty
        ? _string(_map(titleRuns.first)?['text'])
        : null;

    final avatar = NetworkYouTubeThumbnail.fromJson(videoOwner['thumbnail']);
    final subCount = NetworkYouTubeText.fromJson(
      videoOwner['subscriberCountText'],
    );

    return NetworkYouTubeVideoOwner(
      channelId: channelId,
      title: title,
      avatar: avatar,
      subscriberCountText: subCount.value,
    );
  }

  final String channelId;
  final String? title;
  final NetworkYouTubeThumbnail? avatar;
  final String? subscriberCountText;
}

final class NetworkYouTubeWatchNextResponse {
  const NetworkYouTubeWatchNextResponse({
    required this.videoId,
    this.responseContext,
    this.title,
    this.viewCountText,
    this.publishedTimeText,
    this.owner,
    this.description,
    this.commentsContinuationToken,
  });

  factory NetworkYouTubeWatchNextResponse.fromJson(
    Map<String, dynamic> json, {
    String? requestedVideoId,
  }) {
    _throwInnerTubeError(json);
    _throwAlertError(json);

    final contentsMap = _map(json['contents']);
    final twoCol = _map(contentsMap?['twoColumnWatchNextResults']);
    final results = _map(twoCol?['results']);
    final innerResults = _map(results?['results']);
    final primaryContents = _list(innerResults?['contents']);
    final contentsList = primaryContents.isNotEmpty
        ? primaryContents
        : _continuationItems(json);

    String? videoId = requestedVideoId;
    String? title;
    String? viewCountText;
    String? publishedTimeText;
    NetworkYouTubeVideoOwner? owner;
    String? description;
    String? commentsContinuationToken;

    for (final rawItem in contentsList.map(_map).nonNulls) {
      final primary = _map(rawItem['videoPrimaryInfoRenderer']);
      if (primary != null) {
        final titleText = NetworkYouTubeText.fromJson(primary['title']);
        title ??= titleText.value;

        final viewCountObj = _map(primary['viewCount']);
        final videoViewCount = _map(viewCountObj?['videoViewCountRenderer']);
        final simpleViewCount = NetworkYouTubeText.fromJson(
          videoViewCount?['viewCount'],
        );
        viewCountText ??= simpleViewCount.value;

        final relativeDate = NetworkYouTubeText.fromJson(
          primary['relativeDateText'],
        );
        publishedTimeText ??= relativeDate.value;
      }

      final secondary = _map(rawItem['videoSecondaryInfoRenderer']);
      if (secondary != null) {
        final ownerMap = _map(secondary['owner']);
        if (ownerMap != null) {
          try {
            owner ??= NetworkYouTubeVideoOwner.fromJson(ownerMap);
          } on FormatException {
            // Ignore unparseable owner
          }
        }

        final descText =
            NetworkYouTubeText.fromJson(secondary['description']).value ??
            NetworkYouTubeText.fromJson(secondary['attributedDescription'])
                .value ??
            _string(_map(secondary['attributedDescription'])?['content']);
        description ??= descText;
      }

      final itemSection = _map(rawItem['itemSectionRenderer']);
      if (itemSection != null) {
        final targetId =
            _string(itemSection['targetId']) ??
            _string(itemSection['sectionId']);
        if (targetId == 'comments-section' ||
            commentsContinuationToken == null) {
          for (final rawContent in _list(
            itemSection['contents'],
          ).map(_map).nonNulls) {
            final contItem = _map(rawContent['continuationItemRenderer']);
            if (contItem != null) {
              final endpoint = _map(contItem['continuationEndpoint']);
              final command = _map(endpoint?['continuationCommand']);
              final token = _string(command?['token']);
              if (token != null) {
                commentsContinuationToken ??= token;
                break;
              }
            }
          }
        }
      }
    }

    final currentVideoEndpoint = _map(json['currentVideoEndpoint']);
    final watchEndpoint = _map(currentVideoEndpoint?['watchEndpoint']);
    final endpointVideoId = _string(watchEndpoint?['videoId']);
    if (endpointVideoId != null) {
      videoId = endpointVideoId;
    }

    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('WatchNext response is missing videoId');
    }
    if (title == null || title.isEmpty) {
      throw const FormatException(
        'WatchNext response has no videoPrimaryInfoRenderer title',
      );
    }

    return NetworkYouTubeWatchNextResponse(
      videoId: videoId,
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(
              _map(json['responseContext'])!,
            ),
      title: title,
      viewCountText: viewCountText,
      publishedTimeText: publishedTimeText,
      owner: owner,
      description: description,
      commentsContinuationToken: commentsContinuationToken,
    );
  }

  final String videoId;
  final NetworkYouTubeResponseContext? responseContext;
  final String? title;
  final String? viewCountText;
  final String? publishedTimeText;
  final NetworkYouTubeVideoOwner? owner;
  final String? description;
  final String? commentsContinuationToken;
}

List<dynamic> _continuationItems(Map<String, dynamic> json) {
  for (final rawAction in _list(
    json['onResponseReceivedActions'],
  ).map(_map).nonNulls) {
    for (final key in const [
      'appendContinuationItemsAction',
      'reloadContinuationItemsCommand',
    ]) {
      final items = _list(_map(rawAction[key])?['continuationItems']);
      if (items.isNotEmpty) return items;
    }
  }
  return const [];
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
          NetworkYouTubeText.fromJson(alert['text']).value ??
          _string(alert['text']) ??
          'InnerTube alert: $type',
    );
  }
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

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
