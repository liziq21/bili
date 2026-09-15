// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserData',
  json,
  ($checkedConvert) {
    final val = UserData(
      sourceId: $checkedConvert('SOURCE_ID', (v) => v as String? ?? 'bilibili'),
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
    'sourceId': 'SOURCE_ID',
    'themeConfig': 'THEME_CONFIG',
    'useDynamicColor': 'USE_DYNAMIC_COLOR',
  },
);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'SOURCE_ID': instance.sourceId,
  'THEME_CONFIG': instance.themeConfig,
  'USE_DYNAMIC_COLOR': instance.useDynamicColor,
};

const _$ThemeConfigEnumMap = {
  ThemeConfig.followSystem: 'FOLLOW_SYSTEM',
  ThemeConfig.light: 'LIGHT',
  ThemeConfig.dark: 'DARK',
};
