import 'package:meta/meta.dart';

import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Playability status returned in a YouTube `/youtubei/v1/player` response.
@immutable
final class NetworkYouTubePlayabilityStatus {
  const NetworkYouTubePlayabilityStatus({required this.status, this.reason});

  factory NetworkYouTubePlayabilityStatus.fromJson(Map<String, dynamic> json) {
    return NetworkYouTubePlayabilityStatus(
      status: _string(json['status']) ?? 'UNKNOWN',
      reason:
          _string(json['reason']) ??
          NetworkYouTubeText.fromJson(
            _map(
              _map(
                _map(json['errorScreen'])?['playerErrorMessageRenderer'],
              )?['reason'],
            ),
          ).value,
    );
  }

  final String status;
  final String? reason;
}

/// Video details returned in a YouTube `/youtubei/v1/player` response.
@immutable
final class NetworkYouTubePlayerVideoDetails {
  const NetworkYouTubePlayerVideoDetails({
    required this.videoId,
    this.title,
    this.author,
    this.channelId,
    this.lengthSeconds,
    this.viewCount,
    this.shortDescription,
    this.thumbnail,
    this.isLiveContent = false,
    this.keywords = const [],
  });

  factory NetworkYouTubePlayerVideoDetails.fromJson(Map<String, dynamic> json) {
    final videoId = _string(json['videoId']);
    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('videoDetails is missing videoId');
    }

    final keywords = _list(json['keywords'])
        .map((e) => _string(e))
        .nonNulls
        .toList(growable: false);

    return NetworkYouTubePlayerVideoDetails(
      videoId: videoId,
      title: _string(json['title']),
      author: _string(json['author']),
      channelId: _string(json['channelId']),
      lengthSeconds: _string(json['lengthSeconds']),
      viewCount: _string(json['viewCount']),
      shortDescription: _string(json['shortDescription']),
      thumbnail: json['thumbnail'] == null
          ? null
          : NetworkYouTubeThumbnail.fromJson(json['thumbnail']),
      isLiveContent: json['isLiveContent'] == true,
      keywords: List.unmodifiable(keywords),
    );
  }

  final String videoId;
  final String? title;
  final String? author;
  final String? channelId;
  final String? lengthSeconds;
  final String? viewCount;
  final String? shortDescription;
  final NetworkYouTubeThumbnail? thumbnail;
  final bool isLiveContent;
  final List<String> keywords;
}

/// Player microformat info returned in a YouTube `/youtubei/v1/player` response.
@immutable
final class NetworkYouTubePlayerMicroformat {
  const NetworkYouTubePlayerMicroformat({
    this.publishDate,
    this.uploadDate,
    this.category,
    this.isUnlisted = false,
  });

  factory NetworkYouTubePlayerMicroformat.fromJson(Map<String, dynamic> json) {
    final renderer = _map(json['playerMicroformatRenderer']) ?? json;
    return NetworkYouTubePlayerMicroformat(
      publishDate: _string(renderer['publishDate']),
      uploadDate: _string(renderer['uploadDate']),
      category: _string(renderer['category']),
      isUnlisted: renderer['isUnlisted'] == true,
    );
  }

  final String? publishDate;
  final String? uploadDate;
  final String? category;
  final bool isUnlisted;
}

/// Single video stream format item inside `streamingData`.
@immutable
final class NetworkYouTubeStreamFormat {
  const NetworkYouTubeStreamFormat({
    required this.itag,
    this.url,
    this.mimeType,
    this.bitrate,
    this.width,
    this.height,
    this.qualityLabel,
    this.contentLength,
    this.audioQuality,
    this.audioSampleRate,
  });

