import 'package:data/data.dart';

enum YoutubeUploadDateFilterOption(
  @override
  final String label, final int valueInt) implements FilterOption {
  lastHour('lastHour', 1),
  today('today', 2),
  thisWeek('thisWeek', 3),
  thisMonth('thisMonth', 4),
  thisYear('thisYear', 5);

  @override
  String get value => name;
}

enum YoutubeContentTypeFilterOption(
  @override
  final String label, final int valueInt) implements FilterOption {
  video('video', 1),
  channel('channel', 2),
  playlist('playlist', 3),
  movie('movie', 4);

  @override
  String get value => name;
}

enum YoutubeDurationFilterOption(
  @override
  final String label, final int valueInt) implements FilterOption {
  under4Minutes('under4Minutes', 1),
  fourTo20Minutes('fourTo20Minutes', 2),
  over20Minutes('over20Minutes', 3);

  @override
  String get value => name;
}

enum YoutubeFeatureFilterOption(
  @override
  final String label, final int fieldTag) implements FilterOption {
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

class const YoutubeUploadDateFilterGroup({
    super.selection,
    super.label = 'upload_date',
  }) extends SingleFilterGroup {
  this : super(key: 'upload_date', options: YoutubeUploadDateFilterOption.values);
}

class const YoutubeDurationFilterGroup({super.selection, super.label = 'duration'}) extends SingleFilterGroup {
  this
    : super(key: 'duration', options: YoutubeDurationFilterOption.values);
}

class const YoutubeFeatureFilterGroup({
    super.selections = const {},
    super.label = 'feature',
  }) extends MultiFilterGroup {
  this : super(key: 'feature', options: YoutubeFeatureFilterOption.values);
}
