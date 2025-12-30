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

 int get code;
/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultCopyWith<T, ApiResult<T>> get copyWith => _$ApiResultCopyWithImpl<T, ApiResult<T>>(this as ApiResult<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>'))
    ..add(DiagnosticsProperty('code', code));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResult<T>&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>(code: $code)';
}


}

/// @nodoc
abstract mixin class $ApiResultCopyWith<T,$Res>  {
  factory $ApiResultCopyWith(ApiResult<T> value, $Res Function(ApiResult<T>) _then) = _$ApiResultCopyWithImpl;
@useResult
$Res call({
 int code
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
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc


class ApiResultOk<T> with DiagnosticableTreeMixin implements ApiResult<T> {
  const ApiResultOk({required this.code, required this.data});
  

@override final  int code;
 final  T data;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultOkCopyWith<T, ApiResultOk<T>> get copyWith => _$ApiResultOkCopyWithImpl<T, ApiResultOk<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>.ok'))
    ..add(DiagnosticsProperty('code', code))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResultOk<T>&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,code,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>.ok(code: $code, data: $data)';
}


}

/// @nodoc
abstract mixin class $ApiResultOkCopyWith<T,$Res> implements $ApiResultCopyWith<T, $Res> {
  factory $ApiResultOkCopyWith(ApiResultOk<T> value, $Res Function(ApiResultOk<T>) _then) = _$ApiResultOkCopyWithImpl;
@override @useResult
$Res call({
 int code, T data
});




}
/// @nodoc
class _$ApiResultOkCopyWithImpl<T,$Res>
    implements $ApiResultOkCopyWith<T, $Res> {
  _$ApiResultOkCopyWithImpl(this._self, this._then);

  final ApiResultOk<T> _self;
  final $Res Function(ApiResultOk<T>) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? data = freezed,}) {
  return _then(ApiResultOk<T>(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class ApiResultError<T> with DiagnosticableTreeMixin implements ApiResult<T> {
  const ApiResultError({required this.code, this.message});
  

@override final  int code;
 final  String? message;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultErrorCopyWith<T, ApiResultError<T>> get copyWith => _$ApiResultErrorCopyWithImpl<T, ApiResultError<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>.error'))
    ..add(DiagnosticsProperty('code', code))..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResultError<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>.error(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiResultErrorCopyWith<T,$Res> implements $ApiResultCopyWith<T, $Res> {
  factory $ApiResultErrorCopyWith(ApiResultError<T> value, $Res Function(ApiResultError<T>) _then) = _$ApiResultErrorCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message
});




}
/// @nodoc
class _$ApiResultErrorCopyWithImpl<T,$Res>
    implements $ApiResultErrorCopyWith<T, $Res> {
  _$ApiResultErrorCopyWithImpl(this._self, this._then);

  final ApiResultError<T> _self;
  final $Res Function(ApiResultError<T>) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,}) {
  return _then(ApiResultError<T>(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
