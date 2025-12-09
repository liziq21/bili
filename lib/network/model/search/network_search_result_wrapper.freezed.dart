// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_search_result_wrapper.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NetworkSearchResultWrapper {

 List<NetworkArticleSearchResult> get article; List<NetworkBiliUserSearchResult> get biliUser; List<NetworkMediaBangumiSearchResult> get mediaBangumi; List<NetworkMediaFtSearchResult> get mediaFt; List<NetworkLiveRoomSearchResult> get liveRoom; List<NetworkLiveUserSearchResult> get liveUser; List<NetworkVideoSearchResult> get video;
/// Create a copy of NetworkSearchResultWrapper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchResultWrapperCopyWith<NetworkSearchResultWrapper> get copyWith => _$NetworkSearchResultWrapperCopyWithImpl<NetworkSearchResultWrapper>(this as NetworkSearchResultWrapper, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchResultWrapper&&const DeepCollectionEquality().equals(other.article, article)&&const DeepCollectionEquality().equals(other.biliUser, biliUser)&&const DeepCollectionEquality().equals(other.mediaBangumi, mediaBangumi)&&const DeepCollectionEquality().equals(other.mediaFt, mediaFt)&&const DeepCollectionEquality().equals(other.liveRoom, liveRoom)&&const DeepCollectionEquality().equals(other.liveUser, liveUser)&&const DeepCollectionEquality().equals(other.video, video));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(article),const DeepCollectionEquality().hash(biliUser),const DeepCollectionEquality().hash(mediaBangumi),const DeepCollectionEquality().hash(mediaFt),const DeepCollectionEquality().hash(liveRoom),const DeepCollectionEquality().hash(liveUser),const DeepCollectionEquality().hash(video));

@override
String toString() {
  return 'NetworkSearchResultWrapper(article: $article, biliUser: $biliUser, mediaBangumi: $mediaBangumi, mediaFt: $mediaFt, liveRoom: $liveRoom, liveUser: $liveUser, video: $video)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchResultWrapperCopyWith<$Res>  {
  factory $NetworkSearchResultWrapperCopyWith(NetworkSearchResultWrapper value, $Res Function(NetworkSearchResultWrapper) _then) = _$NetworkSearchResultWrapperCopyWithImpl;
@useResult
$Res call({
 List<NetworkArticleSearchResult> article, List<NetworkBiliUserSearchResult> biliUser, List<NetworkMediaBangumiSearchResult> mediaBangumi, List<NetworkMediaFtSearchResult> mediaFt, List<NetworkLiveRoomSearchResult> liveRoom, List<NetworkLiveUserSearchResult> liveUser, List<NetworkVideoSearchResult> video
});




}
/// @nodoc
class _$NetworkSearchResultWrapperCopyWithImpl<$Res>
    implements $NetworkSearchResultWrapperCopyWith<$Res> {
  _$NetworkSearchResultWrapperCopyWithImpl(this._self, this._then);

  final NetworkSearchResultWrapper _self;
  final $Res Function(NetworkSearchResultWrapper) _then;

/// Create a copy of NetworkSearchResultWrapper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? biliUser = null,Object? mediaBangumi = null,Object? mediaFt = null,Object? liveRoom = null,Object? liveUser = null,Object? video = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as List<NetworkArticleSearchResult>,biliUser: null == biliUser ? _self.biliUser : biliUser // ignore: cast_nullable_to_non_nullable
as List<NetworkBiliUserSearchResult>,mediaBangumi: null == mediaBangumi ? _self.mediaBangumi : mediaBangumi // ignore: cast_nullable_to_non_nullable
as List<NetworkMediaBangumiSearchResult>,mediaFt: null == mediaFt ? _self.mediaFt : mediaFt // ignore: cast_nullable_to_non_nullable
as List<NetworkMediaFtSearchResult>,liveRoom: null == liveRoom ? _self.liveRoom : liveRoom // ignore: cast_nullable_to_non_nullable
as List<NetworkLiveRoomSearchResult>,liveUser: null == liveUser ? _self.liveUser : liveUser // ignore: cast_nullable_to_non_nullable
as List<NetworkLiveUserSearchResult>,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as List<NetworkVideoSearchResult>,
  ));
}

}



/// @nodoc


class _NetworkSearchResultWrapper implements NetworkSearchResultWrapper {
  const _NetworkSearchResultWrapper({final  List<NetworkArticleSearchResult> article = const [], final  List<NetworkBiliUserSearchResult> biliUser = const [], final  List<NetworkMediaBangumiSearchResult> mediaBangumi = const [], final  List<NetworkMediaFtSearchResult> mediaFt = const [], final  List<NetworkLiveRoomSearchResult> liveRoom = const [], final  List<NetworkLiveUserSearchResult> liveUser = const [], final  List<NetworkVideoSearchResult> video = const []}): _article = article,_biliUser = biliUser,_mediaBangumi = mediaBangumi,_mediaFt = mediaFt,_liveRoom = liveRoom,_liveUser = liveUser,_video = video;
  

 final  List<NetworkArticleSearchResult> _article;
@override@JsonKey() List<NetworkArticleSearchResult> get article {
  if (_article is EqualUnmodifiableListView) return _article;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_article);
}

 final  List<NetworkBiliUserSearchResult> _biliUser;
