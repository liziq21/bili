import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'theme_config.dart';

part 'user_data.g.dart';

@JsonSerializable(fieldRename: .screamingSnake, createToJson: true)
class UserData extends Equatable {
  const UserData({
    this.sourceId = 'bilibili',
    this.themeConfig = ThemeConfig.followSystem,
    this.useDynamicColor = true,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  final String sourceId;
  final ThemeConfig themeConfig;
  final bool useDynamicColor;

  Map<String, dynamic> toJson() => _$UserDataToJson(this);

  UserData copyWith({
    String? sourceId,
    ThemeConfig? themeConfig,
    bool? useDynamicColor,
  }) {
    return UserData(
      sourceId: sourceId ?? this.sourceId,
      themeConfig: themeConfig ?? this.themeConfig,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  @override
  List<Object?> get props => [sourceId, themeConfig, useDynamicColor];
}
