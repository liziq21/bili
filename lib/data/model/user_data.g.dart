// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserData _$UserDataFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_UserData',
  json,
  ($checkedConvert) {
    final val = _UserData(
      serviceSource: $checkedConvert(
        'SERVICE_SOURCE',
        (v) => $enumDecodeNullable(_$ServiceSourceEnumMap, v) ?? .bilibili,
      ),
      themeConfig: $checkedConvert(
        'THEME_CONFIG',
        (v) => $enumDecodeNullable(_$ThemeConfigEnumMap, v) ?? .followSystem,
      ),
      useDynamicColor: $checkedConvert(
        'USE_DYNAMIC_COLOR',
        (v) => v as bool? ?? true,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'serviceSource': 'SERVICE_SOURCE',
    'themeConfig': 'THEME_CONFIG',
    'useDynamicColor': 'USE_DYNAMIC_COLOR',
  },
);

const _$ServiceSourceEnumMap = {
  ServiceSource.bilibili: 'BILIBILI',
  ServiceSource.youtube: 'YOUTUBE',
};

const _$ThemeConfigEnumMap = {
  ThemeConfig.followSystem: 'FOLLOW_SYSTEM',
  ThemeConfig.light: 'LIGHT',
  ThemeConfig.dark: 'DARK',
};
