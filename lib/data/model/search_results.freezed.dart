// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_results.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AllSearchResults {

 int get page; int get numPages; List<VideoInfoBase> get videos; CreatorProfile? get creatorProfile; List<VideoInfoBase>? get creatorProfileVideos;
/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllSearchResultsCopyWith<AllSearchResults> get copyWith => _$AllSearchResultsCopyWithImpl<AllSearchResults>(this as AllSearchResults, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllSearchResults&&(identical(other.page, page) || other.page == page)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other.videos, videos)&&(identical(other.creatorProfile, creatorProfile) || other.creatorProfile == creatorProfile)&&const DeepCollectionEquality().equals(other.creatorProfileVideos, creatorProfileVideos));
}


@override
int get hashCode => Object.hash(runtimeType,page,numPages,const DeepCollectionEquality().hash(videos),creatorProfile,const DeepCollectionEquality().hash(creatorProfileVideos));

@override
String toString() {
  return 'AllSearchResults(page: $page, numPages: $numPages, videos: $videos, creatorProfile: $creatorProfile, creatorProfileVideos: $creatorProfileVideos)';
}


}

/// @nodoc
abstract mixin class $AllSearchResultsCopyWith<$Res>  {
  factory $AllSearchResultsCopyWith(AllSearchResults value, $Res Function(AllSearchResults) _then) = _$AllSearchResultsCopyWithImpl;
@useResult
$Res call({
 int page, int numPages, List<VideoInfoBase> videos, CreatorProfile? creatorProfile, List<VideoInfoBase>? creatorProfileVideos
});


$CreatorProfileCopyWith<$Res>? get creatorProfile;

}
/// @nodoc
class _$AllSearchResultsCopyWithImpl<$Res>
    implements $AllSearchResultsCopyWith<$Res> {
  _$AllSearchResultsCopyWithImpl(this._self, this._then);

  final AllSearchResults _self;
  final $Res Function(AllSearchResults) _then;

/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? numPages = null,Object? videos = null,Object? creatorProfile = freezed,Object? creatorProfileVideos = freezed,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as List<VideoInfoBase>,creatorProfile: freezed == creatorProfile ? _self.creatorProfile : creatorProfile // ignore: cast_nullable_to_non_nullable
as CreatorProfile?,creatorProfileVideos: freezed == creatorProfileVideos ? _self.creatorProfileVideos : creatorProfileVideos // ignore: cast_nullable_to_non_nullable
as List<VideoInfoBase>?,
  ));
}
/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorProfileCopyWith<$Res>? get creatorProfile {
    if (_self.creatorProfile == null) {
    return null;
  }

  return $CreatorProfileCopyWith<$Res>(_self.creatorProfile!, (value) {
    return _then(_self.copyWith(creatorProfile: value));
  });
}
}



/// @nodoc


class _AllSearchResults implements AllSearchResults {
  const _AllSearchResults({required this.page, required this.numPages, required final  List<VideoInfoBase> videos, this.creatorProfile, final  List<VideoInfoBase>? creatorProfileVideos}): _videos = videos,_creatorProfileVideos = creatorProfileVideos;
  

@override final  int page;
@override final  int numPages;
 final  List<VideoInfoBase> _videos;
@override List<VideoInfoBase> get videos {
  if (_videos is EqualUnmodifiableListView) return _videos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videos);
}

@override final  CreatorProfile? creatorProfile;
 final  List<VideoInfoBase>? _creatorProfileVideos;
@override List<VideoInfoBase>? get creatorProfileVideos {
  final value = _creatorProfileVideos;
  if (value == null) return null;
  if (_creatorProfileVideos is EqualUnmodifiableListView) return _creatorProfileVideos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllSearchResultsCopyWith<_AllSearchResults> get copyWith => __$AllSearchResultsCopyWithImpl<_AllSearchResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllSearchResults&&(identical(other.page, page) || other.page == page)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other._videos, _videos)&&(identical(other.creatorProfile, creatorProfile) || other.creatorProfile == creatorProfile)&&const DeepCollectionEquality().equals(other._creatorProfileVideos, _creatorProfileVideos));
}


@override
int get hashCode => Object.hash(runtimeType,page,numPages,const DeepCollectionEquality().hash(_videos),creatorProfile,const DeepCollectionEquality().hash(_creatorProfileVideos));

@override
String toString() {
  return 'AllSearchResults(page: $page, numPages: $numPages, videos: $videos, creatorProfile: $creatorProfile, creatorProfileVideos: $creatorProfileVideos)';
}


}

