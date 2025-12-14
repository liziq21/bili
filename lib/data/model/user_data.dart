import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

enum DarkThemeConfig {
  followSystem,
  light,
  dark,
}

@freezed
class UserData with _$UserData {
  const factory UserData({
    required DarkThemeConfig darkThemeConfig,
    required bool useDynamicColor,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);
}

