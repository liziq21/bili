import 'package:json_annotation/json_annotation.dart';

part 'theme_config.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: .screamingSnake)
enum ThemeConfig {
  followSystem,
  light,
  dark;

  String toJson() => _$ThemeConfigEnumMap[this]!;

  static ThemeConfig fromJson(String json) =>
      $enumDecode(_$ThemeConfigEnumMap, json);
}