/// @nodoc
abstract mixin class _$AllSearchResultsCopyWith<$Res> implements $AllSearchResultsCopyWith<$Res> {
  factory _$AllSearchResultsCopyWith(_AllSearchResults value, $Res Function(_AllSearchResults) _then) = __$AllSearchResultsCopyWithImpl;
@override @useResult
$Res call({
 int page, int numPages, List<VideoInfoBase> videos, CreatorProfile? creatorProfile, List<VideoInfoBase>? creatorProfileVideos
});


@override $CreatorProfileCopyWith<$Res>? get creatorProfile;

}
/// @nodoc
class __$AllSearchResultsCopyWithImpl<$Res>
    implements _$AllSearchResultsCopyWith<$Res> {
  __$AllSearchResultsCopyWithImpl(this._self, this._then);

  final _AllSearchResults _self;
  final $Res Function(_AllSearchResults) _then;

/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? numPages = null,Object? videos = null,Object? creatorProfile = freezed,Object? creatorProfileVideos = freezed,}) {
  return _then(_AllSearchResults(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self._videos : videos // ignore: cast_nullable_to_non_nullable
as List<VideoInfoBase>,creatorProfile: freezed == creatorProfile ? _self.creatorProfile : creatorProfile // ignore: cast_nullable_to_non_nullable
as CreatorProfile?,creatorProfileVideos: freezed == creatorProfileVideos ? _self._creatorProfileVideos : creatorProfileVideos // ignore: cast_nullable_to_non_nullable
as List<VideoInfoBase>?,
  ));
}

/// Create a copy of AllSearchResults
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorProfileCopyWith<$Res>? get creatorProfile {
    if (_self.creatorProfile == null) {
    return null;
  }

  return $CreatorProfileCopyWith<$Res>(_self.creatorProfile!, (value) {
    return _then(_self.copyWith(creatorProfile: value));
  });
}
}

/// @nodoc
mixin _$SearchResults<T> {

 int get page; int get numPages; List<T> get results;
/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultsCopyWith<T, SearchResults<T>> get copyWith => _$SearchResultsCopyWithImpl<T, SearchResults<T>>(this as SearchResults<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResults<T>&&(identical(other.page, page) || other.page == page)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other.results, results));
}


@override
int get hashCode => Object.hash(runtimeType,page,numPages,const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'SearchResults<$T>(page: $page, numPages: $numPages, results: $results)';
}


}

/// @nodoc
abstract mixin class $SearchResultsCopyWith<T,$Res>  {
  factory $SearchResultsCopyWith(SearchResults<T> value, $Res Function(SearchResults<T>) _then) = _$SearchResultsCopyWithImpl;
@useResult
$Res call({
 int page, int numPages, List<T> results
});




}
/// @nodoc
class _$SearchResultsCopyWithImpl<T,$Res>
    implements $SearchResultsCopyWith<T, $Res> {
  _$SearchResultsCopyWithImpl(this._self, this._then);

  final SearchResults<T> _self;
  final $Res Function(SearchResults<T>) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? numPages = null,Object? results = null,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<T>,
  ));
}

}



/// @nodoc


class _SearchResults<T> implements SearchResults<T> {
  const _SearchResults({required this.page, required this.numPages, required final  List<T> results}): _results = results;
  

@override final  int page;
@override final  int numPages;
 final  List<T> _results;
@override List<T> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultsCopyWith<T, _SearchResults<T>> get copyWith => __$SearchResultsCopyWithImpl<T, _SearchResults<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResults<T>&&(identical(other.page, page) || other.page == page)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&const DeepCollectionEquality().equals(other._results, _results));
}


@override
int get hashCode => Object.hash(runtimeType,page,numPages,const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'SearchResults<$T>(page: $page, numPages: $numPages, results: $results)';
}


}

/// @nodoc
abstract mixin class _$SearchResultsCopyWith<T,$Res> implements $SearchResultsCopyWith<T, $Res> {
  factory _$SearchResultsCopyWith(_SearchResults<T> value, $Res Function(_SearchResults<T>) _then) = __$SearchResultsCopyWithImpl;
@override @useResult
$Res call({
 int page, int numPages, List<T> results
});




}
/// @nodoc
class __$SearchResultsCopyWithImpl<T,$Res>
    implements _$SearchResultsCopyWith<T, $Res> {
  __$SearchResultsCopyWithImpl(this._self, this._then);

  final _SearchResults<T> _self;
  final $Res Function(_SearchResults<T>) _then;

/// Create a copy of SearchResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? numPages = null,Object? results = null,}) {
  return _then(_SearchResults<T>(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<T>,
  ));
}


}

// dart format on
