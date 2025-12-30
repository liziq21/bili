// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LiveRoom implements DiagnosticableTreeMixin {

 int get id; String get title; String get coverUrl; bool get isLive; String get cateName; int get uid; String get uname;
/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRoomCopyWith<LiveRoom> get copyWith => _$LiveRoomCopyWithImpl<LiveRoom>(this as LiveRoom, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LiveRoom'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('coverUrl', coverUrl))..add(DiagnosticsProperty('isLive', isLive))..add(DiagnosticsProperty('cateName', cateName))..add(DiagnosticsProperty('uid', uid))..add(DiagnosticsProperty('uname', uname));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.cateName, cateName) || other.cateName == cateName)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uname, uname) || other.uname == uname));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,coverUrl,isLive,cateName,uid,uname);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LiveRoom(id: $id, title: $title, coverUrl: $coverUrl, isLive: $isLive, cateName: $cateName, uid: $uid, uname: $uname)';
}


}

/// @nodoc
abstract mixin class $LiveRoomCopyWith<$Res>  {
  factory $LiveRoomCopyWith(LiveRoom value, $Res Function(LiveRoom) _then) = _$LiveRoomCopyWithImpl;
@useResult
$Res call({
 int id, String title, String coverUrl, bool isLive, String cateName, int uid, String uname
});




}
/// @nodoc
class _$LiveRoomCopyWithImpl<$Res>
    implements $LiveRoomCopyWith<$Res> {
  _$LiveRoomCopyWithImpl(this._self, this._then);

  final LiveRoom _self;
  final $Res Function(LiveRoom) _then;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? coverUrl = null,Object? isLive = null,Object? cateName = null,Object? uid = null,Object? uname = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,cateName: null == cateName ? _self.cateName : cateName // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



/// @nodoc


class _LiveRoom with DiagnosticableTreeMixin implements LiveRoom {
  const _LiveRoom({required this.id, required this.title, required this.coverUrl, required this.isLive, required this.cateName, required this.uid, required this.uname});
  

@override final  int id;
@override final  String title;
@override final  String coverUrl;
@override final  bool isLive;
@override final  String cateName;
@override final  int uid;
@override final  String uname;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRoomCopyWith<_LiveRoom> get copyWith => __$LiveRoomCopyWithImpl<_LiveRoom>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'LiveRoom'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('coverUrl', coverUrl))..add(DiagnosticsProperty('isLive', isLive))..add(DiagnosticsProperty('cateName', cateName))..add(DiagnosticsProperty('uid', uid))..add(DiagnosticsProperty('uname', uname));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.cateName, cateName) || other.cateName == cateName)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uname, uname) || other.uname == uname));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,coverUrl,isLive,cateName,uid,uname);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'LiveRoom(id: $id, title: $title, coverUrl: $coverUrl, isLive: $isLive, cateName: $cateName, uid: $uid, uname: $uname)';
}


}

/// @nodoc
abstract mixin class _$LiveRoomCopyWith<$Res> implements $LiveRoomCopyWith<$Res> {
  factory _$LiveRoomCopyWith(_LiveRoom value, $Res Function(_LiveRoom) _then) = __$LiveRoomCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String coverUrl, bool isLive, String cateName, int uid, String uname
});




}
/// @nodoc
class __$LiveRoomCopyWithImpl<$Res>
    implements _$LiveRoomCopyWith<$Res> {
  __$LiveRoomCopyWithImpl(this._self, this._then);

  final _LiveRoom _self;
  final $Res Function(_LiveRoom) _then;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? coverUrl = null,Object? isLive = null,Object? cateName = null,Object? uid = null,Object? uname = null,}) {
  return _then(_LiveRoom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,cateName: null == cateName ? _self.cateName : cateName // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
