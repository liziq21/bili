// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
  serviceSource:
      $enumDecodeNullable(_$ServiceSourceEnumMap, json['SERVICE_SOURCE']) ??
      ServiceSource.bilibili,
  themeConfig:
      $enumDecodeNullable(_$ThemeConfigEnumMap, json['THEME_CONFIG']) ??
      ThemeConfig.followSystem,
  useDynamicColor: json['USE_DYNAMIC_COLOR'] as bool? ?? true,
);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'SERVICE_SOURCE': instance.serviceSource.toJson(),
  'THEME_CONFIG': instance.themeConfig.toJson(),
  'USE_DYNAMIC_COLOR': instance.useDynamicColor,
};

const _$ServiceSourceEnumMap = {
  ServiceSource.bilibili: 'BILIBILI',
  ServiceSource.youtube: 'YOUTUBE',
};

const _$ThemeConfigEnumMap = {
  ThemeConfig.followSystem: 'FOLLOW_SYSTEM',
  ThemeConfig.light: 'LIGHT',
  ThemeConfig.dark: 'DARK',
};
