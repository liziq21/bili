// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchResult {

 int get page; int get pagesize; int get numResults; int get numPages; Map<SearchResultType, String>? get pageinfo;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other.pageinfo, pageinfo));
}


@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(pageinfo));

@override
String toString() {
  return 'SearchResult(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo)';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 int page, int pagesize, int numResults, int numPages, Map<SearchResultType, String>? pageinfo
});




}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pagesize: null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,pageinfo: freezed == pageinfo ? _self.pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, String>?,
  ));
}

}



/// @nodoc


class _SearchResult implements SearchResult {
  const _SearchResult({required this.page, required this.pagesize, required this.numResults, required this.numPages, final  Map<SearchResultType, String>? pageinfo}): _pageinfo = pageinfo;
  

@override final  int page;
@override final  int pagesize;
@override final  int numResults;
@override final  int numPages;
 final  Map<SearchResultType, String>? _pageinfo;
@override Map<SearchResultType, String>? get pageinfo {
  final value = _pageinfo;
  if (value == null) return null;
  if (_pageinfo is EqualUnmodifiableMapView) return _pageinfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other._pageinfo, _pageinfo));
}


@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(_pageinfo));

@override
String toString() {
  return 'SearchResult(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 int page, int pagesize, int numResults, int numPages, Map<SearchResultType, String>? pageinfo
});




}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,}) {
  return _then(_SearchResult(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pagesize: null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,pageinfo: freezed == pageinfo ? _self._pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, String>?,
  ));
}


}

// dart format on