@override@JsonKey() List<NetworkBiliUserSearchResult> get biliUser {
  if (_biliUser is EqualUnmodifiableListView) return _biliUser;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_biliUser);
}

 final  List<NetworkMediaBangumiSearchResult> _mediaBangumi;
@override@JsonKey() List<NetworkMediaBangumiSearchResult> get mediaBangumi {
  if (_mediaBangumi is EqualUnmodifiableListView) return _mediaBangumi;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaBangumi);
}

 final  List<NetworkMediaFtSearchResult> _mediaFt;
@override@JsonKey() List<NetworkMediaFtSearchResult> get mediaFt {
  if (_mediaFt is EqualUnmodifiableListView) return _mediaFt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaFt);
}

 final  List<NetworkLiveRoomSearchResult> _liveRoom;
@override@JsonKey() List<NetworkLiveRoomSearchResult> get liveRoom {
  if (_liveRoom is EqualUnmodifiableListView) return _liveRoom;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_liveRoom);
}

 final  List<NetworkLiveUserSearchResult> _liveUser;
@override@JsonKey() List<NetworkLiveUserSearchResult> get liveUser {
  if (_liveUser is EqualUnmodifiableListView) return _liveUser;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_liveUser);
}

 final  List<NetworkVideoSearchResult> _video;
@override@JsonKey() List<NetworkVideoSearchResult> get video {
  if (_video is EqualUnmodifiableListView) return _video;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_video);
}


/// Create a copy of NetworkSearchResultWrapper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkSearchResultWrapperCopyWith<_NetworkSearchResultWrapper> get copyWith => __$NetworkSearchResultWrapperCopyWithImpl<_NetworkSearchResultWrapper>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkSearchResultWrapper&&const DeepCollectionEquality().equals(other._article, _article)&&const DeepCollectionEquality().equals(other._biliUser, _biliUser)&&const DeepCollectionEquality().equals(other._mediaBangumi, _mediaBangumi)&&const DeepCollectionEquality().equals(other._mediaFt, _mediaFt)&&const DeepCollectionEquality().equals(other._liveRoom, _liveRoom)&&const DeepCollectionEquality().equals(other._liveUser, _liveUser)&&const DeepCollectionEquality().equals(other._video, _video));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_article),const DeepCollectionEquality().hash(_biliUser),const DeepCollectionEquality().hash(_mediaBangumi),const DeepCollectionEquality().hash(_mediaFt),const DeepCollectionEquality().hash(_liveRoom),const DeepCollectionEquality().hash(_liveUser),const DeepCollectionEquality().hash(_video));

@override
String toString() {
  return 'NetworkSearchResultWrapper(article: $article, biliUser: $biliUser, mediaBangumi: $mediaBangumi, mediaFt: $mediaFt, liveRoom: $liveRoom, liveUser: $liveUser, video: $video)';
}


}

/// @nodoc
abstract mixin class _$NetworkSearchResultWrapperCopyWith<$Res> implements $NetworkSearchResultWrapperCopyWith<$Res> {
  factory _$NetworkSearchResultWrapperCopyWith(_NetworkSearchResultWrapper value, $Res Function(_NetworkSearchResultWrapper) _then) = __$NetworkSearchResultWrapperCopyWithImpl;
@override @useResult
$Res call({
 List<NetworkArticleSearchResult> article, List<NetworkBiliUserSearchResult> biliUser, List<NetworkMediaBangumiSearchResult> mediaBangumi, List<NetworkMediaFtSearchResult> mediaFt, List<NetworkLiveRoomSearchResult> liveRoom, List<NetworkLiveUserSearchResult> liveUser, List<NetworkVideoSearchResult> video
});




}
/// @nodoc
class __$NetworkSearchResultWrapperCopyWithImpl<$Res>
    implements _$NetworkSearchResultWrapperCopyWith<$Res> {
  __$NetworkSearchResultWrapperCopyWithImpl(this._self, this._then);

  final _NetworkSearchResultWrapper _self;
  final $Res Function(_NetworkSearchResultWrapper) _then;

/// Create a copy of NetworkSearchResultWrapper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? biliUser = null,Object? mediaBangumi = null,Object? mediaFt = null,Object? liveRoom = null,Object? liveUser = null,Object? video = null,}) {
  return _then(_NetworkSearchResultWrapper(
article: null == article ? _self._article : article // ignore: cast_nullable_to_non_nullable
as List<NetworkArticleSearchResult>,biliUser: null == biliUser ? _self._biliUser : biliUser // ignore: cast_nullable_to_non_nullable
as List<NetworkBiliUserSearchResult>,mediaBangumi: null == mediaBangumi ? _self._mediaBangumi : mediaBangumi // ignore: cast_nullable_to_non_nullable
as List<NetworkMediaBangumiSearchResult>,mediaFt: null == mediaFt ? _self._mediaFt : mediaFt // ignore: cast_nullable_to_non_nullable
as List<NetworkMediaFtSearchResult>,liveRoom: null == liveRoom ? _self._liveRoom : liveRoom // ignore: cast_nullable_to_non_nullable
as List<NetworkLiveRoomSearchResult>,liveUser: null == liveUser ? _self._liveUser : liveUser // ignore: cast_nullable_to_non_nullable
as List<NetworkLiveUserSearchResult>,video: null == video ? _self._video : video // ignore: cast_nullable_to_non_nullable
as List<NetworkVideoSearchResult>,
  ));
}


}

// dart format on
