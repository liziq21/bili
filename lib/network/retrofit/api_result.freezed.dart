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
ApiResult<T> _$ApiResultFromJson<T>(
  Map<String, dynamic> json,T Function(Object?) fromJsonT
) {
        switch (json['runtimeType']) {
                  case 'ok':
          return ApiResultOk<T>.fromJson(
            json,fromJsonT
          );
                case 'error':
          return ApiResultError<T>.fromJson(
            json,fromJsonT
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ApiResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$ApiResult<T> implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResult<T>);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>()';
}


}

/// @nodoc
class $ApiResultCopyWith<T,$Res>  {
$ApiResultCopyWith(ApiResult<T> _, $Res Function(ApiResult<T>) __);
}



/// @nodoc
@JsonSerializable(createToJson: false,genericArgumentFactories: true)

class ApiResultOk<T> with DiagnosticableTreeMixin implements ApiResult<T> {
  const ApiResultOk(this.data, {final  String? $type}): $type = $type ?? 'ok';
  factory ApiResultOk.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ApiResultOkFromJson(json,fromJsonT);

 final  T data;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultOkCopyWith<T, ApiResultOk<T>> get copyWith => _$ApiResultOkCopyWithImpl<T, ApiResultOk<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>.ok'))
    ..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResultOk<T>&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>.ok(data: $data)';
}


}

/// @nodoc
abstract mixin class $ApiResultOkCopyWith<T,$Res> implements $ApiResultCopyWith<T, $Res> {
  factory $ApiResultOkCopyWith(ApiResultOk<T> value, $Res Function(ApiResultOk<T>) _then) = _$ApiResultOkCopyWithImpl;
@useResult
$Res call({
 T data
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
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(ApiResultOk<T>(
freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc
@JsonSerializable(createToJson: false,genericArgumentFactories: true)

class ApiResultError<T> with DiagnosticableTreeMixin implements ApiResult<T> {
  const ApiResultError(this.code, this.message, this.ttl, {final  String? $type}): $type = $type ?? 'error';
  factory ApiResultError.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ApiResultErrorFromJson(json,fromJsonT);

 final  int code;
 final  String message;
 final  int ttl;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultErrorCopyWith<T, ApiResultError<T>> get copyWith => _$ApiResultErrorCopyWithImpl<T, ApiResultError<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ApiResult<$T>.error'))
    ..add(DiagnosticsProperty('code', code))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('ttl', ttl));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResultError<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.ttl, ttl) || other.ttl == ttl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,ttl);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ApiResult<$T>.error(code: $code, message: $message, ttl: $ttl)';
}


}

/// @nodoc
abstract mixin class $ApiResultErrorCopyWith<T,$Res> implements $ApiResultCopyWith<T, $Res> {
  factory $ApiResultErrorCopyWith(ApiResultError<T> value, $Res Function(ApiResultError<T>) _then) = _$ApiResultErrorCopyWithImpl;
@useResult
$Res call({
 int code, String message, int ttl
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
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? ttl = null,}) {
  return _then(ApiResultError<T>(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
