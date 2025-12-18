import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

enum ThemeConfig {
  followSystem,
  light,
  dark,
}

@freezed
abstract class UserData with _$UserData {
  const factory UserData({
    @Default(.followSystem) ThemeConfig themeConfig,
    @Default(true) bool useDynamicColor,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}

