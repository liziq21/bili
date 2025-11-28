// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiResult<T> implements DiagnosticableTreeMixin {

 int get code; String get message; int get ttl; T get data;
/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultCopyWith<T, ApiResult<T>> get copyWith => _$ApiResultCopyWithImpl<T, ApiResult<T>>(this as ApiResult<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>'))
    ..add(DiagnosticsProperty('code', code))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('ttl', ttl))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResult<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,ttl,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>(code: $code, message: $message, ttl: $ttl, data: $data)';
}


}

/// @nodoc
abstract mixin class $ApiResultCopyWith<T,$Res>  {
  factory $ApiResultCopyWith(ApiResult<T> value, $Res Function(ApiResult<T>) _then) = _$ApiResultCopyWithImpl;
@useResult
$Res call({
 int code, String message, int ttl, T data
});




}
/// @nodoc
class _$ApiResultCopyWithImpl<T,$Res>
    implements $ApiResultCopyWith<T, $Res> {
  _$ApiResultCopyWithImpl(this._self, this._then);

  final ApiResult<T> _self;
  final $Res Function(ApiResult<T>) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? ttl = null,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false,genericArgumentFactories: true)

class _ApiResult<T> with DiagnosticableTreeMixin implements ApiResult<T> {
  const _ApiResult(this.code, this.message, this.ttl, this.data);
  factory _ApiResult.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ApiResultFromJson(json,fromJsonT);

@override final  int code;
@override final  String message;
@override final  int ttl;
@override final  T data;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiResultCopyWith<T, _ApiResult<T>> get copyWith => __$ApiResultCopyWithImpl<T, _ApiResult<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>'))
    ..add(DiagnosticsProperty('code', code))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('ttl', ttl))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiResult<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,ttl,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>(code: $code, message: $message, ttl: $ttl, data: $data)';
}


}

/// @nodoc
abstract mixin class _$ApiResultCopyWith<T,$Res> implements $ApiResultCopyWith<T, $Res> {
  factory _$ApiResultCopyWith(_ApiResult<T> value, $Res Function(_ApiResult<T>) _then) = __$ApiResultCopyWithImpl;
@override @useResult
$Res call({
 int code, String message, int ttl, T data
});




}
/// @nodoc
class __$ApiResultCopyWithImpl<T,$Res>
    implements _$ApiResultCopyWith<T, $Res> {
  __$ApiResultCopyWithImpl(this._self, this._then);

  final _ApiResult<T> _self;
  final $Res Function(_ApiResult<T>) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? ttl = null,Object? data = freezed,}) {
  return _then(_ApiResult<T>(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

// dart format on
