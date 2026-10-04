import 'package:meta/meta.dart';

import '../exception/ypi_exception.dart';
import 'network_youtube_search.dart';

/// Author details of a YouTube comment.
@immutable
final class NetworkYouTubeCommentAuthor {
  const NetworkYouTubeCommentAuthor({
    this.channelId,
    this.displayName,
    this.avatar,
  });

  final String? channelId;
  final String? displayName;
  final NetworkYouTubeThumbnail? avatar;
}

/// Typed representation of a YouTube video comment thread item.
@immutable
final class NetworkYouTubeCommentThread {
  const NetworkYouTubeCommentThread({
    required this.commentId,
    this.author,
    this.text,
    this.publishedTimeText,
    this.likeCountText,
    this.replyCount,
    this.replyContinuationToken,
  });

  factory NetworkYouTubeCommentThread.fromJson(
    Map<String, dynamic> json, {
    Map<String, Map<String, dynamic>>? entityMap,
  }) {
    final commentThread = _map(json['commentThreadRenderer']);
    final rawCommentNode = commentThread ?? json;

    final commentViewModel = _map(rawCommentNode['commentViewModel']);
    final innerViewModel = _map(commentViewModel?['commentViewModel']);
    final commentRenderer = _map(rawCommentNode['comment']);

    String? commentId;
    NetworkYouTubeCommentAuthor? author;
    String? text;
    String? publishedTimeText;
    String? likeCountText;
    int? replyCount;
    String? replyContinuationToken;

    if (innerViewModel != null) {
      commentId = _string(innerViewModel['commentId']);
      final entityKey = _string(innerViewModel['commentKey']);

      Map<String, dynamic>? entity;
      if (entityMap != null) {
        if (entityKey != null && entityMap.containsKey(entityKey)) {
          entity = entityMap[entityKey];
        } else if (commentId != null) {
          for (final candidate in entityMap.values) {
            final props = _map(candidate['properties']);
            if (_string(props?['commentId']) == commentId) {
              entity = candidate;
              break;
            }
          }
        }
      }

      if (entity != null) {
        final authorObj = _map(entity['author']);
        final propsObj = _map(entity['properties']);
        final toolbarObj = _map(entity['toolbar']);

        final avatarUrl = _string(authorObj?['avatarThumbnailUrl']);
        author = NetworkYouTubeCommentAuthor(
          channelId: _string(authorObj?['channelId']),
          displayName: _string(authorObj?['displayName']),
          avatar: avatarUrl != null
              ? NetworkYouTubeThumbnail(
                  thumbnails: [
                    NetworkYouTubeThumbnailSize(
                      url: avatarUrl,
                      width: null,
                      height: null,
                    ),
                  ],
                )
              : null,
        );

        final contentObj = _map(propsObj?['content']);
        text = _string(contentObj?['content']);
        publishedTimeText = _string(propsObj?['publishedTime']);

        likeCountText =
            _string(toolbarObj?['likeCountNotliked']) ??
            _string(toolbarObj?['likeCountLiked']);

        final rawReplyCount = _string(toolbarObj?['replyCount']);
        if (rawReplyCount != null) {
          replyCount = int.tryParse(rawReplyCount.replaceAll(',', ''));
        }
      }
    } else if (commentRenderer != null) {
      final renderer =
          _map(commentRenderer['commentRenderer']) ?? commentRenderer;
      commentId = _string(renderer['commentId']);

      final authorText = NetworkYouTubeText.fromJson(renderer['authorText']);
      final authorEndpoint = _map(renderer['authorEndpoint']);
      final browseEndpoint = _map(authorEndpoint?['browseEndpoint']);
      final channelId = _string(browseEndpoint?['browseId']);
      final thumbnail = NetworkYouTubeThumbnail.fromJson(
        renderer['authorThumbnail'],
      );

      author = NetworkYouTubeCommentAuthor(
        channelId: channelId,
        displayName: authorText.value,
        avatar: thumbnail,
      );

      final contentText = NetworkYouTubeText.fromJson(renderer['contentText']);
      text = contentText.value;

      final pubTime = NetworkYouTubeText.fromJson(
        renderer['publishedTimeText'],
      );
      publishedTimeText = pubTime.value;

      final voteCount = NetworkYouTubeText.fromJson(renderer['voteCount']);
      likeCountText = voteCount.value;

      if (renderer['replyCount'] is int) {
        replyCount = renderer['replyCount'] as int;
      }
    }

    if (commentId == null || commentId.isEmpty) {
      throw const FormatException('commentThread is missing commentId');
    }

    final repliesNode = _map(rawCommentNode['replies']);
    final commentReplies = _map(repliesNode?['commentRepliesRenderer']);
    final replyContents = _list(commentReplies?['contents']);
    for (final rawReplyItem in replyContents.map(_map).nonNulls) {
      final contItem = _map(rawReplyItem['continuationItemRenderer']);
      if (contItem != null) {
        replyContinuationToken = _continuationTokenFromJson(contItem);
        if (replyContinuationToken != null) break;
      }
    }

    return NetworkYouTubeCommentThread(
      commentId: commentId,
      author: author,
      text: text,
      publishedTimeText: publishedTimeText,
      likeCountText: likeCountText,
      replyCount: replyCount,
      replyContinuationToken: replyContinuationToken,
    );
  }

