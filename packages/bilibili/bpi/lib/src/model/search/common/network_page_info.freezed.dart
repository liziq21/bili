// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_page_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkPageinfo {

 int get total; int get numResults; int get pages;
/// Create a copy of NetworkPageinfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkPageinfoCopyWith<NetworkPageinfo> get copyWith => _$NetworkPageinfoCopyWithImpl<NetworkPageinfo>(this as NetworkPageinfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkPageinfo&&(identical(other.total, total) || other.total == total)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,numResults,pages);

@override
String toString() {
  return 'NetworkPageinfo(total: $total, numResults: $numResults, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $NetworkPageinfoCopyWith<$Res>  {
  factory $NetworkPageinfoCopyWith(NetworkPageinfo value, $Res Function(NetworkPageinfo) _then) = _$NetworkPageinfoCopyWithImpl;
@useResult
$Res call({
 int total, int numResults, int pages
});




}
/// @nodoc
class _$NetworkPageinfoCopyWithImpl<$Res>
    implements $NetworkPageinfoCopyWith<$Res> {
  _$NetworkPageinfoCopyWithImpl(this._self, this._then);

  final NetworkPageinfo _self;
  final $Res Function(NetworkPageinfo) _then;

/// Create a copy of NetworkPageinfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? numResults = null,Object? pages = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkPageinfo implements NetworkPageinfo {
  const _NetworkPageinfo({required this.total, required this.numResults, required this.pages});
  factory _NetworkPageinfo.fromJson(Map<String, dynamic> json) => _$NetworkPageinfoFromJson(json);

@override final  int total;
@override final  int numResults;
@override final  int pages;

/// Create a copy of NetworkPageinfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkPageinfoCopyWith<_NetworkPageinfo> get copyWith => __$NetworkPageinfoCopyWithImpl<_NetworkPageinfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkPageinfo&&(identical(other.total, total) || other.total == total)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,numResults,pages);

@override
String toString() {
  return 'NetworkPageinfo(total: $total, numResults: $numResults, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$NetworkPageinfoCopyWith<$Res> implements $NetworkPageinfoCopyWith<$Res> {
  factory _$NetworkPageinfoCopyWith(_NetworkPageinfo value, $Res Function(_NetworkPageinfo) _then) = __$NetworkPageinfoCopyWithImpl;
@override @useResult
$Res call({
 int total, int numResults, int pages
});




}
/// @nodoc
class __$NetworkPageinfoCopyWithImpl<$Res>
    implements _$NetworkPageinfoCopyWith<$Res> {
  __$NetworkPageinfoCopyWithImpl(this._self, this._then);

  final _NetworkPageinfo _self;
  final $Res Function(_NetworkPageinfo) _then;

/// Create a copy of NetworkPageinfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? numResults = null,Object? pages = null,}) {
  return _then(_NetworkPageinfo(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
