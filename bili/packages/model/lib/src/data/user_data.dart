import 'package:freezed_annotation/freezed_annotation.dart';
import 'theme_config.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: .screamingSnake)
enum ServiceSource {
  bilibili,
  youtube;

  String toJson() => _$ServiceSourceEnumMap[this]!;

  static ServiceSource fromJson(String json) =>
      $enumDecode(_$ServiceSourceEnumMap, json);
}

@freezed
abstract class UserData with _$UserData {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: .screamingSnake)
  const factory UserData({
    @Default(ServiceSource.bilibili) ServiceSource serviceSource,
    @Default(ThemeConfig.followSystem) ThemeConfig themeConfig,
    @Default(true) bool useDynamicColor,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
