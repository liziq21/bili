import 'package:json_annotation/json_annotation.dart';

part 'search_type.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: FieldRename.snake)
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
  
  /*static SearchType? parse(String type) =>
    $enumDecodeNullable(
      _$SearchTypeEnumMap,
      type,
      unknownValue: JsonKey.nullForUndefinedEnumValue,
    );*/
}
