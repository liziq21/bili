// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'http_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HttpError {

 String get code; String get message; String? get stack;
/// Create a copy of HttpError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpErrorCopyWith<HttpError> get copyWith => _$HttpErrorCopyWithImpl<HttpError>(this as HttpError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.stack, stack) || other.stack == stack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,stack);

@override
String toString() {
  return 'HttpError(code: $code, message: $message, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $HttpErrorCopyWith<$Res>  {
  factory $HttpErrorCopyWith(HttpError value, $Res Function(HttpError) _then) = _$HttpErrorCopyWithImpl;
@useResult
$Res call({
 String code, String message, String? stack
});




}
/// @nodoc
class _$HttpErrorCopyWithImpl<$Res>
    implements $HttpErrorCopyWith<$Res> {
  _$HttpErrorCopyWithImpl(this._self, this._then);

  final HttpError _self;
  final $Res Function(HttpError) _then;

/// Create a copy of HttpError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? stack = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stack: freezed == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _HttpError implements HttpError {
  const _HttpError({this.code = "ERROR", required this.message, required this.stack});
  factory _HttpError.fromJson(Map<String, dynamic> json) => _$HttpErrorFromJson(json);

@override@JsonKey() final  String code;
@override final  String message;
@override final  String? stack;

/// Create a copy of HttpError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HttpErrorCopyWith<_HttpError> get copyWith => __$HttpErrorCopyWithImpl<_HttpError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HttpError&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.stack, stack) || other.stack == stack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,stack);

@override
String toString() {
  return 'HttpError(code: $code, message: $message, stack: $stack)';
}


}

/// @nodoc
abstract mixin class _$HttpErrorCopyWith<$Res> implements $HttpErrorCopyWith<$Res> {
  factory _$HttpErrorCopyWith(_HttpError value, $Res Function(_HttpError) _then) = __$HttpErrorCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, String? stack
});




}
/// @nodoc
class __$HttpErrorCopyWithImpl<$Res>
    implements _$HttpErrorCopyWith<$Res> {
  __$HttpErrorCopyWithImpl(this._self, this._then);

  final _HttpError _self;
  final $Res Function(_HttpError) _then;

/// Create a copy of HttpError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? stack = freezed,}) {
  return _then(_HttpError(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stack: freezed == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
