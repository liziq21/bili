import 'package:json_annotation/json_annotation.dart';

part 'search_result_type.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: FieldRename.snake)
enum SearchResultType {
  article,
  biliUser,
  mediaBangumi,
  mediaFt,
  liveRoom,
  liveUser,
  video;
  
  static SearchResultType? parse(String type) =>
    $enumDecodeNullable(
      _$SearchResultTypeEnumMap,
      type,
      unknownValue: JsonKey.nullForUndefinedEnumValue,
    );
}
