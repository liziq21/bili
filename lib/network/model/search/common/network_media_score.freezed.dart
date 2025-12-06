// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_media_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkMediaScore {

 int get score; int get userCount;
/// Create a copy of NetworkMediaScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkMediaScoreCopyWith<NetworkMediaScore> get copyWith => _$NetworkMediaScoreCopyWithImpl<NetworkMediaScore>(this as NetworkMediaScore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkMediaScore&&(identical(other.score, score) || other.score == score)&&(identical(other.userCount, userCount) || other.userCount == userCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,score,userCount);

@override
String toString() {
  return 'NetworkMediaScore(score: $score, userCount: $userCount)';
}


}

/// @nodoc
abstract mixin class $NetworkMediaScoreCopyWith<$Res>  {
  factory $NetworkMediaScoreCopyWith(NetworkMediaScore value, $Res Function(NetworkMediaScore) _then) = _$NetworkMediaScoreCopyWithImpl;
@useResult
$Res call({
 int score, int userCount
});




}
/// @nodoc
class _$NetworkMediaScoreCopyWithImpl<$Res>
    implements $NetworkMediaScoreCopyWith<$Res> {
  _$NetworkMediaScoreCopyWithImpl(this._self, this._then);

  final NetworkMediaScore _self;
  final $Res Function(NetworkMediaScore) _then;

/// Create a copy of NetworkMediaScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? score = null,Object? userCount = null,}) {
  return _then(_self.copyWith(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,userCount: null == userCount ? _self.userCount : userCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc

@JsonSerializable(fieldRename: .snake)
class _NetworkMediaScore implements NetworkMediaScore {
  const _NetworkMediaScore({required this.score, required this.userCount});
  factory _NetworkMediaScore.fromJson(Map<String, dynamic> json) => _$NetworkMediaScoreFromJson(json);

@override final  int score;
@override final  int userCount;

/// Create a copy of NetworkMediaScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkMediaScoreCopyWith<_NetworkMediaScore> get copyWith => __$NetworkMediaScoreCopyWithImpl<_NetworkMediaScore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkMediaScore&&(identical(other.score, score) || other.score == score)&&(identical(other.userCount, userCount) || other.userCount == userCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,score,userCount);

@override
String toString() {
  return 'NetworkMediaScore(score: $score, userCount: $userCount)';
}


}

/// @nodoc
abstract mixin class _$NetworkMediaScoreCopyWith<$Res> implements $NetworkMediaScoreCopyWith<$Res> {
  factory _$NetworkMediaScoreCopyWith(_NetworkMediaScore value, $Res Function(_NetworkMediaScore) _then) = __$NetworkMediaScoreCopyWithImpl;
@override @useResult
$Res call({
 int score, int userCount
});




}
/// @nodoc
class __$NetworkMediaScoreCopyWithImpl<$Res>
    implements _$NetworkMediaScoreCopyWith<$Res> {
  __$NetworkMediaScoreCopyWithImpl(this._self, this._then);

  final _NetworkMediaScore _self;
  final $Res Function(_NetworkMediaScore) _then;

/// Create a copy of NetworkMediaScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? score = null,Object? userCount = null,}) {
  return _then(_NetworkMediaScore(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,userCount: null == userCount ? _self.userCount : userCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
