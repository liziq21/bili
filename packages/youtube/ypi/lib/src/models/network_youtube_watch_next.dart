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

    // 首屏是 twoColumnWatchNextResults.results.results.contents；续页走
    // onResponseReceivedActions[].appendContinuationItemsAction.continuationItems，
    // 结构完全不同。只读首屏那条路径，续页响应会被当成「没有内容」——而续页
    // 请求本身不带 videoId，videoId 只能靠调用方兜底，于是内容为空却解析成功。
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

        // 简介有两个位置，且都不走 NetworkYouTubeText 的两种形态：
        // `description` 是 runs/simpleText，而 `attributedDescription` 是
        // `{commandRuns, content, styleRuns}`——文本在 `content` 键上，既不是
        // simpleText 也不是 runs。只喂给 NetworkYouTubeText 会解析出 null，
        // 于是 `from_json_test.dart` 对真实 fixture 断言 description 非空直接
        // 失败（这条断言最初就是这么红的）。
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
        // 只取评论区段落的令牌。`|| commentsContinuationToken == null` 会让排在
        // 评论区段之前、同样带 continuationItemRenderer 的区段抢先写入自己的
        // 令牌，而 `??=` 又使真正的评论区令牌无法覆盖它。
        if (targetId == 'comments-section') {
          for (final rawContent in _list(
            itemSection['contents'],
          ).map(_map).nonNulls) {
            final contItem = _map(rawContent['continuationItemRenderer']);
            if (contItem != null) {
              final endpoint = _map(contItem['continuationEndpoint']);
              final command = _map(endpoint?['continuationCommand']);
              final token = _string(command?['token']);
              if (token != null) {
                commentsContinuationToken = token;
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
    // videoId 可以由调用方兜底，但内容字段不行。HTTP 200 + 非空 results 的
    // 无效响应（失效/受限视频）会让上面两个 renderer 循环全程空转，只靠
    // videoId 检查就放行，调用方拿到的是标题/作者/简介全 null 的「成功」
    // 响应，而不是一个错误。至少要有标题才说明确实解析到了主信息。
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

  /// 评论区段落的 continuation token，抓取评论续页时使用。
  final String? commentsContinuationToken;
}

/// Pulls `continuationItems` out of a paginated `next` response.
///
/// YouTube 续页把追加条目放在 `onResponseReceivedActions[]` 里，每项形如
/// `{"appendContinuationItemsAction": {"continuationItems": [...]}}`；reload
/// 条目走 `reloadContinuationItemsCommand`，同样带 `continuationItems`。
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

/// Turns an `alerts[]` ERROR block into a typed business error.
///
/// YouTube answers a removed or restricted video with HTTP 200, no top-level
/// `error`, and `alerts[].alertRenderer` of type `ERROR`. Without this the
/// response fails later with a `FormatException` about the missing title, and
/// the caller cannot tell an InnerTube refusal from a malformed response.
/// Same classification `network_youtube_browse.dart` applies to a missing
/// channel.
void _throwAlertError(Map<String, dynamic> json) {
  for (final rawAlert in _list(json['alerts']).map(_map).nonNulls) {
    final alert = _map(rawAlert['alertRenderer']);
    if (alert == null) continue;
    final type = _string(alert['type']);
    if (type == null || type == 'OK') continue;
    throw YpiInnerTubeException(
      code: null,
      continuation: null,
      // alert 的文本有两种形态：simpleText 与 runs。NetworkYouTubeText 两种都
      // 认，手工只读 simpleText 会在 runs 形态下退化成 'InnerTube alert: ERROR'，
      // 把具体原因丢掉。
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
