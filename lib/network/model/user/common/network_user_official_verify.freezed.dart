// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_user_official_verify.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkUserOfficialVerify {

 int get type; String get desc;
/// Create a copy of NetworkUserOfficialVerify
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkUserOfficialVerifyCopyWith<NetworkUserOfficialVerify> get copyWith => _$NetworkUserOfficialVerifyCopyWithImpl<NetworkUserOfficialVerify>(this as NetworkUserOfficialVerify, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkUserOfficialVerify&&(identical(other.type, type) || other.type == type)&&(identical(other.desc, desc) || other.desc == desc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,desc);

@override
String toString() {
  return 'NetworkUserOfficialVerify(type: $type, desc: $desc)';
}


}

/// @nodoc
abstract mixin class $NetworkUserOfficialVerifyCopyWith<$Res>  {
  factory $NetworkUserOfficialVerifyCopyWith(NetworkUserOfficialVerify value, $Res Function(NetworkUserOfficialVerify) _then) = _$NetworkUserOfficialVerifyCopyWithImpl;
@useResult
$Res call({
 int type, String desc
});




}
/// @nodoc
class _$NetworkUserOfficialVerifyCopyWithImpl<$Res>
    implements $NetworkUserOfficialVerifyCopyWith<$Res> {
  _$NetworkUserOfficialVerifyCopyWithImpl(this._self, this._then);

  final NetworkUserOfficialVerify _self;
  final $Res Function(NetworkUserOfficialVerify) _then;

/// Create a copy of NetworkUserOfficialVerify
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? desc = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkUserOfficialVerify implements NetworkUserOfficialVerify {
  const _NetworkUserOfficialVerify({required this.type, required this.desc});
  factory _NetworkUserOfficialVerify.fromJson(Map<String, dynamic> json) => _$NetworkUserOfficialVerifyFromJson(json);

@override final  int type;
@override final  String desc;

/// Create a copy of NetworkUserOfficialVerify
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkUserOfficialVerifyCopyWith<_NetworkUserOfficialVerify> get copyWith => __$NetworkUserOfficialVerifyCopyWithImpl<_NetworkUserOfficialVerify>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkUserOfficialVerify&&(identical(other.type, type) || other.type == type)&&(identical(other.desc, desc) || other.desc == desc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,desc);

@override
String toString() {
  return 'NetworkUserOfficialVerify(type: $type, desc: $desc)';
}


}

/// @nodoc
abstract mixin class _$NetworkUserOfficialVerifyCopyWith<$Res> implements $NetworkUserOfficialVerifyCopyWith<$Res> {
  factory _$NetworkUserOfficialVerifyCopyWith(_NetworkUserOfficialVerify value, $Res Function(_NetworkUserOfficialVerify) _then) = __$NetworkUserOfficialVerifyCopyWithImpl;
@override @useResult
$Res call({
 int type, String desc
});




}
/// @nodoc
class __$NetworkUserOfficialVerifyCopyWithImpl<$Res>
    implements _$NetworkUserOfficialVerifyCopyWith<$Res> {
  __$NetworkUserOfficialVerifyCopyWithImpl(this._self, this._then);

  final _NetworkUserOfficialVerify _self;
  final $Res Function(_NetworkUserOfficialVerify) _then;

/// Create a copy of NetworkUserOfficialVerify
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? desc = null,}) {
  return _then(_NetworkUserOfficialVerify(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
