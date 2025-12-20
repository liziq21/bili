import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: .screamingSnake)
enum ThemeConfig {
  followSystem,
  light,
  dark;
  
  String toJson() => _$ThemeConfigTypeEnumMap[this]!;
  
  static SearchResultType fromJson(String type) =>
    $enumDecode(_$ThemeConfigTypeEnumMap, type);
}

@freezed
abstract class UserData with _$UserData {
  @JsonSerializable(fieldRename: .screamingSnake)
  const factory UserData({
    @Default(ThemeConfig.followSystem) ThemeConfig themeConfig,
    @Default(true) bool useDynamicColor,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}

