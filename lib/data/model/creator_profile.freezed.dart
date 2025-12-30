// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'creator_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreatorProfile implements DiagnosticableTreeMixin {

 String get id; String get name; String get thumbnailUrl; bool get isLive; int get roomId; int? get subscribers; int? get videos;
/// Create a copy of CreatorProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorProfileCopyWith<CreatorProfile> get copyWith => _$CreatorProfileCopyWithImpl<CreatorProfile>(this as CreatorProfile, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CreatorProfile'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('thumbnailUrl', thumbnailUrl))..add(DiagnosticsProperty('isLive', isLive))..add(DiagnosticsProperty('roomId', roomId))..add(DiagnosticsProperty('subscribers', subscribers))..add(DiagnosticsProperty('videos', videos));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatorProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.subscribers, subscribers) || other.subscribers == subscribers)&&(identical(other.videos, videos) || other.videos == videos));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,thumbnailUrl,isLive,roomId,subscribers,videos);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CreatorProfile(id: $id, name: $name, thumbnailUrl: $thumbnailUrl, isLive: $isLive, roomId: $roomId, subscribers: $subscribers, videos: $videos)';
}


}

/// @nodoc
abstract mixin class $CreatorProfileCopyWith<$Res>  {
  factory $CreatorProfileCopyWith(CreatorProfile value, $Res Function(CreatorProfile) _then) = _$CreatorProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String thumbnailUrl, bool isLive, int roomId, int? subscribers, int? videos
});




}
/// @nodoc
class _$CreatorProfileCopyWithImpl<$Res>
    implements $CreatorProfileCopyWith<$Res> {
  _$CreatorProfileCopyWithImpl(this._self, this._then);

  final CreatorProfile _self;
  final $Res Function(CreatorProfile) _then;

/// Create a copy of CreatorProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? thumbnailUrl = null,Object? isLive = null,Object? roomId = null,Object? subscribers = freezed,Object? videos = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,subscribers: freezed == subscribers ? _self.subscribers : subscribers // ignore: cast_nullable_to_non_nullable
as int?,videos: freezed == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}



/// @nodoc


class _CreatorProfile with DiagnosticableTreeMixin implements CreatorProfile {
  const _CreatorProfile({required this.id, required this.name, required this.thumbnailUrl, required this.isLive, required this.roomId, this.subscribers, this.videos});
  

@override final  String id;
@override final  String name;
@override final  String thumbnailUrl;
@override final  bool isLive;
@override final  int roomId;
@override final  int? subscribers;
@override final  int? videos;

/// Create a copy of CreatorProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorProfileCopyWith<_CreatorProfile> get copyWith => __$CreatorProfileCopyWithImpl<_CreatorProfile>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CreatorProfile'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('thumbnailUrl', thumbnailUrl))..add(DiagnosticsProperty('isLive', isLive))..add(DiagnosticsProperty('roomId', roomId))..add(DiagnosticsProperty('subscribers', subscribers))..add(DiagnosticsProperty('videos', videos));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatorProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.subscribers, subscribers) || other.subscribers == subscribers)&&(identical(other.videos, videos) || other.videos == videos));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,thumbnailUrl,isLive,roomId,subscribers,videos);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CreatorProfile(id: $id, name: $name, thumbnailUrl: $thumbnailUrl, isLive: $isLive, roomId: $roomId, subscribers: $subscribers, videos: $videos)';
}


}

/// @nodoc
abstract mixin class _$CreatorProfileCopyWith<$Res> implements $CreatorProfileCopyWith<$Res> {
  factory _$CreatorProfileCopyWith(_CreatorProfile value, $Res Function(_CreatorProfile) _then) = __$CreatorProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String thumbnailUrl, bool isLive, int roomId, int? subscribers, int? videos
});




}
/// @nodoc
class __$CreatorProfileCopyWithImpl<$Res>
    implements _$CreatorProfileCopyWith<$Res> {
  __$CreatorProfileCopyWithImpl(this._self, this._then);

  final _CreatorProfile _self;
  final $Res Function(_CreatorProfile) _then;

/// Create a copy of CreatorProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? thumbnailUrl = null,Object? isLive = null,Object? roomId = null,Object? subscribers = freezed,Object? videos = freezed,}) {
  return _then(_CreatorProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,subscribers: freezed == subscribers ? _self.subscribers : subscribers // ignore: cast_nullable_to_non_nullable
as int?,videos: freezed == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
