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
  video,
  unknown;
  
  static SearchResultType parse(String type) =>
    $enumDecode(
      _$SearchResultTypeEnumMap,
      type,
      unknownValue: SearchResultType.unknown,
    );
    
  factory SearchResultType.fromJson(Map<String, dynamic> json)
    => _$SearchResultTypeFromJson(json);
}