  final String commentId;
  final NetworkYouTubeCommentAuthor? author;
  final String? text;
  final String? publishedTimeText;
  final String? likeCountText;
  final int? replyCount;
  final String? replyContinuationToken;
}

/// Response returned by YouTube InnerTube comment list endpoint (`/youtubei/v1/next`).
@immutable
final class NetworkYouTubeCommentsResponse {
  const NetworkYouTubeCommentsResponse({
    this.responseContext,
    this.headerCountText,
    this.items = const [],
    this.continuationToken,
  });

  factory NetworkYouTubeCommentsResponse.fromJson(Map<String, dynamic> json) {
    _throwInnerTubeError(json);
    _throwAlertError(json);

    String? headerCountText;
    final items = <NetworkYouTubeCommentThread>[];
    String? continuationToken;

    final entityMap = <String, Map<String, dynamic>>{};
    final frameworkUpdates = _map(json['frameworkUpdates']);
    final entityBatchUpdate = _map(frameworkUpdates?['entityBatchUpdate']);
    for (final rawMutation in _list(
      entityBatchUpdate?['mutations'],
    ).map(_map).nonNulls) {
      final payload = _map(rawMutation['payload']);
      final commentEntity = _map(payload?['commentEntityPayload']);
      if (commentEntity != null) {
        final key = _string(commentEntity['key']);
        if (key != null) {
          entityMap[key] = commentEntity;
        }
      }
    }

    final rawEndpoints = <dynamic>[
      ..._list(json['onResponseReceivedEndpoints']),
      ..._list(json['onResponseReceivedActions']),
    ];
    final endpoints = rawEndpoints.map(_map).nonNulls;

    // 响应结构若变化，端点列表会整个消失。此时继续走会静默返回空评论列表，
    // 调用方分不清「视频没有评论」和「解析器不认识这个响应」，故按未识别响应抛错。
    if (endpoints.isEmpty) {
      throw const FormatException(
        'Comments response carried no continuation endpoints',
      );
    }

    for (final ep in endpoints) {
      final cmd =
          _map(ep['reloadContinuationItemsCommand']) ??
          _map(ep['appendContinuationItemsAction']);
      if (cmd == null) continue;

      final continuationItems = _list(cmd['continuationItems'])
          .map(_map)
          .nonNulls;
      for (final rawItem in continuationItems) {
        final header = _map(rawItem['commentsHeaderRenderer']);
        if (header != null) {
          final countText = NetworkYouTubeText.fromJson(header['countText']);
          headerCountText ??= countText.value;
          continue;
        }

        if (rawItem.containsKey('commentThreadRenderer') ||
            rawItem.containsKey('commentViewModel')) {
          try {
            final thread = NetworkYouTubeCommentThread.fromJson(
              rawItem,
              entityMap: entityMap,
            );
            items.add(thread);
          } on FormatException {
            // Ignore unparseable comment
          }
          continue;
        }

        final contItem = _map(rawItem['continuationItemRenderer']);
        if (contItem != null) {
          continuationToken ??= _continuationTokenFromJson(contItem);
        }
      }
    }

    return NetworkYouTubeCommentsResponse(
      responseContext: _map(json['responseContext']) == null
          ? null
          : NetworkYouTubeResponseContext.fromJson(
              _map(json['responseContext'])!,
            ),
      headerCountText: headerCountText,
      items: List.unmodifiable(items),
      continuationToken: continuationToken,
    );
  }

  final NetworkYouTubeResponseContext? responseContext;
  final String? headerCountText;
  final List<NetworkYouTubeCommentThread> items;
  final String? continuationToken;
}

String? _continuationTokenFromJson(Map<String, dynamic> renderer) {
  final endpoint = _map(renderer['continuationEndpoint']);
  final command = _map(endpoint?['continuationCommand']);
  return _string(command?['token']);
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
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

extension _NonNulls<T> on Iterable<T?> {
  Iterable<T> get nonNulls => where((value) => value != null).cast<T>();
}
