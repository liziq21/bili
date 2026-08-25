import 'package:json_annotation/json_annotation.dart';
part 'search_type.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: .snake)
enum SearchType {
  article,
  biliUser,
  photo,
  topic,
  mediaBangumi,
  mediaFt,
  live,
  liveRoom,
  liveUser,
  video;

  @override
  String toString() => _$SearchTypeEnumMap[this]!;
}
