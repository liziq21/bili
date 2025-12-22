// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserData {

 ThemeConfig get themeConfig; bool get useDynamicColor;
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataCopyWith<UserData> get copyWith => _$UserDataCopyWithImpl<UserData>(this as UserData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserData&&(identical(other.themeConfig, themeConfig) || other.themeConfig == themeConfig)&&(identical(other.useDynamicColor, useDynamicColor) || other.useDynamicColor == useDynamicColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeConfig,useDynamicColor);

@override
String toString() {
  return 'UserData(themeConfig: $themeConfig, useDynamicColor: $useDynamicColor)';
}


}

/// @nodoc
abstract mixin class $UserDataCopyWith<$Res>  {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) _then) = _$UserDataCopyWithImpl;
@useResult
$Res call({
 ThemeConfig themeConfig, bool useDynamicColor
});




}
/// @nodoc
class _$UserDataCopyWithImpl<$Res>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._self, this._then);

  final UserData _self;
  final $Res Function(UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeConfig = null,Object? useDynamicColor = null,}) {
  return _then(_self.copyWith(
themeConfig: null == themeConfig ? _self.themeConfig : themeConfig // ignore: cast_nullable_to_non_nullable
as ThemeConfig,useDynamicColor: null == useDynamicColor ? _self.useDynamicColor : useDynamicColor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}



/// @nodoc

@JsonSerializable(fieldRename: .screamingSnake)
class _UserData implements UserData {
  const _UserData({this.themeConfig = ThemeConfig.followSystem, this.useDynamicColor = true});
  factory _UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

@override@JsonKey() final  ThemeConfig themeConfig;
@override@JsonKey() final  bool useDynamicColor;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataCopyWith<_UserData> get copyWith => __$UserDataCopyWithImpl<_UserData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserData&&(identical(other.themeConfig, themeConfig) || other.themeConfig == themeConfig)&&(identical(other.useDynamicColor, useDynamicColor) || other.useDynamicColor == useDynamicColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeConfig,useDynamicColor);

@override
String toString() {
  return 'UserData(themeConfig: $themeConfig, useDynamicColor: $useDynamicColor)';
}


}

/// @nodoc
abstract mixin class _$UserDataCopyWith<$Res> implements $UserDataCopyWith<$Res> {
  factory _$UserDataCopyWith(_UserData value, $Res Function(_UserData) _then) = __$UserDataCopyWithImpl;
@override @useResult
$Res call({
 ThemeConfig themeConfig, bool useDynamicColor
});




}
/// @nodoc
class __$UserDataCopyWithImpl<$Res>
    implements _$UserDataCopyWith<$Res> {
  __$UserDataCopyWithImpl(this._self, this._then);

  final _UserData _self;
  final $Res Function(_UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeConfig = null,Object? useDynamicColor = null,}) {
  return _then(_UserData(
themeConfig: null == themeConfig ? _self.themeConfig : themeConfig // ignore: cast_nullable_to_non_nullable
as ThemeConfig,useDynamicColor: null == useDynamicColor ? _self.useDynamicColor : useDynamicColor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
