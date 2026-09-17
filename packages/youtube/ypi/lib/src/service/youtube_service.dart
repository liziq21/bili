import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:data/data.dart';
import 'package:http/http.dart' as http;

import '../api/yt_api.dart';
import '../api/yt_interceptor.dart';
import '../model/yt_search_filter.dart';
import '../model/yt_search_sort.dart';
import '../protobuf/yt_protobuf_encoder.dart';

class YoutubeService {
  YoutubeService({http.Client? httpClient, ChopperClient? chopperClient})
    : _ownsHttpClient = httpClient == null && chopperClient == null,
      _httpClient = httpClient ?? http.Client() {
    _chopperClient =
        chopperClient ??
        ChopperClient(
          client: _httpClient,
          converter: const YoutubeRequestConverter(),
          interceptors: [const YoutubeInnerTubeInterceptor()],
        );
    _api = YoutubeApi.create(_chopperClient);
  }

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  late final ChopperClient _chopperClient;
  late final YoutubeApi _api;

  void close() {
    _chopperClient.dispose();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<(List<VideoModel> videos, String? continuationToken)> searchVideos(
    String query, {
    YoutubeSearchSort sort = YoutubeSearchSort.relevance,
    YoutubeUploadDateFilter? uploadDate,
    YoutubeDurationFilter? duration,
    Set<YoutubeFeatureFilter> features = const {},
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = query;
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: sort,
        uploadDate: uploadDate,
        contentType: YoutubeContentTypeFilter.video,
        duration: duration,
        features: features,
      );
      if (params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _api.search(body);
    if (!response.isSuccessful || response.body == null) {
      return (const <VideoModel>[], null);
    }

    final data = response.body!;
    return _parseVideoSearchResponse(data);
  }

  Future<(List<CreatorProfile> profiles, String? continuationToken)>
  searchChannels(
    String query, {
    YoutubeSearchSort sort = YoutubeSearchSort.relevance,
    String? continuation,
  }) async {
    final body = <String, dynamic>{};
    if (continuation != null && continuation.isNotEmpty) {
      body['continuation'] = continuation;
    } else {
      body['query'] = query;
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: sort,
        contentType: YoutubeContentTypeFilter.channel,
      );
      if (params.isNotEmpty) {
        body['params'] = params;
      }
    }

    final response = await _api.search(body);
    if (!response.isSuccessful || response.body == null) {
      return (const <CreatorProfile>[], null);
    }

    final data = response.body!;
    return _parseChannelSearchResponse(data);
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await _api.getSearchSuggestions(query);
      if (!response.isSuccessful || response.body == null) {
        return const [];
      }

      final bodyString = response.body!;
      var jsonText = bodyString;
      if (jsonText.startsWith('window.google.ac.h(')) {
        jsonText = jsonText
            .substring('window.google.ac.h('.length, jsonText.length - 1)
            .trim();
      }

      final decoded = json.decode(jsonText);
      if (decoded is List && decoded.length >= 2 && decoded[1] is List) {
        final rawSuggestions = decoded[1] as List;
        return rawSuggestions
            .map((e) => e is List ? e[0].toString() : e.toString())
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  (List<VideoModel> videos, String? continuationToken)
  _parseVideoSearchResponse(Map<String, dynamic> data) {
    final videos = <VideoModel>[];
    String? continuationToken;

    final items = [];

    final contents =
        data['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']
            as List?;
    if (contents != null) {
      for (final section in contents) {
        final itemSection =
            section['itemSectionRenderer']?['contents'] as List?;
        if (itemSection != null) {
          items.addAll(itemSection);
        }
        final contItem = section['continuationItemRenderer'];
        if (contItem != null) {
          continuationToken = _extractContinuationToken(contItem);
        }
      }
    }

    final continuationContents = data['onResponseReceivedCommands'] as List?;
    if (continuationContents != null) {
      for (final command in continuationContents) {
        final appendContinuationItems =
            command['appendContinuationItemsAction']?['continuationItems']
                as List?;
        if (appendContinuationItems != null) {
          for (final item in appendContinuationItems) {
            final itemSection =
                item['itemSectionRenderer']?['contents'] as List?;
            if (itemSection != null) {
              items.addAll(itemSection);
            } else {
              items.add(item);
            }
            if (item.containsKey('continuationItemRenderer')) {
              continuationToken = _extractContinuationToken(
                item['continuationItemRenderer'],
              );
            }
          }
        }
      }
    }

    for (final item in items) {
      if (item is Map<String, dynamic> && item.containsKey('videoRenderer')) {
        final video = _parseVideoRenderer(item['videoRenderer']);
        if (video != null) {
          videos.add(video);
        }
      } else if (item is Map<String, dynamic> &&
          item.containsKey('continuationItemRenderer')) {
        continuationToken = _extractContinuationToken(
          item['continuationItemRenderer'],
        );
      }
    }

    return (videos, continuationToken);
  }

  (List<CreatorProfile> profiles, String? continuationToken)
  _parseChannelSearchResponse(Map<String, dynamic> data) {
    final profiles = <CreatorProfile>[];
    String? continuationToken;

    final items = [];

    final contents =
        data['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']
            as List?;
    if (contents != null) {
      for (final section in contents) {
        final itemSection =
            section['itemSectionRenderer']?['contents'] as List?;
        if (itemSection != null) {
          items.addAll(itemSection);
        }
        final contItem = section['continuationItemRenderer'];
        if (contItem != null) {
          continuationToken = _extractContinuationToken(contItem);
        }
      }
    }

    final continuationContents = data['onResponseReceivedCommands'] as List?;
    if (continuationContents != null) {
      for (final command in continuationContents) {
        final appendContinuationItems =
            command['appendContinuationItemsAction']?['continuationItems']
                as List?;
        if (appendContinuationItems != null) {
          for (final item in appendContinuationItems) {
            final itemSection =
                item['itemSectionRenderer']?['contents'] as List?;
            if (itemSection != null) {
              items.addAll(itemSection);
            } else {
              items.add(item);
            }
            if (item.containsKey('continuationItemRenderer')) {
              continuationToken = _extractContinuationToken(
                item['continuationItemRenderer'],
              );
            }
          }
        }
      }
    }

    for (final item in items) {
      if (item is Map<String, dynamic> && item.containsKey('channelRenderer')) {
        final profile = _parseChannelRenderer(item['channelRenderer']);
        if (profile != null) {
          profiles.add(profile);
        }
      } else if (item is Map<String, dynamic> &&
          item.containsKey('continuationItemRenderer')) {
        continuationToken = _extractContinuationToken(
          item['continuationItemRenderer'],
        );
      }
    }

    return (profiles, continuationToken);
  }

  String? _extractContinuationToken(dynamic contItem) {
    if (contItem is Map<String, dynamic>) {
      final endpoint = contItem['continuationEndpoint'];
      final token = endpoint?['continuationCommand']?['token'] as String?;
      return token;
    }
    return null;
  }

  VideoModel? _parseVideoRenderer(Map<String, dynamic> json) {
    try {
      final videoId = json['videoId'] as String?;
      if (videoId == null || videoId.isEmpty) return null;

      final title = _extractText(json['title']);
      final url = 'https://www.youtube.com/watch?v=$videoId';

      final thumbnails = json['thumbnail']?['thumbnails'] as List?;
      final thumbnailUrl = (thumbnails != null && thumbnails.isNotEmpty)
          ? (thumbnails.last['url'] as String?) ?? ''
          : '';

      final viewCountText = _extractText(json['viewCountText']);
      final viewCount = _parseViewCount(viewCountText);

      final uploadDateText = _extractText(json['publishedTimeText']);
      final uploadDate = _parseUploadDate(uploadDateText);
      final lengthText = _extractText(json['lengthText']);
      final duration = _parseDurationInSeconds(lengthText);

      final ownerRuns = json['ownerText']?['runs'] as List?;
      final creatorName = (ownerRuns != null && ownerRuns.isNotEmpty)
          ? (ownerRuns[0]['text'] as String?) ?? ''
          : '';

      final browseEndpoint =
          ownerRuns?[0]?['navigationEndpoint']?['browseEndpoint'];
      final creatorId = (browseEndpoint?['browseId'] as String?) ?? '';

      final descriptionSnippet = _extractText(json['descriptionSnippet']);

      return VideoModel(
        id: videoId,
        title: title,
        url: url,
        thumbnailUrl: thumbnailUrl,
        viewCount: viewCount,
        uploadDate: uploadDate,
        duration: duration,
        desc: descriptionSnippet,
        creatorProfileName: creatorName,
        creatorProfileId: creatorId,
      );
    } catch (_) {
      return null;
    }
  }

  CreatorProfile? _parseChannelRenderer(Map<String, dynamic> json) {
    try {
      final channelId = json['channelId'] as String?;
      if (channelId == null || channelId.isEmpty) return null;

      final title = _extractText(json['title']);

      final avatarThumbnails = json['thumbnail']?['thumbnails'] as List?;
      final thumbnailUrl =
          (avatarThumbnails != null && avatarThumbnails.isNotEmpty)
          ? (avatarThumbnails.last['url'] as String?) ?? ''
          : null;

      final videoCountText = _extractText(json['videoCountText']);
      final videoCount = _parseInt(videoCountText);

      return CreatorProfile(
        id: channelId,
        name: title,
        thumbnailUrl: thumbnailUrl,
        videos: videoCount,
      );
    } catch (_) {
      return null;
    }
  }

  String _extractText(dynamic node) {
    if (node == null) return '';
    if (node is String) return node;
    if (node is Map<String, dynamic>) {
      if (node.containsKey('simpleText')) {
        return (node['simpleText'] as String?) ?? '';
      }
      if (node.containsKey('runs') && node['runs'] is List) {
        final runs = node['runs'] as List;
        return runs.map((r) => (r['text'] as String?) ?? '').join();
      }
    }
    return '';
  }

  int? _parseViewCount(String text) {
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits);
  }

  int? _parseInt(String text) {
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits);
  }

  int? _parseDurationInSeconds(String text) {
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return m * 60 + s;
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    }
    return null;
  }

  DateTime? _parseUploadDate(String text) {
    if (text.isEmpty) return null;
    final parsedDirect = DateTime.tryParse(text);
    if (parsedDirect != null) return parsedDirect;

    final now = DateTime.now();
    final lower = text.toLowerCase();

    final numberMatch = RegExp(r'\d+').firstMatch(lower);
    if (numberMatch == null) return null;
    final amount = int.tryParse(numberMatch.group(0)!) ?? 0;

    if (lower.contains('hour') || lower.contains('小时')) {
      return now.subtract(Duration(hours: amount));
    } else if (lower.contains('day') || lower.contains('天')) {
      return now.subtract(Duration(days: amount));
    } else if (lower.contains('week') || lower.contains('周')) {
      return now.subtract(Duration(days: amount * 7));
    } else if (lower.contains('month') || lower.contains('月')) {
      return now.subtract(Duration(days: amount * 30));
    } else if (lower.contains('year') || lower.contains('年')) {
      return now.subtract(Duration(days: amount * 365));
    } else if (lower.contains('minute') || lower.contains('分')) {
      return now.subtract(Duration(minutes: amount));
    }
    return null;
  }
}
