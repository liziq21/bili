import 'package:meta/meta.dart';

import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

@immutable
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

@immutable
final class NetworkYouTubeWatchNextResponse {
  const NetworkYouTubeWatchNextResponse({
    required this.videoId,
    this.responseContext,
    this.title,
    this.viewCountText,
    this.publishedTimeText,
    this.owner,
    this.description,
  });

  factory NetworkYouTubeWatchNextResponse.fromJson(
    Map<String, dynamic> json, {
    String? requestedVideoId,
  }) {
    _throwInnerTubeError(json);

    final contentsMap = _map(json['contents']);
    final twoCol = _map(contentsMap?['twoColumnWatchNextResults']);
    final results = _map(twoCol?['results']);
    final innerResults = _map(results?['results']);
    final contentsList = _list(innerResults?['contents']);

    String? videoId = requestedVideoId;
    String? title;
    String? viewCountText;
    String? publishedTimeText;
    NetworkYouTubeVideoOwner? owner;
    String? description;

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
                .value;
        description ??= descText;
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
    );
  }

  final String videoId;
  final NetworkYouTubeResponseContext? responseContext;
  final String? title;
  final String? viewCountText;
  final String? publishedTimeText;
  final NetworkYouTubeVideoOwner? owner;
  final String? description;
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
