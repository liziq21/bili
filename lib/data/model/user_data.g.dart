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
      themeConfig: $checkedConvert(
        'THEME_CONFIG',
        (v) =>
            $enumDecodeNullable(_$ThemeConfigEnumMap, v) ??
            ThemeConfig.followSystem,
      ),
      useDynamicColor: $checkedConvert(
        'USE_DYNAMIC_COLOR',
        (v) => v as bool? ?? true,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'themeConfig': 'THEME_CONFIG',
    'useDynamicColor': 'USE_DYNAMIC_COLOR',
  },
);

const _$ThemeConfigEnumMap = {
  ThemeConfig.followSystem: 'FOLLOW_SYSTEM',
  ThemeConfig.light: 'LIGHT',
  ThemeConfig.dark: 'DARK',
};
