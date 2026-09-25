import 'package:ypi/ypi.dart';

Iterable<NetworkYouTubeSearchSection> _sections({
  required NetworkYouTubeSearchContents? contents,
  required List<NetworkYouTubeResponseCommand> commands,
}) sync* {
  final initialSections =
      contents
          ?.twoColumnSearchResultsRenderer
          ?.primaryContents
          ?.sectionListRenderer
          ?.contents ??
      const <NetworkYouTubeSearchSection>[];
  yield* initialSections;

  for (final command in commands) {
    final action = command.appendContinuationItemsAction;
    if (action != null) {
      yield* action.continuationItems;
    }
  }
}

List<NetworkYouTubeVideoRenderer> videoRenderers(
  NetworkYouTubeVideoSearchResponse response,
) {
  return [
    for (final section in _sections(
      contents: response.contents,
      commands: response.onResponseReceivedCommands,
    ))
      if (section is NetworkYouTubeItemSectionRenderer)
        for (final item in section.contents)
          if (item is NetworkYouTubeVideoSearchItem) item.renderer,
  ];
}

List<NetworkYouTubeChannelRenderer> channelRenderers(
  NetworkYouTubeChannelSearchResponse response,
) {
  return [
    for (final section in _sections(
      contents: response.contents,
      commands: response.onResponseReceivedCommands,
    ))
      if (section is NetworkYouTubeItemSectionRenderer)
        for (final item in section.contents)
          if (item is NetworkYouTubeChannelSearchItem) item.renderer,
  ];
}

String? videoContinuationToken(
  NetworkYouTubeVideoSearchResponse response,
) {
  String? token;
  for (final section in _sections(
    contents: response.contents,
    commands: response.onResponseReceivedCommands,
  )) {
    if (section is NetworkYouTubeContinuationSection) {
      token = section.renderer.token;
      continue;
    }
    if (section is! NetworkYouTubeItemSectionRenderer) {
      continue;
    }
    for (final item in section.contents) {
      if (item is NetworkYouTubeContinuationSearchItem) {
        token = item.renderer.token;
      }
    }
  }
  return token;
}

String? channelContinuationToken(
  NetworkYouTubeChannelSearchResponse response,
) {
  String? token;
  for (final section in _sections(
    contents: response.contents,
    commands: response.onResponseReceivedCommands,
  )) {
    if (section is NetworkYouTubeContinuationSection) {
      token = section.renderer.token;
      continue;
    }
    if (section is! NetworkYouTubeItemSectionRenderer) {
      continue;
    }
    for (final item in section.contents) {
      if (item is NetworkYouTubeContinuationSearchItem) {
        token = item.renderer.token;
      }
    }
  }
  return token;
}
