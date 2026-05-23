// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_search_suggest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkSearchSuggest {

 List<NetworkSearchSuggestItem> get tag;
/// Create a copy of NetworkSearchSuggest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchSuggestCopyWith<NetworkSearchSuggest> get copyWith => _$NetworkSearchSuggestCopyWithImpl<NetworkSearchSuggest>(this as NetworkSearchSuggest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchSuggest&&const DeepCollectionEquality().equals(other.tag, tag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tag));

@override
String toString() {
  return 'NetworkSearchSuggest(tag: $tag)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchSuggestCopyWith<$Res>  {
  factory $NetworkSearchSuggestCopyWith(NetworkSearchSuggest value, $Res Function(NetworkSearchSuggest) _then) = _$NetworkSearchSuggestCopyWithImpl;
@useResult
$Res call({
 List<NetworkSearchSuggestItem> tag
});




}
/// @nodoc
class _$NetworkSearchSuggestCopyWithImpl<$Res>
    implements $NetworkSearchSuggestCopyWith<$Res> {
  _$NetworkSearchSuggestCopyWithImpl(this._self, this._then);

  final NetworkSearchSuggest _self;
  final $Res Function(NetworkSearchSuggest) _then;

/// Create a copy of NetworkSearchSuggest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tag = null,}) {
  return _then(_self.copyWith(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as List<NetworkSearchSuggestItem>,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkSearchSuggest implements NetworkSearchSuggest {
  const _NetworkSearchSuggest({required final  List<NetworkSearchSuggestItem> tag}): _tag = tag;
  factory _NetworkSearchSuggest.fromJson(Map<String, dynamic> json) => _$NetworkSearchSuggestFromJson(json);

 final  List<NetworkSearchSuggestItem> _tag;
@override List<NetworkSearchSuggestItem> get tag {
  if (_tag is EqualUnmodifiableListView) return _tag;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tag);
}


/// Create a copy of NetworkSearchSuggest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchSuggestCopyWith<_NetworkSearchSuggest> get copyWith => __$NetworkSearchSuggestCopyWithImpl<_NetworkSearchSuggest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearchSuggest&&const DeepCollectionEquality().equals(other._tag, _tag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tag));

@override
String toString() {
  return 'NetworkSearchSuggest(tag: $tag)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchSuggestCopyWith<$Res> implements $NetworkSearchSuggestCopyWith<$Res> {
  factory _$NetworkSearchSuggestCopyWith(_NetworkSearchSuggest value, $Res Function(_NetworkSearchSuggest) _then) = __$NetworkSearchSuggestCopyWithImpl;
@override @useResult
$Res call({
 List<NetworkSearchSuggestItem> tag
});




}
/// @nodoc
class __$NetworkSearchSuggestCopyWithImpl<$Res>
    implements _$NetworkSearchSuggestCopyWith<$Res> {
  __$NetworkSearchSuggestCopyWithImpl(this._self, this._then);

  final _NetworkSearchSuggest _self;
  final $Res Function(_NetworkSearchSuggest) _then;

/// Create a copy of NetworkSearchSuggest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tag = null,}) {
  return _then(_NetworkSearchSuggest(
tag: null == tag ? _self._tag : tag // ignore: cast_nullable_to_non_nullable
as List<NetworkSearchSuggestItem>,
  ));
}


}


/// @nodoc
mixin _$NetworkSearchSuggestItem {

 String get term; String get name;
/// Create a copy of NetworkSearchSuggestItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchSuggestItemCopyWith<NetworkSearchSuggestItem> get copyWith => _$NetworkSearchSuggestItemCopyWithImpl<NetworkSearchSuggestItem>(this as NetworkSearchSuggestItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchSuggestItem&&(identical(other.term, term) || other.term == term)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,name);

@override
String toString() {
  return 'NetworkSearchSuggestItem(term: $term, name: $name)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchSuggestItemCopyWith<$Res>  {
  factory $NetworkSearchSuggestItemCopyWith(NetworkSearchSuggestItem value, $Res Function(NetworkSearchSuggestItem) _then) = _$NetworkSearchSuggestItemCopyWithImpl;
@useResult
$Res call({
 String term, String name
});




}
/// @nodoc
class _$NetworkSearchSuggestItemCopyWithImpl<$Res>
    implements $NetworkSearchSuggestItemCopyWith<$Res> {
  _$NetworkSearchSuggestItemCopyWithImpl(this._self, this._then);

  final NetworkSearchSuggestItem _self;
  final $Res Function(NetworkSearchSuggestItem) _then;

/// Create a copy of NetworkSearchSuggestItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? name = null,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkSearchSuggestItem implements NetworkSearchSuggestItem {
  const _NetworkSearchSuggestItem({required this.term, required this.name});
  factory _NetworkSearchSuggestItem.fromJson(Map<String, dynamic> json) => _$NetworkSearchSuggestItemFromJson(json);

@override final  String term;
@override final  String name;

/// Create a copy of NetworkSearchSuggestItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchSuggestItemCopyWith<_NetworkSearchSuggestItem> get copyWith => __$NetworkSearchSuggestItemCopyWithImpl<_NetworkSearchSuggestItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearchSuggestItem&&(identical(other.term, term) || other.term == term)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,name);

@override
String toString() {
  return 'NetworkSearchSuggestItem(term: $term, name: $name)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchSuggestItemCopyWith<$Res> implements $NetworkSearchSuggestItemCopyWith<$Res> {
  factory _$NetworkSearchSuggestItemCopyWith(_NetworkSearchSuggestItem value, $Res Function(_NetworkSearchSuggestItem) _then) = __$NetworkSearchSuggestItemCopyWithImpl;
@override @useResult
$Res call({
 String term, String name
});




}
/// @nodoc
class __$NetworkSearchSuggestItemCopyWithImpl<$Res>
    implements _$NetworkSearchSuggestItemCopyWith<$Res> {
  __$NetworkSearchSuggestItemCopyWithImpl(this._self, this._then);

  final _NetworkSearchSuggestItem _self;
  final $Res Function(_NetworkSearchSuggestItem) _then;

/// Create a copy of NetworkSearchSuggestItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? name = null,}) {
  return _then(_NetworkSearchSuggestItem(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
