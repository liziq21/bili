// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_search_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecentSearchQuery {

 String get query; DateTime get queriedDate;
/// Create a copy of RecentSearchQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentSearchQueryCopyWith<RecentSearchQuery> get copyWith => _$RecentSearchQueryCopyWithImpl<RecentSearchQuery>(this as RecentSearchQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentSearchQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.queriedDate, queriedDate) || other.queriedDate == queriedDate));
}


@override
int get hashCode => Object.hash(runtimeType,query,queriedDate);

@override
String toString() {
  return 'RecentSearchQuery(query: $query, queriedDate: $queriedDate)';
}


}

/// @nodoc
abstract mixin class $RecentSearchQueryCopyWith<$Res>  {
  factory $RecentSearchQueryCopyWith(RecentSearchQuery value, $Res Function(RecentSearchQuery) _then) = _$RecentSearchQueryCopyWithImpl;
@useResult
$Res call({
 String query, DateTime queriedDate
});




}
/// @nodoc
class _$RecentSearchQueryCopyWithImpl<$Res>
    implements $RecentSearchQueryCopyWith<$Res> {
  _$RecentSearchQueryCopyWithImpl(this._self, this._then);

  final RecentSearchQuery _self;
  final $Res Function(RecentSearchQuery) _then;

/// Create a copy of RecentSearchQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? queriedDate = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,queriedDate: null == queriedDate ? _self.queriedDate : queriedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}



/// @nodoc


class _RecentSearchQuery implements RecentSearchQuery {
  const _RecentSearchQuery({required this.query, required this.queriedDate});
  

@override final  String query;
@override final  DateTime queriedDate;

/// Create a copy of RecentSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentSearchQueryCopyWith<_RecentSearchQuery> get copyWith => __$RecentSearchQueryCopyWithImpl<_RecentSearchQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentSearchQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.queriedDate, queriedDate) || other.queriedDate == queriedDate));
}


@override
int get hashCode => Object.hash(runtimeType,query,queriedDate);

@override
String toString() {
  return 'RecentSearchQuery(query: $query, queriedDate: $queriedDate)';
}


}

/// @nodoc
abstract mixin class _$RecentSearchQueryCopyWith<$Res> implements $RecentSearchQueryCopyWith<$Res> {
  factory _$RecentSearchQueryCopyWith(_RecentSearchQuery value, $Res Function(_RecentSearchQuery) _then) = __$RecentSearchQueryCopyWithImpl;
@override @useResult
$Res call({
 String query, DateTime queriedDate
});




}
/// @nodoc
class __$RecentSearchQueryCopyWithImpl<$Res>
    implements _$RecentSearchQueryCopyWith<$Res> {
  __$RecentSearchQueryCopyWithImpl(this._self, this._then);

  final _RecentSearchQuery _self;
  final $Res Function(_RecentSearchQuery) _then;

/// Create a copy of RecentSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? queriedDate = null,}) {
  return _then(_RecentSearchQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,queriedDate: null == queriedDate ? _self.queriedDate : queriedDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
