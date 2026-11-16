import 'package:data/data.dart';

/// The neutral [FilterGroup.key] values YouTube search filters carry.
abstract final class YoutubeFilterKey {
  static const uploadDate = 'upload_date';
  static const duration = 'duration';
  static const feature = 'feature';
}

/// {@template youtube_filter_option}
/// A selectable YouTube search filter option.
///
/// [FilterOption.label] is the stable identifier of the option, never
/// user-facing copy: the localized text lives in `youtube_<locale>.arb` and is
/// read through `labelWithL10n` / `localizedLabel`.
/// {@endtemplate}

/// {@macro youtube_filter_option}
///
/// [paramValue] is the raw value the option writes into the InnerTube search
/// params.
abstract interface class YoutubeFilterOption implements FilterOption {
  /// The raw value the option writes into the InnerTube search params.
  int get paramValue;
}

/// YouTube upload-date filter values: the protobuf varint at filter field 1.
enum YoutubeUploadDateFilterOption(
  @override final String label,
  @override final int paramValue,
) implements YoutubeFilterOption {
  lastHour('lastHour', 1),
  today('today', 2),
  thisWeek('thisWeek', 3),
  thisMonth('thisMonth', 4),
  thisYear('thisYear', 5);

  @override
  String get value => name;
}

/// YouTube result-type filter values: the protobuf varint at filter field 2.
enum YoutubeContentTypeFilterOption(
  @override final String label,
  @override final int paramValue,
) implements YoutubeFilterOption {
  video('video', 1),
  channel('channel', 2),
  playlist('playlist', 3),
  movie('movie', 4);

  /// The `contentType` value of the video search tab.
  int get contentType => paramValue;

  @override
  String get value => name;
}

/// YouTube duration filter values: the protobuf varint at filter field 3.
enum YoutubeDurationFilterOption(
  @override final String label,
  @override final int paramValue,
) implements YoutubeFilterOption {
  under4Minutes('under4Minutes', 1),
  fourTo20Minutes('fourTo20Minutes', 2),
  over20Minutes('over20Minutes', 3);

  @override
  String get value => name;
}

/// YouTube feature filters, one protobuf field per enabled feature.
enum YoutubeFeatureFilterOption(
  @override final String label,
  @override final int paramValue,
) implements YoutubeFilterOption {
  live('live', 4),
  fourK('fourK', 5),
  hd('hd', 6),
  subtitles('subtitles', 7),
  creativeCommons('creativeCommons', 8),
  threeD('threeD', 9),
  threeSixty('threeSixty', 11),
  hdr('hdr', 14);

  @override
  String get value => name;
}

/// Maps a neutral [FilterOption] back onto [T] by its stable [FilterOption.value],
/// so a filter rebuilt elsewhere still resolves to a request value.
T? youtubeFilterOptionFrom<T extends YoutubeFilterOption>(
  FilterOption? option,
  List<T> candidates,
) {
  if (option == null) {
    return null;
  }
  for (final candidate in candidates) {
    if (candidate.value == option.value) {
      return candidate;
    }
  }
  return null;
}

class const YoutubeUploadDateFilterGroup({
  super.selection,
  super.label = 'upload_date',
}) extends SingleFilterGroup {
  this
    : super(
        key: YoutubeFilterKey.uploadDate,
        options: YoutubeUploadDateFilterOption.values,
      );
}

class const YoutubeDurationFilterGroup({
  super.selection,
  super.label = 'duration',
}) extends SingleFilterGroup {
  this
    : super(
        key: YoutubeFilterKey.duration,
        options: YoutubeDurationFilterOption.values,
      );
}

class const YoutubeFeatureFilterGroup({
  super.selections = const {},
  super.label = 'feature',
}) extends MultiFilterGroup {
  this
    : super(
        key: YoutubeFilterKey.feature,
        options: YoutubeFeatureFilterOption.values,
      );
}