  factory NetworkYouTubeStreamFormat.fromJson(Map<String, dynamic> json) {
    final itag = json['itag'] is int
        ? json['itag'] as int
        : int.tryParse('${json['itag']}') ?? 0;
    return NetworkYouTubeStreamFormat(
      itag: itag,
      url: _string(json['url']),
      mimeType: _string(json['mimeType']),
      bitrate: json['bitrate'] is int
          ? json['bitrate'] as int
          : int.tryParse('${json['bitrate']}'),
      width: json['width'] is int
          ? json['width'] as int
          : int.tryParse('${json['width']}'),
      height: json['height'] is int
          ? json['height'] as int
          : int.tryParse('${json['height']}'),
      qualityLabel: _string(json['qualityLabel']),
      contentLength: _string(json['contentLength']),
      audioQuality: _string(json['audioQuality']),
      audioSampleRate: _string(json['audioSampleRate']),
    );
  }

  final int itag;
  final String? url;
  final String? mimeType;
  final int? bitrate;
  final int? width;
  final int? height;
  final String? qualityLabel;
  final String? contentLength;
  final String? audioQuality;
  final String? audioSampleRate;
}

/// Streaming media data container returned in a YouTube `/youtubei/v1/player` response.
@immutable
final class NetworkYouTubeStreamingData {
  const NetworkYouTubeStreamingData({
    this.formats = const [],
    this.adaptiveFormats = const [],
  });

  factory NetworkYouTubeStreamingData.fromJson(Map<String, dynamic> json) {
    final formats = _list(json['formats'])
        .map(_map)
        .nonNulls
        .map(NetworkYouTubeStreamFormat.fromJson)
        .toList(growable: false);

    final adaptiveFormats = _list(json['adaptiveFormats'])
        .map(_map)
        .nonNulls
        .map(NetworkYouTubeStreamFormat.fromJson)
        .toList(growable: false);

    return NetworkYouTubeStreamingData(
      formats: List.unmodifiable(formats),
      adaptiveFormats: List.unmodifiable(adaptiveFormats),
    );
  }

  final List<NetworkYouTubeStreamFormat> formats;
  final List<NetworkYouTubeStreamFormat> adaptiveFormats;
}

/// Response model for YouTube InnerTube `/youtubei/v1/player`.
@immutable
final class NetworkYouTubePlayerResponse {
  const NetworkYouTubePlayerResponse({
    required this.videoId,
    this.responseContext,
    this.playabilityStatus,
    this.videoDetails,
    this.microformat,
    this.streamingData,
  });

  factory NetworkYouTubePlayerResponse.fromJson(
    Map<String, dynamic> json, {
    String? requestedVideoId,
  }) {
    _throwInnerTubeError(json);
    _throwAlertError(json);

    final playability = _map(json['playabilityStatus']);
    final playabilityStatus = playability == null
        ? null
        : NetworkYouTubePlayabilityStatus.fromJson(playability);

    final detailsMap = _map(json['videoDetails']);
    NetworkYouTubePlayerVideoDetails? videoDetails;
    if (detailsMap != null) {
      try {
        videoDetails = NetworkYouTubePlayerVideoDetails.fromJson(detailsMap);
      } on FormatException {
        // Ignore malformed videoDetails
      }
    }

    final videoId = videoDetails?.videoId ?? requestedVideoId;
    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('Player response is missing videoId');
    }

    final microformatMap = _map(json['microformat']);
    final microformat = microformatMap == null
        ? null
        : NetworkYouTubePlayerMicroformat.fromJson(microformatMap);

    final streamingMap = _map(json['streamingData']);
    final streamingData = streamingMap == null
        ? null
        : NetworkYouTubeStreamingData.fromJson(streamingMap);

    return NetworkYouTubePlayerResponse(
      videoId: videoId,
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(
              _map(json['responseContext'])!,
            ),
      playabilityStatus: playabilityStatus,
      videoDetails: videoDetails,
      microformat: microformat,
      streamingData: streamingData,
    );
  }

  final String videoId;
  final NetworkYouTubeResponseContext? responseContext;
  final NetworkYouTubePlayabilityStatus? playabilityStatus;
  final NetworkYouTubePlayerVideoDetails? videoDetails;
  final NetworkYouTubePlayerMicroformat? microformat;
  final NetworkYouTubeStreamingData? streamingData;
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
