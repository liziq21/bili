// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkSearch {

 int get page; int get pagesize; int get numResults; int get numPages;@JsonKey(fromJson: _pageinfoMapFromJson) Map<SearchResultType, NetworkPageinfo>? get pageinfo;@JsonKey(fromJson: _resultMapFromJson) Map<SearchResultType, List<NetworkSearchResult>?> get result;
/// Create a copy of NetworkSearch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchCopyWith<NetworkSearch> get copyWith => _$NetworkSearchCopyWithImpl<NetworkSearch>(this as NetworkSearch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearch&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other.pageinfo, pageinfo)&&const DeepCollectionEquality().equals(other.result, result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(pageinfo),const DeepCollectionEquality().hash(result));

@override
String toString() {
  return 'NetworkSearch(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo, result: $result)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchCopyWith<$Res>  {
  factory $NetworkSearchCopyWith(NetworkSearch value, $Res Function(NetworkSearch) _then) = _$NetworkSearchCopyWithImpl;
@useResult
$Res call({
 int page, int pagesize, int numResults, int numPages,@JsonKey(fromJson: _pageinfoMapFromJson) Map<SearchResultType, NetworkPageinfo>? pageinfo,@JsonKey(fromJson: _resultMapFromJson) Map<SearchResultType, List<NetworkSearchResult>?> result
});




}
/// @nodoc
class _$NetworkSearchCopyWithImpl<$Res>
    implements $NetworkSearchCopyWith<$Res> {
  _$NetworkSearchCopyWithImpl(this._self, this._then);

  final NetworkSearch _self;
  final $Res Function(NetworkSearch) _then;

/// Create a copy of NetworkSearch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,Object? result = null,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pagesize: null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,pageinfo: freezed == pageinfo ? _self.pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, NetworkPageinfo>?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, List<NetworkSearchResult>?>,
  ));
}

}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkSearch implements NetworkSearch {
  const _NetworkSearch(this.page, this.pagesize, this.numResults, this.numPages, @JsonKey(fromJson: _pageinfoMapFromJson) final  Map<SearchResultType, NetworkPageinfo>? pageinfo, @JsonKey(fromJson: _resultMapFromJson) final  Map<SearchResultType, List<NetworkSearchResult>?> result): _pageinfo = pageinfo,_result = result;
  factory _NetworkSearch.fromJson(Map<String, dynamic> json) => _$NetworkSearchFromJson(json);

@override final  int page;
@override final  int pagesize;
@override final  int numResults;
@override final  int numPages;
 final  Map<SearchResultType, NetworkPageinfo>? _pageinfo;
@override@JsonKey(fromJson: _pageinfoMapFromJson) Map<SearchResultType, NetworkPageinfo>? get pageinfo {
  final value = _pageinfo;
  if (value == null) return null;
  if (_pageinfo is EqualUnmodifiableMapView) return _pageinfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<SearchResultType, List<NetworkSearchResult>?> _result;
@override@JsonKey(fromJson: _resultMapFromJson) Map<SearchResultType, List<NetworkSearchResult>?> get result {
  if (_result is EqualUnmodifiableMapView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_result);
}


/// Create a copy of NetworkSearch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchCopyWith<_NetworkSearch> get copyWith => __$NetworkSearchCopyWithImpl<_NetworkSearch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearch&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other._pageinfo, _pageinfo)&&const DeepCollectionEquality().equals(other._result, _result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(_pageinfo),const DeepCollectionEquality().hash(_result));

@override
String toString() {
  return 'NetworkSearch(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo, result: $result)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchCopyWith<$Res> implements $NetworkSearchCopyWith<$Res> {
  factory _$NetworkSearchCopyWith(_NetworkSearch value, $Res Function(_NetworkSearch) _then) = __$NetworkSearchCopyWithImpl;
@override @useResult
$Res call({
 int page, int pagesize, int numResults, int numPages,@JsonKey(fromJson: _pageinfoMapFromJson) Map<SearchResultType, NetworkPageinfo>? pageinfo,@JsonKey(fromJson: _resultMapFromJson) Map<SearchResultType, List<NetworkSearchResult>?> result
});




}
/// @nodoc
class __$NetworkSearchCopyWithImpl<$Res>
    implements _$NetworkSearchCopyWith<$Res> {
  __$NetworkSearchCopyWithImpl(this._self, this._then);

  final _NetworkSearch _self;
  final $Res Function(_NetworkSearch) _then;

/// Create a copy of NetworkSearch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,Object? result = null,}) {
  return _then(_NetworkSearch(
null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,freezed == pageinfo ? _self._pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, NetworkPageinfo>?,null == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, List<NetworkSearchResult>?>,
  ));
}


}


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
  const _NetworkPageinfo(this.total, this.numResults, this.pages);
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
null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
