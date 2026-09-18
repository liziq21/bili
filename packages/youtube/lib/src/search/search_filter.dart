import 'package:data/data.dart';

enum YoutubeUploadDateFilterOption implements FilterOption {
  lastHour('lastHour', 1),
  today('today', 2),
  thisWeek('thisWeek', 3),
  thisMonth('thisMonth', 4),
  thisYear('thisYear', 5);

  const YoutubeUploadDateFilterOption(this.label, this.valueInt);

  @override
  final String label;

  final int valueInt;

  @override
  String get value => name;
}

enum YoutubeContentTypeFilterOption implements FilterOption {
  video('video', 1),
  channel('channel', 2),
  playlist('playlist', 3),
  movie('movie', 4);

  const YoutubeContentTypeFilterOption(this.label, this.valueInt);

  @override
  final String label;

  final int valueInt;

  @override
  String get value => name;
}

enum YoutubeDurationFilterOption implements FilterOption {
  under4Minutes('under4Minutes', 1),
  fourTo20Minutes('fourTo20Minutes', 2),
  over20Minutes('over20Minutes', 3);

  const YoutubeDurationFilterOption(this.label, this.valueInt);

  @override
  final String label;

  final int valueInt;

  @override
  String get value => name;
}

enum YoutubeFeatureFilterOption implements FilterOption {
  live('live', 4),
  fourK('fourK', 5),
  hd('hd', 6),
  subtitles('subtitles', 7),
  creativeCommons('creativeCommons', 8),
  threeD('threeD', 9),
  threeSixty('threeSixty', 11),
  hdr('hdr', 14);

  const YoutubeFeatureFilterOption(this.label, this.fieldTag);

  @override
  final String label;

  final int fieldTag;

  @override
  String get value => name;
}

class YoutubeUploadDateFilterGroup extends SingleFilterGroup {
  const YoutubeUploadDateFilterGroup({
    super.selection,
    super.label = 'upload_date',
  }) : super(key: 'upload_date', options: YoutubeUploadDateFilterOption.values);
}

class YoutubeDurationFilterGroup extends SingleFilterGroup {
  const YoutubeDurationFilterGroup({super.selection, super.label = 'duration'})
    : super(key: 'duration', options: YoutubeDurationFilterOption.values);
}

class YoutubeFeatureFilterGroup extends MultiFilterGroup {
  const YoutubeFeatureFilterGroup({
    super.selections = const {},
    super.label = 'feature',
  }) : super(key: 'feature', options: YoutubeFeatureFilterOption.values);
}
