import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'theme_config.dart';

part 'user_data.g.dart';

@JsonSerializable(fieldRename: .screamingSnake, createToJson: true)
class const UserData({
  final String sourceId = 'bilibili',
  final ThemeConfig themeConfig = ThemeConfig.followSystem,
  final bool useDynamicColor = true,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

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
