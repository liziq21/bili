import 'dart:convert';

import '../exception/ypi_exception.dart';

final class NetworkYouTubeSearchSuggestions {
  const NetworkYouTubeSearchSuggestions({
    required this.query,
    required this.suggestions,
  });

  factory NetworkYouTubeSearchSuggestions.fromResponse({
    required String query,
    required String responseBody,
  }) {
    var text = responseBody.trim();
    const prefix = 'window.google.ac.h(';
    if (text.startsWith(prefix)) {
      final closingParenthesis = text.lastIndexOf(')');
      if (closingParenthesis > prefix.length) {
        text = text.substring(prefix.length, closingParenthesis).trim();
      }
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      throw YpiJsonException('Invalid Google Suggest JSON: ${error.message}');
    }

    if (decoded is! List || decoded.length < 2 || decoded[1] is! List) {
      throw const YpiJsonException(
        'Google Suggest response has an unexpected shape',
      );
    }

    final suggestions = <String>[];
    for (final entry in decoded[1] as List<dynamic>) {
      final value = entry is List && entry.isNotEmpty ? entry.first : entry;
      if (value is String && value.isNotEmpty) {
        suggestions.add(value);
      }
    }

    return NetworkYouTubeSearchSuggestions(
      query: query,
      suggestions: List.unmodifiable(suggestions),
    );
  }

  final String query;
  final List<String> suggestions;
}

final class NetworkYouTubeTextRun {
  const NetworkYouTubeTextRun({required this.text, this.navigationEndpoint});

  factory NetworkYouTubeTextRun.fromJson(Map<String, dynamic> json) {
    return NetworkYouTubeTextRun(
      text: _string(json['text']) ?? '',
      navigationEndpoint: NetworkYouTubeNavigationEndpoint.fromJson(
        json['navigationEndpoint'],
      ),
    );
  }

  final String text;
  final NetworkYouTubeNavigationEndpoint? navigationEndpoint;
}

final class NetworkYouTubeText {
  const NetworkYouTubeText({this.simpleText, this.runs = const []});

  factory NetworkYouTubeText.fromJson(Object? value) {
    final json = _map(value);
    if (json == null) {
      return const NetworkYouTubeText();
    }
    final rawRuns = _list(json['runs']);
    return NetworkYouTubeText(
      simpleText: _string(json['simpleText']),
      runs: List.unmodifiable(
        rawRuns
            .map(_map)
            .nonNulls
            .map(NetworkYouTubeTextRun.fromJson)
            .toList(growable: false),
      ),
    );
  }

  final String? simpleText;
  final List<NetworkYouTubeTextRun> runs;

  String? get value {
    if (simpleText != null && simpleText!.isNotEmpty) {
      return simpleText;
    }
    if (runs.isEmpty) {
      return null;
    }
    final value = runs.map((run) => run.text).join();
    return value.isEmpty ? null : value;
  }
}

final class NetworkYouTubeNavigationEndpoint {
  const NetworkYouTubeNavigationEndpoint({this.browseId});

  factory NetworkYouTubeNavigationEndpoint.fromJson(Object? value) {
    final json = _map(value);
    final browse = _map(json?['browseEndpoint']);
    return NetworkYouTubeNavigationEndpoint(
      browseId: _string(browse?['browseId']),
    );
  }

  final String? browseId;
}

final class NetworkYouTubeThumbnail {
  const NetworkYouTubeThumbnail({this.thumbnails = const []});

