// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkSearchResult {

 int get page; int get pagesize; int get numResults; int get numPages;@JsonKey(fromJson: _pageinfoFromJson) Map<SearchResultType, NetworkPageinfo>? get pageinfo; NetworkSearchResultWrapper get result;
/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchResultCopyWith<NetworkSearchResult> get copyWith => _$NetworkSearchResultCopyWithImpl<NetworkSearchResult>(this as NetworkSearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchResult&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other.pageinfo, pageinfo)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(pageinfo),result);

@override
String toString() {
  return 'NetworkSearchResult(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo, result: $result)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchResultCopyWith<$Res>  {
  factory $NetworkSearchResultCopyWith(NetworkSearchResult value, $Res Function(NetworkSearchResult) _then) = _$NetworkSearchResultCopyWithImpl;
@useResult
$Res call({
 int page, int pagesize, int numResults, int numPages,@JsonKey(fromJson: _pageinfoFromJson) Map<SearchResultType, NetworkPageinfo>? pageinfo, NetworkSearchResultWrapper result
});


$NetworkSearchResultWrapperCopyWith<$Res> get result;

}
/// @nodoc
class _$NetworkSearchResultCopyWithImpl<$Res>
    implements $NetworkSearchResultCopyWith<$Res> {
  _$NetworkSearchResultCopyWithImpl(this._self, this._then);

  final NetworkSearchResult _self;
  final $Res Function(NetworkSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,Object? result = null,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pagesize: null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,pageinfo: freezed == pageinfo ? _self.pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, NetworkPageinfo>?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NetworkSearchResultWrapper,
  ));
}
/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkSearchResultWrapperCopyWith<$Res> get result {
  
  return $NetworkSearchResultWrapperCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}



/// @nodoc
@JsonSerializable(createToJson: false)

class _NetworkSearchResult implements NetworkSearchResult {
  const _NetworkSearchResult({required this.page, required this.pagesize, required this.numResults, required this.numPages, @JsonKey(fromJson: _pageinfoFromJson) final  Map<SearchResultType, NetworkPageinfo>? pageinfo, required this.result}): _pageinfo = pageinfo;
  factory _NetworkSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkSearchResultFromJson(json);

@override final  int page;
@override final  int pagesize;
@override final  int numResults;
@override final  int numPages;
 final  Map<SearchResultType, NetworkPageinfo>? _pageinfo;
@override@JsonKey(fromJson: _pageinfoFromJson) Map<SearchResultType, NetworkPageinfo>? get pageinfo {
  final value = _pageinfo;
  if (value == null) return null;
  if (_pageinfo is EqualUnmodifiableMapView) return _pageinfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  NetworkSearchResultWrapper result;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchResultCopyWith<_NetworkSearchResult> get copyWith => __$NetworkSearchResultCopyWithImpl<_NetworkSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearchResult&&(identical(other.page, page) || other.page == page)&&(identical(other.pagesize, pagesize) || other.pagesize == pagesize)&&(identical(other.numResults, numResults) || other.numResults == numResults)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other._pageinfo, _pageinfo)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,pagesize,numResults,numPages,const DeepCollectionEquality().hash(_pageinfo),result);

@override
String toString() {
  return 'NetworkSearchResult(page: $page, pagesize: $pagesize, numResults: $numResults, numPages: $numPages, pageinfo: $pageinfo, result: $result)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory _$NetworkSearchResultCopyWith(_NetworkSearchResult value, $Res Function(_NetworkSearchResult) _then) = __$NetworkSearchResultCopyWithImpl;
@override @useResult
$Res call({
 int page, int pagesize, int numResults, int numPages,@JsonKey(fromJson: _pageinfoFromJson) Map<SearchResultType, NetworkPageinfo>? pageinfo, NetworkSearchResultWrapper result
});


@override $NetworkSearchResultWrapperCopyWith<$Res> get result;

}
/// @nodoc
class __$NetworkSearchResultCopyWithImpl<$Res>
    implements _$NetworkSearchResultCopyWith<$Res> {
  __$NetworkSearchResultCopyWithImpl(this._self, this._then);

  final _NetworkSearchResult _self;
  final $Res Function(_NetworkSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? pagesize = null,Object? numResults = null,Object? numPages = null,Object? pageinfo = freezed,Object? result = null,}) {
  return _then(_NetworkSearchResult(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pagesize: null == pagesize ? _self.pagesize : pagesize // ignore: cast_nullable_to_non_nullable
as int,numResults: null == numResults ? _self.numResults : numResults // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,pageinfo: freezed == pageinfo ? _self._pageinfo : pageinfo // ignore: cast_nullable_to_non_nullable
as Map<SearchResultType, NetworkPageinfo>?,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NetworkSearchResultWrapper,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkSearchResultWrapperCopyWith<$Res> get result {
  
  return $NetworkSearchResultWrapperCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
