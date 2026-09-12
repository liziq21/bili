import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'theme_config.dart';

part 'user_data.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: .screamingSnake)
enum ServiceSource {
  bilibili,
  youtube;

  String toJson() => _$ServiceSourceEnumMap[this]!;

  static ServiceSource fromJson(String json) =>
      $enumDecode(_$ServiceSourceEnumMap, json);
}

@JsonSerializable(fieldRename: .screamingSnake)
class UserData extends Equatable {
  const UserData({
    this.serviceSource = ServiceSource.bilibili,
    this.themeConfig = ThemeConfig.followSystem,
    this.useDynamicColor = true,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  final ServiceSource serviceSource;
  final ThemeConfig themeConfig;
  final bool useDynamicColor;

  Map<String, dynamic> toJson() => _$UserDataToJson(this);

  UserData copyWith({
    ServiceSource? serviceSource,
    ThemeConfig? themeConfig,
    bool? useDynamicColor,
  }) {
    return UserData(
      serviceSource: serviceSource ?? this.serviceSource,
      themeConfig: themeConfig ?? this.themeConfig,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  @override
  List<Object?> get props => [serviceSource, themeConfig, useDynamicColor];
}
