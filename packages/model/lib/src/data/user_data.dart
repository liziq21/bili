import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'theme_config.dart';

part 'user_data.g.dart';

@JsonSerializable(fieldRename: .screamingSnake, createToJson: true)
class const UserData({
  /// 用户选择的服务源标识，null 表示尚未选择过。
  ///
  /// 取值由 app 层决定（见 HomeBloc 的解析点），model 层不绑定任何服务名，
  /// 满足 app/docs/design-system.md 的 R8「服务源无关性」。
  final String? sourceId,
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
