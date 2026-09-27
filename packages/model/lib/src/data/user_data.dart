import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'theme_config.dart';

part 'user_data.g.dart';

@JsonSerializable(fieldRename: .screamingSnake, createToJson: true)
class const UserData({
  // 写死的服务身份，违反 app/docs/design-system.md 的 R8「服务源无关性」。
  // 此处是真正生效的那一处默认值：SharedPreferences 无 SOURCE_ID 时，
  // 生成的 _$UserDataFromJson 以 `?? 'bilibili'` 读到的就是它。
  // 同值另有一处 app/lib/datastore/preferences_data_source.dart 的
  // PreferencesKey.sourceId（实测不可达），迁移时两处需同时处理。
  // 跨层依赖与 static const 的求值限制见该文件注释。
  final String sourceId = 'bilibili',
  final ThemeConfig themeConfig = ThemeConfig.followSystem,
  final bool useDynamicColor = true,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

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