  factory NetworkYouTubeThumbnail.fromJson(Object? value) {
    final json = _map(value);
    final rawThumbnails = _list(json?['thumbnails']);
    return NetworkYouTubeThumbnail(
      thumbnails: List.unmodifiable(
        rawThumbnails
            .map(_map)
            .nonNulls
            .map(
              (thumbnail) => NetworkYouTubeThumbnailSize(
                url: _string(thumbnail['url']),
                width: _integer(thumbnail['width']),
                height: _integer(thumbnail['height']),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  final List<NetworkYouTubeThumbnailSize> thumbnails;
}

final class NetworkYouTubeThumbnailSize {
  const NetworkYouTubeThumbnailSize({this.url, this.width, this.height});

  final String? url;
  final int? width;
  final int? height;
}

final class NetworkYouTubeVideoRenderer {
  const NetworkYouTubeVideoRenderer({
    required this.videoId,
    this.title,
    this.thumbnail,
    this.viewCountText,
    this.publishedTimeText,
    this.lengthText,
    this.owner,
    this.descriptionSnippet,
  });

  factory NetworkYouTubeVideoRenderer.fromJson(Map<String, dynamic> json) {
    final videoId = _string(json['videoId']);
    if (videoId == null || videoId.isEmpty) {
      throw const FormatException('videoRenderer is missing videoId');
    }

    return NetworkYouTubeVideoRenderer(
      videoId: videoId,
      title: NetworkYouTubeText.fromJson(json['title']),
      thumbnail: NetworkYouTubeThumbnail.fromJson(json['thumbnail']),
      viewCountText: NetworkYouTubeText.fromJson(json['viewCountText']),
      publishedTimeText: NetworkYouTubeText.fromJson(json['publishedTimeText']),
      lengthText: NetworkYouTubeText.fromJson(json['lengthText']),
      owner: NetworkYouTubeOwner.fromJson(json['ownerText']),
      descriptionSnippet: NetworkYouTubeText.fromJson(
        json['descriptionSnippet'],
      ),
    );
  }

  final String videoId;
  final NetworkYouTubeText? title;
  final NetworkYouTubeThumbnail? thumbnail;
  final NetworkYouTubeText? viewCountText;
  final NetworkYouTubeText? publishedTimeText;
  final NetworkYouTubeText? lengthText;
  final NetworkYouTubeOwner? owner;
  final NetworkYouTubeText? descriptionSnippet;
}

final class NetworkYouTubeOwner {
  const NetworkYouTubeOwner({required this.text, this.browseId});

  static NetworkYouTubeOwner? fromJson(Object? value) {
    if (value == null) {
      return null;
    }
    final text = NetworkYouTubeText.fromJson(value);
    final firstRun = text.runs.isEmpty ? null : text.runs.first;
    return NetworkYouTubeOwner(
      text: text,
      browseId: firstRun?.navigationEndpoint?.browseId,
    );
  }

  final NetworkYouTubeText text;
  final String? browseId;
}

final class NetworkYouTubeChannelRenderer {
  const NetworkYouTubeChannelRenderer({
    required this.channelId,
    this.title,
    this.thumbnail,
    this.videoCountText,
    this.subscriberCountText,
    this.navigationEndpoint,
  });

  factory NetworkYouTubeChannelRenderer.fromJson(Map<String, dynamic> json) {
    final channelId = _string(json['channelId']);
    if (channelId == null || channelId.isEmpty) {
      throw const FormatException('channelRenderer is missing channelId');
    }

    return NetworkYouTubeChannelRenderer(
      channelId: channelId,
      title: NetworkYouTubeText.fromJson(json['title']),
      thumbnail: NetworkYouTubeThumbnail.fromJson(json['thumbnail']),
      videoCountText: NetworkYouTubeText.fromJson(json['videoCountText']),
      subscriberCountText: NetworkYouTubeText.fromJson(
        json['subscriberCountText'],
      ),
      navigationEndpoint: NetworkYouTubeNavigationEndpoint.fromJson(
        json['navigationEndpoint'],
      ),
    );
  }

  final String channelId;
  final NetworkYouTubeText? title;
  final NetworkYouTubeThumbnail? thumbnail;
  final NetworkYouTubeText? videoCountText;
  final NetworkYouTubeText? subscriberCountText;
  final NetworkYouTubeNavigationEndpoint? navigationEndpoint;
}

final class NetworkYouTubeContinuationItemRenderer {
  const NetworkYouTubeContinuationItemRenderer({required this.token});

  factory NetworkYouTubeContinuationItemRenderer.fromJson(
    Map<String, dynamic> json,
  ) {
    final endpoint = _map(json['continuationEndpoint']);
    final command = _map(endpoint?['continuationCommand']);
    final token = _string(command?['token']);
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'continuationItemRenderer is missing continuation token',
      );
    }
    return NetworkYouTubeContinuationItemRenderer(token: token);
  }

  final String token;
}

sealed class NetworkYouTubeSearchItem {
  const NetworkYouTubeSearchItem();
}

final class NetworkYouTubeVideoSearchItem extends NetworkYouTubeSearchItem {
  const NetworkYouTubeVideoSearchItem(this.renderer);

  final NetworkYouTubeVideoRenderer renderer;
}

final class NetworkYouTubeChannelSearchItem extends NetworkYouTubeSearchItem {
  const NetworkYouTubeChannelSearchItem(this.renderer);

  final NetworkYouTubeChannelRenderer renderer;
}

final class NetworkYouTubeContinuationSearchItem
    extends NetworkYouTubeSearchItem {
  const NetworkYouTubeContinuationSearchItem(this.renderer);

  final NetworkYouTubeContinuationItemRenderer renderer;
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

final class NetworkYouTubeItemSectionRenderer
    extends NetworkYouTubeSearchSection {
  const NetworkYouTubeItemSectionRenderer({required this.contents});

  factory NetworkYouTubeItemSectionRenderer.fromJson(
    Map<String, dynamic> json,
  ) {
    final renderer = _map(json['itemSectionRenderer']);
    final rawContents = _list(renderer?['contents']);
    return NetworkYouTubeItemSectionRenderer(
      contents: List.unmodifiable(
        rawContents
            .map(_map)
            .nonNulls
            .map(_searchItemFromJson)
            .nonNulls
            .toList(growable: false),
      ),
    );
  }

  final List<NetworkYouTubeSearchItem> contents;
}

sealed class NetworkYouTubeSearchSection {
  const NetworkYouTubeSearchSection();
}

final class NetworkYouTubeContinuationSection
    extends NetworkYouTubeSearchSection {
  const NetworkYouTubeContinuationSection(this.renderer);

  final NetworkYouTubeContinuationItemRenderer renderer;
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

final class NetworkYouTubeSectionListRenderer {
  const NetworkYouTubeSectionListRenderer({required this.contents});

  factory NetworkYouTubeSectionListRenderer.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawContents = _list(json['contents']);
    return NetworkYouTubeSectionListRenderer(
      contents: List.unmodifiable(
        rawContents
            .map(_map)
            .nonNulls
            .map(_searchSectionFromJson)
            .nonNulls
            .toList(growable: false),
      ),
    );
  }

  final List<NetworkYouTubeSearchSection> contents;
}

final class NetworkYouTubePrimaryContents {
  const NetworkYouTubePrimaryContents({this.sectionListRenderer});

  factory NetworkYouTubePrimaryContents.fromJson(Object? value) {
    final json = _map(value);
    final sectionList = _map(json?['sectionListRenderer']);
    return NetworkYouTubePrimaryContents(
      sectionListRenderer: sectionList == null
          ? null
          : NetworkYouTubeSectionListRenderer.fromJson(sectionList),
    );
  }

  final NetworkYouTubeSectionListRenderer? sectionListRenderer;
}

final class NetworkYouTubeTwoColumnSearchResultsRenderer {
  const NetworkYouTubeTwoColumnSearchResultsRenderer({this.primaryContents});

  factory NetworkYouTubeTwoColumnSearchResultsRenderer.fromJson(Object? value) {
    final json = _map(value);
    return NetworkYouTubeTwoColumnSearchResultsRenderer(
      primaryContents: NetworkYouTubePrimaryContents.fromJson(
        json?['primaryContents'],
      ),
    );
  }

  final NetworkYouTubePrimaryContents? primaryContents;
}

final class NetworkYouTubeSearchContents {
  const NetworkYouTubeSearchContents({this.twoColumnSearchResultsRenderer});

  factory NetworkYouTubeSearchContents.fromJson(Object? value) {
    final json = _map(value);
    final twoColumn = json?['twoColumnSearchResultsRenderer'];
    return NetworkYouTubeSearchContents(
      twoColumnSearchResultsRenderer: twoColumn == null
          ? null
          : NetworkYouTubeTwoColumnSearchResultsRenderer.fromJson(twoColumn),
    );
  }

  final NetworkYouTubeTwoColumnSearchResultsRenderer?
  twoColumnSearchResultsRenderer;
}

final class NetworkYouTubeAppendContinuationItemsAction {
  const NetworkYouTubeAppendContinuationItemsAction({
    required this.continuationItems,
  });

  factory NetworkYouTubeAppendContinuationItemsAction.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = _list(json['continuationItems']);
    return NetworkYouTubeAppendContinuationItemsAction(
      continuationItems: List.unmodifiable(
        rawItems
            .map(_map)
            .nonNulls
            .map(_searchSectionFromJson)
            .nonNulls
            .toList(growable: false),
      ),
    );
  }

  final List<NetworkYouTubeSearchSection> continuationItems;
}

final class NetworkYouTubeResponseCommand {
  const NetworkYouTubeResponseCommand({this.appendContinuationItemsAction});

  factory NetworkYouTubeResponseCommand.fromJson(Map<String, dynamic> json) {
    final action = _map(json['appendContinuationItemsAction']);
    return NetworkYouTubeResponseCommand(
      appendContinuationItemsAction: action == null
          ? null
          : NetworkYouTubeAppendContinuationItemsAction.fromJson(action),
    );
  }

  final NetworkYouTubeAppendContinuationItemsAction?
  appendContinuationItemsAction;
}

final class NetworkYouTubeVideoSearchResponse {
  const NetworkYouTubeVideoSearchResponse({
    this.responseContext,
    this.estimatedResults,
    this.contents,
    this.onResponseReceivedCommands = const [],
  });

  factory NetworkYouTubeVideoSearchResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    _throwInnerTubeError(json);
    return NetworkYouTubeVideoSearchResponse(
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(json['responseContext']),
      estimatedResults: _string(json['estimatedResults']),
      contents: json['contents'] == null
          ? null
          : NetworkYouTubeSearchContents.fromJson(json['contents']),
      onResponseReceivedCommands: _responseCommands(json),
    );
  }

  final NetworkYouTubeResponseContext? responseContext;
  final String? estimatedResults;
  final NetworkYouTubeSearchContents? contents;
  final List<NetworkYouTubeResponseCommand> onResponseReceivedCommands;
}

final class NetworkYouTubeChannelSearchResponse {
  const NetworkYouTubeChannelSearchResponse({
    this.responseContext,
    this.estimatedResults,
    this.contents,
    this.onResponseReceivedCommands = const [],
  });

  factory NetworkYouTubeChannelSearchResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    _throwInnerTubeError(json);
    return NetworkYouTubeChannelSearchResponse(
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(json['responseContext']),
      estimatedResults: _string(json['estimatedResults']),
      contents: json['contents'] == null
          ? null
          : NetworkYouTubeSearchContents.fromJson(json['contents']),
      onResponseReceivedCommands: _responseCommands(json),
    );
  }

  final NetworkYouTubeResponseContext? responseContext;
  final String? estimatedResults;
  final NetworkYouTubeSearchContents? contents;
  final List<NetworkYouTubeResponseCommand> onResponseReceivedCommands;
}

final class NetworkYouTubeResponseContext {
  const NetworkYouTubeResponseContext({this.responseId, this.loggedOut});

  factory NetworkYouTubeResponseContext.fromJson(Map<String, dynamic> json) {
    final main = _map(json['mainAppWebResponseContext']);
    final loggedOut = main?['loggedOut'];
    return NetworkYouTubeResponseContext(
      responseId: _string(json['responseId']),
      loggedOut: loggedOut is bool ? loggedOut : null,
    );
  }

  final String? responseId;
  final bool? loggedOut;
}

List<NetworkYouTubeResponseCommand> _responseCommands(
  Map<String, dynamic> json,
) {
  final rawCommands = _list(json['onResponseReceivedCommands']);
  return List.unmodifiable(
    rawCommands
        .map(_map)
        .nonNulls
        .map(NetworkYouTubeResponseCommand.fromJson)
        .where((command) => command.appendContinuationItemsAction != null)
        .toList(growable: false),
  );
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

extension _NonNulls<T> on Iterable<T?> {
  Iterable<T> get nonNulls => where((value) => value != null).cast<T>();
}
