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
NetworkSearchResult _$NetworkSearchResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'article':
          return NetworkArticleSearchResult.fromJson(
            json
          );
                case 'bili_user':
          return NetworkBiliUserSearchResult.fromJson(
            json
          );
                case 'media_bangumi':
          return NetworkMediaBangumiSearchResult.fromJson(
            json
          );
                case 'media_ft':
          return NetworkMediaFtSearchResult.fromJson(
            json
          );
                case 'live_room':
          return NetworkLiveRoomSearchResult.fromJson(
            json
          );
                case 'live_user':
          return NetworkLiveUserSearchResult.fromJson(
            json
          );
                case 'video':
          return NetworkVideoSearchResult.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'NetworkSearchResult',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$NetworkSearchResult {

 SearchResultType get type;
/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkSearchResultCopyWith<NetworkSearchResult> get copyWith => _$NetworkSearchResultCopyWithImpl<NetworkSearchResult>(this as NetworkSearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkSearchResult&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'NetworkSearchResult(type: $type)';
}


}

/// @nodoc
abstract mixin class $NetworkSearchResultCopyWith<$Res>  {
  factory $NetworkSearchResultCopyWith(NetworkSearchResult value, $Res Function(NetworkSearchResult) _then) = _$NetworkSearchResultCopyWithImpl;
@useResult
$Res call({
 SearchResultType type
});




}
/// @nodoc
class _$NetworkSearchResultCopyWithImpl<$Res>
    implements $NetworkSearchResultCopyWith<$Res> {
  _$NetworkSearchResultCopyWithImpl(this._self, this._then);

  final NetworkSearchResult _self;
  final $Res Function(NetworkSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,
  ));
}

}



/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkArticleSearchResult implements NetworkSearchResult {
  const NetworkArticleSearchResult(this.type, this.categoryId, this.categoryName, this.commentUrl, this.desc, this.id, final  List<String> imageUrls, this.isComment, this.isFold, this.isRk1, this.like, this.mid, this.pubTime, this.rankIndex, this.rankOffset, this.reply, this.spreadId, this.subType, this.templateId, this.title, this.version, this.view): _imageUrls = imageUrls;
  factory NetworkArticleSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkArticleSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int categoryId;
 final  String categoryName;
 final  String commentUrl;
 final  String desc;
 final  int id;
 final  List<String> _imageUrls;
 List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

 final  int isComment;
 final  bool isFold;
 final  bool isRk1;
 final  int like;
 final  int mid;
 final  int pubTime;
 final  int rankIndex;
 final  int rankOffset;
 final  int reply;
 final  int spreadId;
 final  int subType;
 final  int templateId;
 final  HtmlTitle title;
 final  String version;
 final  int view;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkArticleSearchResultCopyWith<NetworkArticleSearchResult> get copyWith => _$NetworkArticleSearchResultCopyWithImpl<NetworkArticleSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkArticleSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.commentUrl, commentUrl) || other.commentUrl == commentUrl)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.isComment, isComment) || other.isComment == isComment)&&(identical(other.isFold, isFold) || other.isFold == isFold)&&(identical(other.isRk1, isRk1) || other.isRk1 == isRk1)&&(identical(other.like, like) || other.like == like)&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.pubTime, pubTime) || other.pubTime == pubTime)&&(identical(other.rankIndex, rankIndex) || other.rankIndex == rankIndex)&&(identical(other.rankOffset, rankOffset) || other.rankOffset == rankOffset)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.subType, subType) || other.subType == subType)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.title, title) || other.title == title)&&(identical(other.version, version) || other.version == version)&&(identical(other.view, view) || other.view == view));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,categoryId,categoryName,commentUrl,desc,id,const DeepCollectionEquality().hash(_imageUrls),isComment,isFold,isRk1,like,mid,pubTime,rankIndex,rankOffset,reply,spreadId,subType,templateId,title,version,view]);

@override
String toString() {
  return 'NetworkSearchResult.article(type: $type, categoryId: $categoryId, categoryName: $categoryName, commentUrl: $commentUrl, desc: $desc, id: $id, imageUrls: $imageUrls, isComment: $isComment, isFold: $isFold, isRk1: $isRk1, like: $like, mid: $mid, pubTime: $pubTime, rankIndex: $rankIndex, rankOffset: $rankOffset, reply: $reply, spreadId: $spreadId, subType: $subType, templateId: $templateId, title: $title, version: $version, view: $view)';
}


}

/// @nodoc
abstract mixin class $NetworkArticleSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkArticleSearchResultCopyWith(NetworkArticleSearchResult value, $Res Function(NetworkArticleSearchResult) _then) = _$NetworkArticleSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int categoryId, String categoryName, String commentUrl, String desc, int id, List<String> imageUrls, int isComment, bool isFold, bool isRk1, int like, int mid, int pubTime, int rankIndex, int rankOffset, int reply, int spreadId, int subType, int templateId, HtmlTitle title, String version, int view
});


$HtmlTitleCopyWith<$Res> get title;

}
/// @nodoc
class _$NetworkArticleSearchResultCopyWithImpl<$Res>
    implements $NetworkArticleSearchResultCopyWith<$Res> {
  _$NetworkArticleSearchResultCopyWithImpl(this._self, this._then);

  final NetworkArticleSearchResult _self;
  final $Res Function(NetworkArticleSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? categoryId = null,Object? categoryName = null,Object? commentUrl = null,Object? desc = null,Object? id = null,Object? imageUrls = null,Object? isComment = null,Object? isFold = null,Object? isRk1 = null,Object? like = null,Object? mid = null,Object? pubTime = null,Object? rankIndex = null,Object? rankOffset = null,Object? reply = null,Object? spreadId = null,Object? subType = null,Object? templateId = null,Object? title = null,Object? version = null,Object? view = null,}) {
  return _then(NetworkArticleSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,null == commentUrl ? _self.commentUrl : commentUrl // ignore: cast_nullable_to_non_nullable
as String,null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,null == isComment ? _self.isComment : isComment // ignore: cast_nullable_to_non_nullable
as int,null == isFold ? _self.isFold : isFold // ignore: cast_nullable_to_non_nullable
as bool,null == isRk1 ? _self.isRk1 : isRk1 // ignore: cast_nullable_to_non_nullable
as bool,null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as int,null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,null == pubTime ? _self.pubTime : pubTime // ignore: cast_nullable_to_non_nullable
as int,null == rankIndex ? _self.rankIndex : rankIndex // ignore: cast_nullable_to_non_nullable
as int,null == rankOffset ? _self.rankOffset : rankOffset // ignore: cast_nullable_to_non_nullable
as int,null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as int,null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as int,null == subType ? _self.subType : subType // ignore: cast_nullable_to_non_nullable
as int,null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as int,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as HtmlTitle,null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get title {
  
  return $HtmlTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkBiliUserSearchResult implements NetworkSearchResult {
  const NetworkBiliUserSearchResult(this.type, this.mid, this.uname, this.usign, this.fans, this.videos, this.upic, this.faceNft, this.faceNftType, this.verifyInfo, this.level, this.gender, this.isUpuser, this.isLive, this.roomId, final  List<NetworkBiliUserRes> res, this.officialVerify, this.isSeniorMember): _res = res;
  factory NetworkBiliUserSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkBiliUserSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int mid;
 final  String uname;
 final  String usign;
 final  int fans;
 final  int videos;
 final  String upic;
 final  int faceNft;
 final  int faceNftType;
 final  String verifyInfo;
 final  int level;
 final  int gender;
 final  int isUpuser;
 final  int isLive;
 final  int roomId;
 final  List<NetworkBiliUserRes> _res;
 List<NetworkBiliUserRes> get res {
  if (_res is EqualUnmodifiableListView) return _res;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_res);
}

 final  NetworkUserOfficialVerify officialVerify;
 final  int isSeniorMember;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkBiliUserSearchResultCopyWith<NetworkBiliUserSearchResult> get copyWith => _$NetworkBiliUserSearchResultCopyWithImpl<NetworkBiliUserSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkBiliUserSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.usign, usign) || other.usign == usign)&&(identical(other.fans, fans) || other.fans == fans)&&(identical(other.videos, videos) || other.videos == videos)&&(identical(other.upic, upic) || other.upic == upic)&&(identical(other.faceNft, faceNft) || other.faceNft == faceNft)&&(identical(other.faceNftType, faceNftType) || other.faceNftType == faceNftType)&&(identical(other.verifyInfo, verifyInfo) || other.verifyInfo == verifyInfo)&&(identical(other.level, level) || other.level == level)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.isUpuser, isUpuser) || other.isUpuser == isUpuser)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&const DeepCollectionEquality().equals(other._res, _res)&&(identical(other.officialVerify, officialVerify) || other.officialVerify == officialVerify)&&(identical(other.isSeniorMember, isSeniorMember) || other.isSeniorMember == isSeniorMember));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,mid,uname,usign,fans,videos,upic,faceNft,faceNftType,verifyInfo,level,gender,isUpuser,isLive,roomId,const DeepCollectionEquality().hash(_res),officialVerify,isSeniorMember);

@override
String toString() {
  return 'NetworkSearchResult.biliUser(type: $type, mid: $mid, uname: $uname, usign: $usign, fans: $fans, videos: $videos, upic: $upic, faceNft: $faceNft, faceNftType: $faceNftType, verifyInfo: $verifyInfo, level: $level, gender: $gender, isUpuser: $isUpuser, isLive: $isLive, roomId: $roomId, res: $res, officialVerify: $officialVerify, isSeniorMember: $isSeniorMember)';
}


}

/// @nodoc
abstract mixin class $NetworkBiliUserSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkBiliUserSearchResultCopyWith(NetworkBiliUserSearchResult value, $Res Function(NetworkBiliUserSearchResult) _then) = _$NetworkBiliUserSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int mid, String uname, String usign, int fans, int videos, String upic, int faceNft, int faceNftType, String verifyInfo, int level, int gender, int isUpuser, int isLive, int roomId, List<NetworkBiliUserRes> res, NetworkUserOfficialVerify officialVerify, int isSeniorMember
});


$NetworkUserOfficialVerifyCopyWith<$Res> get officialVerify;

}
/// @nodoc
class _$NetworkBiliUserSearchResultCopyWithImpl<$Res>
    implements $NetworkBiliUserSearchResultCopyWith<$Res> {
  _$NetworkBiliUserSearchResultCopyWithImpl(this._self, this._then);

  final NetworkBiliUserSearchResult _self;
  final $Res Function(NetworkBiliUserSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? mid = null,Object? uname = null,Object? usign = null,Object? fans = null,Object? videos = null,Object? upic = null,Object? faceNft = null,Object? faceNftType = null,Object? verifyInfo = null,Object? level = null,Object? gender = null,Object? isUpuser = null,Object? isLive = null,Object? roomId = null,Object? res = null,Object? officialVerify = null,Object? isSeniorMember = null,}) {
  return _then(NetworkBiliUserSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,null == usign ? _self.usign : usign // ignore: cast_nullable_to_non_nullable
as String,null == fans ? _self.fans : fans // ignore: cast_nullable_to_non_nullable
as int,null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as int,null == upic ? _self.upic : upic // ignore: cast_nullable_to_non_nullable
as String,null == faceNft ? _self.faceNft : faceNft // ignore: cast_nullable_to_non_nullable
as int,null == faceNftType ? _self.faceNftType : faceNftType // ignore: cast_nullable_to_non_nullable
as int,null == verifyInfo ? _self.verifyInfo : verifyInfo // ignore: cast_nullable_to_non_nullable
as String,null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as int,null == isUpuser ? _self.isUpuser : isUpuser // ignore: cast_nullable_to_non_nullable
as int,null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as int,null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,null == res ? _self._res : res // ignore: cast_nullable_to_non_nullable
as List<NetworkBiliUserRes>,null == officialVerify ? _self.officialVerify : officialVerify // ignore: cast_nullable_to_non_nullable
as NetworkUserOfficialVerify,null == isSeniorMember ? _self.isSeniorMember : isSeniorMember // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkUserOfficialVerifyCopyWith<$Res> get officialVerify {
  
  return $NetworkUserOfficialVerifyCopyWith<$Res>(_self.officialVerify, (value) {
    return _then(_self.copyWith(officialVerify: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkMediaBangumiSearchResult implements NetworkSearchResult {
  const NetworkMediaBangumiSearchResult(this.type, this.mediaId, this.title, this.orgTitle, this.mediaType, this.cv, this.staff, this.seasonId, this.isAvid, this.hitEpids, this.seasonType, this.seasonTypeName, this.url, this.buttonText, this.isSelection, this.cover, this.areas, this.styles, this.gotoUrl, this.desc, this.pubtime, this.mediaMode, this.mediaScore, this.indexShow);
  factory NetworkMediaBangumiSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkMediaBangumiSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int mediaId;
 final  HtmlTitle title;
 final  String orgTitle;
 final  int mediaType;
 final  String cv;
 final  String staff;
 final  int seasonId;
 final  bool isAvid;
 final  String hitEpids;
 final  int seasonType;
 final  String seasonTypeName;
 final  String url;
 final  String buttonText;
 final  int isSelection;
 final  String? cover;
 final  String areas;
 final  String styles;
 final  String gotoUrl;
 final  String desc;
 final  int pubtime;
 final  int mediaMode;
 final  NetworkMediaScore mediaScore;
 final  String indexShow;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkMediaBangumiSearchResultCopyWith<NetworkMediaBangumiSearchResult> get copyWith => _$NetworkMediaBangumiSearchResultCopyWithImpl<NetworkMediaBangumiSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkMediaBangumiSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.orgTitle, orgTitle) || other.orgTitle == orgTitle)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.cv, cv) || other.cv == cv)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.isAvid, isAvid) || other.isAvid == isAvid)&&(identical(other.hitEpids, hitEpids) || other.hitEpids == hitEpids)&&(identical(other.seasonType, seasonType) || other.seasonType == seasonType)&&(identical(other.seasonTypeName, seasonTypeName) || other.seasonTypeName == seasonTypeName)&&(identical(other.url, url) || other.url == url)&&(identical(other.buttonText, buttonText) || other.buttonText == buttonText)&&(identical(other.isSelection, isSelection) || other.isSelection == isSelection)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.areas, areas) || other.areas == areas)&&(identical(other.styles, styles) || other.styles == styles)&&(identical(other.gotoUrl, gotoUrl) || other.gotoUrl == gotoUrl)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.pubtime, pubtime) || other.pubtime == pubtime)&&(identical(other.mediaMode, mediaMode) || other.mediaMode == mediaMode)&&(identical(other.mediaScore, mediaScore) || other.mediaScore == mediaScore)&&(identical(other.indexShow, indexShow) || other.indexShow == indexShow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,mediaId,title,orgTitle,mediaType,cv,staff,seasonId,isAvid,hitEpids,seasonType,seasonTypeName,url,buttonText,isSelection,cover,areas,styles,gotoUrl,desc,pubtime,mediaMode,mediaScore,indexShow]);

@override
String toString() {
  return 'NetworkSearchResult.mediaBangumi(type: $type, mediaId: $mediaId, title: $title, orgTitle: $orgTitle, mediaType: $mediaType, cv: $cv, staff: $staff, seasonId: $seasonId, isAvid: $isAvid, hitEpids: $hitEpids, seasonType: $seasonType, seasonTypeName: $seasonTypeName, url: $url, buttonText: $buttonText, isSelection: $isSelection, cover: $cover, areas: $areas, styles: $styles, gotoUrl: $gotoUrl, desc: $desc, pubtime: $pubtime, mediaMode: $mediaMode, mediaScore: $mediaScore, indexShow: $indexShow)';
}


}

/// @nodoc
abstract mixin class $NetworkMediaBangumiSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkMediaBangumiSearchResultCopyWith(NetworkMediaBangumiSearchResult value, $Res Function(NetworkMediaBangumiSearchResult) _then) = _$NetworkMediaBangumiSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int mediaId, HtmlTitle title, String orgTitle, int mediaType, String cv, String staff, int seasonId, bool isAvid, String hitEpids, int seasonType, String seasonTypeName, String url, String buttonText, int isSelection, String? cover, String areas, String styles, String gotoUrl, String desc, int pubtime, int mediaMode, NetworkMediaScore mediaScore, String indexShow
});


$HtmlTitleCopyWith<$Res> get title;$NetworkMediaScoreCopyWith<$Res> get mediaScore;

}
/// @nodoc
class _$NetworkMediaBangumiSearchResultCopyWithImpl<$Res>
    implements $NetworkMediaBangumiSearchResultCopyWith<$Res> {
  _$NetworkMediaBangumiSearchResultCopyWithImpl(this._self, this._then);

  final NetworkMediaBangumiSearchResult _self;
  final $Res Function(NetworkMediaBangumiSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? mediaId = null,Object? title = null,Object? orgTitle = null,Object? mediaType = null,Object? cv = null,Object? staff = null,Object? seasonId = null,Object? isAvid = null,Object? hitEpids = null,Object? seasonType = null,Object? seasonTypeName = null,Object? url = null,Object? buttonText = null,Object? isSelection = null,Object? cover = freezed,Object? areas = null,Object? styles = null,Object? gotoUrl = null,Object? desc = null,Object? pubtime = null,Object? mediaMode = null,Object? mediaScore = null,Object? indexShow = null,}) {
  return _then(NetworkMediaBangumiSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as int,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as HtmlTitle,null == orgTitle ? _self.orgTitle : orgTitle // ignore: cast_nullable_to_non_nullable
as String,null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as int,null == cv ? _self.cv : cv // ignore: cast_nullable_to_non_nullable
as String,null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as String,null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,null == isAvid ? _self.isAvid : isAvid // ignore: cast_nullable_to_non_nullable
as bool,null == hitEpids ? _self.hitEpids : hitEpids // ignore: cast_nullable_to_non_nullable
as String,null == seasonType ? _self.seasonType : seasonType // ignore: cast_nullable_to_non_nullable
as int,null == seasonTypeName ? _self.seasonTypeName : seasonTypeName // ignore: cast_nullable_to_non_nullable
as String,null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,null == buttonText ? _self.buttonText : buttonText // ignore: cast_nullable_to_non_nullable
as String,null == isSelection ? _self.isSelection : isSelection // ignore: cast_nullable_to_non_nullable
as int,freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as String,null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as String,null == gotoUrl ? _self.gotoUrl : gotoUrl // ignore: cast_nullable_to_non_nullable
as String,null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,null == pubtime ? _self.pubtime : pubtime // ignore: cast_nullable_to_non_nullable
as int,null == mediaMode ? _self.mediaMode : mediaMode // ignore: cast_nullable_to_non_nullable
as int,null == mediaScore ? _self.mediaScore : mediaScore // ignore: cast_nullable_to_non_nullable
as NetworkMediaScore,null == indexShow ? _self.indexShow : indexShow // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get title {
  
  return $HtmlTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkMediaScoreCopyWith<$Res> get mediaScore {
  
  return $NetworkMediaScoreCopyWith<$Res>(_self.mediaScore, (value) {
    return _then(_self.copyWith(mediaScore: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkMediaFtSearchResult implements NetworkSearchResult {
  const NetworkMediaFtSearchResult(this.type, this.mediaId, this.title, this.orgTitle, this.mediaType, this.cv, this.staff, this.seasonId, this.isAvid, this.hitEpids, this.seasonType, this.seasonTypeName, this.url, this.buttonText, this.isSelection, this.cover, this.areas, this.styles, this.gotoUrl, this.desc, this.pubtime, this.mediaMode, this.mediaScore, this.indexShow);
  factory NetworkMediaFtSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkMediaFtSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int mediaId;
 final  HtmlTitle title;
 final  String orgTitle;
 final  int mediaType;
 final  String cv;
 final  String staff;
 final  int seasonId;
 final  bool isAvid;
 final  String hitEpids;
 final  int seasonType;
 final  String seasonTypeName;
 final  String url;
 final  String buttonText;
 final  int isSelection;
 final  String cover;
 final  String areas;
 final  String styles;
 final  String gotoUrl;
 final  String desc;
 final  int pubtime;
 final  int mediaMode;
 final  NetworkMediaScore mediaScore;
 final  String indexShow;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkMediaFtSearchResultCopyWith<NetworkMediaFtSearchResult> get copyWith => _$NetworkMediaFtSearchResultCopyWithImpl<NetworkMediaFtSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkMediaFtSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.orgTitle, orgTitle) || other.orgTitle == orgTitle)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.cv, cv) || other.cv == cv)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.isAvid, isAvid) || other.isAvid == isAvid)&&(identical(other.hitEpids, hitEpids) || other.hitEpids == hitEpids)&&(identical(other.seasonType, seasonType) || other.seasonType == seasonType)&&(identical(other.seasonTypeName, seasonTypeName) || other.seasonTypeName == seasonTypeName)&&(identical(other.url, url) || other.url == url)&&(identical(other.buttonText, buttonText) || other.buttonText == buttonText)&&(identical(other.isSelection, isSelection) || other.isSelection == isSelection)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.areas, areas) || other.areas == areas)&&(identical(other.styles, styles) || other.styles == styles)&&(identical(other.gotoUrl, gotoUrl) || other.gotoUrl == gotoUrl)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.pubtime, pubtime) || other.pubtime == pubtime)&&(identical(other.mediaMode, mediaMode) || other.mediaMode == mediaMode)&&(identical(other.mediaScore, mediaScore) || other.mediaScore == mediaScore)&&(identical(other.indexShow, indexShow) || other.indexShow == indexShow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,mediaId,title,orgTitle,mediaType,cv,staff,seasonId,isAvid,hitEpids,seasonType,seasonTypeName,url,buttonText,isSelection,cover,areas,styles,gotoUrl,desc,pubtime,mediaMode,mediaScore,indexShow]);

@override
String toString() {
  return 'NetworkSearchResult.mediaFt(type: $type, mediaId: $mediaId, title: $title, orgTitle: $orgTitle, mediaType: $mediaType, cv: $cv, staff: $staff, seasonId: $seasonId, isAvid: $isAvid, hitEpids: $hitEpids, seasonType: $seasonType, seasonTypeName: $seasonTypeName, url: $url, buttonText: $buttonText, isSelection: $isSelection, cover: $cover, areas: $areas, styles: $styles, gotoUrl: $gotoUrl, desc: $desc, pubtime: $pubtime, mediaMode: $mediaMode, mediaScore: $mediaScore, indexShow: $indexShow)';
}


}

/// @nodoc
abstract mixin class $NetworkMediaFtSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkMediaFtSearchResultCopyWith(NetworkMediaFtSearchResult value, $Res Function(NetworkMediaFtSearchResult) _then) = _$NetworkMediaFtSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int mediaId, HtmlTitle title, String orgTitle, int mediaType, String cv, String staff, int seasonId, bool isAvid, String hitEpids, int seasonType, String seasonTypeName, String url, String buttonText, int isSelection, String cover, String areas, String styles, String gotoUrl, String desc, int pubtime, int mediaMode, NetworkMediaScore mediaScore, String indexShow
});


$HtmlTitleCopyWith<$Res> get title;$NetworkMediaScoreCopyWith<$Res> get mediaScore;

}
/// @nodoc
class _$NetworkMediaFtSearchResultCopyWithImpl<$Res>
    implements $NetworkMediaFtSearchResultCopyWith<$Res> {
  _$NetworkMediaFtSearchResultCopyWithImpl(this._self, this._then);

  final NetworkMediaFtSearchResult _self;
  final $Res Function(NetworkMediaFtSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? mediaId = null,Object? title = null,Object? orgTitle = null,Object? mediaType = null,Object? cv = null,Object? staff = null,Object? seasonId = null,Object? isAvid = null,Object? hitEpids = null,Object? seasonType = null,Object? seasonTypeName = null,Object? url = null,Object? buttonText = null,Object? isSelection = null,Object? cover = null,Object? areas = null,Object? styles = null,Object? gotoUrl = null,Object? desc = null,Object? pubtime = null,Object? mediaMode = null,Object? mediaScore = null,Object? indexShow = null,}) {
  return _then(NetworkMediaFtSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as int,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as HtmlTitle,null == orgTitle ? _self.orgTitle : orgTitle // ignore: cast_nullable_to_non_nullable
as String,null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as int,null == cv ? _self.cv : cv // ignore: cast_nullable_to_non_nullable
as String,null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as String,null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,null == isAvid ? _self.isAvid : isAvid // ignore: cast_nullable_to_non_nullable
as bool,null == hitEpids ? _self.hitEpids : hitEpids // ignore: cast_nullable_to_non_nullable
as String,null == seasonType ? _self.seasonType : seasonType // ignore: cast_nullable_to_non_nullable
as int,null == seasonTypeName ? _self.seasonTypeName : seasonTypeName // ignore: cast_nullable_to_non_nullable
as String,null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,null == buttonText ? _self.buttonText : buttonText // ignore: cast_nullable_to_non_nullable
as String,null == isSelection ? _self.isSelection : isSelection // ignore: cast_nullable_to_non_nullable
as int,null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as String,null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as String,null == gotoUrl ? _self.gotoUrl : gotoUrl // ignore: cast_nullable_to_non_nullable
as String,null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,null == pubtime ? _self.pubtime : pubtime // ignore: cast_nullable_to_non_nullable
as int,null == mediaMode ? _self.mediaMode : mediaMode // ignore: cast_nullable_to_non_nullable
as int,null == mediaScore ? _self.mediaScore : mediaScore // ignore: cast_nullable_to_non_nullable
as NetworkMediaScore,null == indexShow ? _self.indexShow : indexShow // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get title {
  
  return $HtmlTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkMediaScoreCopyWith<$Res> get mediaScore {
  
  return $NetworkMediaScoreCopyWith<$Res>(_self.mediaScore, (value) {
    return _then(_self.copyWith(mediaScore: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkLiveRoomSearchResult implements NetworkSearchResult {
  const NetworkLiveRoomSearchResult(this.type, this.area, this.attentions, this.cateName, this.cover, this.isLiveRoomInline, this.liveStatus, this.liveTime, this.online, this.rankIndex, this.rankOffset, this.roomid, this.shortId, this.style, this.tags, this.title, this.uface, this.uid, this.uname, this.userCover);
  factory NetworkLiveRoomSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkLiveRoomSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int area;
 final  int attentions;
 final  String cateName;
 final  String cover;
 final  int isLiveRoomInline;
 final  int liveStatus;
 final  String liveTime;
 final  int online;
 final  int rankIndex;
 final  int rankOffset;
 final  int roomid;
 final  int shortId;
 final  int style;
 final  String tags;
 final  HtmlTitle title;
 final  String uface;
 final  int uid;
 final  String uname;
 final  String userCover;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkLiveRoomSearchResultCopyWith<NetworkLiveRoomSearchResult> get copyWith => _$NetworkLiveRoomSearchResultCopyWithImpl<NetworkLiveRoomSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkLiveRoomSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.area, area) || other.area == area)&&(identical(other.attentions, attentions) || other.attentions == attentions)&&(identical(other.cateName, cateName) || other.cateName == cateName)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.isLiveRoomInline, isLiveRoomInline) || other.isLiveRoomInline == isLiveRoomInline)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus)&&(identical(other.liveTime, liveTime) || other.liveTime == liveTime)&&(identical(other.online, online) || other.online == online)&&(identical(other.rankIndex, rankIndex) || other.rankIndex == rankIndex)&&(identical(other.rankOffset, rankOffset) || other.rankOffset == rankOffset)&&(identical(other.roomid, roomid) || other.roomid == roomid)&&(identical(other.shortId, shortId) || other.shortId == shortId)&&(identical(other.style, style) || other.style == style)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.title, title) || other.title == title)&&(identical(other.uface, uface) || other.uface == uface)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.userCover, userCover) || other.userCover == userCover));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,area,attentions,cateName,cover,isLiveRoomInline,liveStatus,liveTime,online,rankIndex,rankOffset,roomid,shortId,style,tags,title,uface,uid,uname,userCover]);

@override
String toString() {
  return 'NetworkSearchResult.liveRoom(type: $type, area: $area, attentions: $attentions, cateName: $cateName, cover: $cover, isLiveRoomInline: $isLiveRoomInline, liveStatus: $liveStatus, liveTime: $liveTime, online: $online, rankIndex: $rankIndex, rankOffset: $rankOffset, roomid: $roomid, shortId: $shortId, style: $style, tags: $tags, title: $title, uface: $uface, uid: $uid, uname: $uname, userCover: $userCover)';
}


}

/// @nodoc
abstract mixin class $NetworkLiveRoomSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkLiveRoomSearchResultCopyWith(NetworkLiveRoomSearchResult value, $Res Function(NetworkLiveRoomSearchResult) _then) = _$NetworkLiveRoomSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int area, int attentions, String cateName, String cover, int isLiveRoomInline, int liveStatus, String liveTime, int online, int rankIndex, int rankOffset, int roomid, int shortId, int style, String tags, HtmlTitle title, String uface, int uid, String uname, String userCover
});


$HtmlTitleCopyWith<$Res> get title;

}
/// @nodoc
class _$NetworkLiveRoomSearchResultCopyWithImpl<$Res>
    implements $NetworkLiveRoomSearchResultCopyWith<$Res> {
  _$NetworkLiveRoomSearchResultCopyWithImpl(this._self, this._then);

  final NetworkLiveRoomSearchResult _self;
  final $Res Function(NetworkLiveRoomSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? area = null,Object? attentions = null,Object? cateName = null,Object? cover = null,Object? isLiveRoomInline = null,Object? liveStatus = null,Object? liveTime = null,Object? online = null,Object? rankIndex = null,Object? rankOffset = null,Object? roomid = null,Object? shortId = null,Object? style = null,Object? tags = null,Object? title = null,Object? uface = null,Object? uid = null,Object? uname = null,Object? userCover = null,}) {
  return _then(NetworkLiveRoomSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as int,null == attentions ? _self.attentions : attentions // ignore: cast_nullable_to_non_nullable
as int,null == cateName ? _self.cateName : cateName // ignore: cast_nullable_to_non_nullable
as String,null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,null == isLiveRoomInline ? _self.isLiveRoomInline : isLiveRoomInline // ignore: cast_nullable_to_non_nullable
as int,null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as int,null == liveTime ? _self.liveTime : liveTime // ignore: cast_nullable_to_non_nullable
as String,null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as int,null == rankIndex ? _self.rankIndex : rankIndex // ignore: cast_nullable_to_non_nullable
as int,null == rankOffset ? _self.rankOffset : rankOffset // ignore: cast_nullable_to_non_nullable
as int,null == roomid ? _self.roomid : roomid // ignore: cast_nullable_to_non_nullable
as int,null == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as int,null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as int,null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as HtmlTitle,null == uface ? _self.uface : uface // ignore: cast_nullable_to_non_nullable
as String,null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,null == userCover ? _self.userCover : userCover // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get title {
  
  return $HtmlTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkLiveUserSearchResult implements NetworkSearchResult {
  const NetworkLiveUserSearchResult(this.type, this.area, this.areaV2Id, this.attentions, this.cateName, this.id, this.isLive, this.liveStatus, this.liveTime, this.rankIndex, this.rankOffset, this.roomid, this.tags, this.uface, this.uid, this.uname);
  factory NetworkLiveUserSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkLiveUserSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int area;
 final  int areaV2Id;
 final  int attentions;
 final  String cateName;
 final  int id;
 final  bool isLive;
 final  int liveStatus;
 final  String liveTime;
 final  int rankIndex;
 final  int rankOffset;
 final  int roomid;
 final  String tags;
 final  String uface;
 final  int uid;
 final  HtmlTitle uname;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkLiveUserSearchResultCopyWith<NetworkLiveUserSearchResult> get copyWith => _$NetworkLiveUserSearchResultCopyWithImpl<NetworkLiveUserSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkLiveUserSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.area, area) || other.area == area)&&(identical(other.areaV2Id, areaV2Id) || other.areaV2Id == areaV2Id)&&(identical(other.attentions, attentions) || other.attentions == attentions)&&(identical(other.cateName, cateName) || other.cateName == cateName)&&(identical(other.id, id) || other.id == id)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus)&&(identical(other.liveTime, liveTime) || other.liveTime == liveTime)&&(identical(other.rankIndex, rankIndex) || other.rankIndex == rankIndex)&&(identical(other.rankOffset, rankOffset) || other.rankOffset == rankOffset)&&(identical(other.roomid, roomid) || other.roomid == roomid)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.uface, uface) || other.uface == uface)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.uname, uname) || other.uname == uname));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,area,areaV2Id,attentions,cateName,id,isLive,liveStatus,liveTime,rankIndex,rankOffset,roomid,tags,uface,uid,uname);

@override
String toString() {
  return 'NetworkSearchResult.liveUser(type: $type, area: $area, areaV2Id: $areaV2Id, attentions: $attentions, cateName: $cateName, id: $id, isLive: $isLive, liveStatus: $liveStatus, liveTime: $liveTime, rankIndex: $rankIndex, rankOffset: $rankOffset, roomid: $roomid, tags: $tags, uface: $uface, uid: $uid, uname: $uname)';
}


}

/// @nodoc
abstract mixin class $NetworkLiveUserSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkLiveUserSearchResultCopyWith(NetworkLiveUserSearchResult value, $Res Function(NetworkLiveUserSearchResult) _then) = _$NetworkLiveUserSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int area, int areaV2Id, int attentions, String cateName, int id, bool isLive, int liveStatus, String liveTime, int rankIndex, int rankOffset, int roomid, String tags, String uface, int uid, HtmlTitle uname
});


$HtmlTitleCopyWith<$Res> get uname;

}
/// @nodoc
class _$NetworkLiveUserSearchResultCopyWithImpl<$Res>
    implements $NetworkLiveUserSearchResultCopyWith<$Res> {
  _$NetworkLiveUserSearchResultCopyWithImpl(this._self, this._then);

  final NetworkLiveUserSearchResult _self;
  final $Res Function(NetworkLiveUserSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? area = null,Object? areaV2Id = null,Object? attentions = null,Object? cateName = null,Object? id = null,Object? isLive = null,Object? liveStatus = null,Object? liveTime = null,Object? rankIndex = null,Object? rankOffset = null,Object? roomid = null,Object? tags = null,Object? uface = null,Object? uid = null,Object? uname = null,}) {
  return _then(NetworkLiveUserSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as int,null == areaV2Id ? _self.areaV2Id : areaV2Id // ignore: cast_nullable_to_non_nullable
as int,null == attentions ? _self.attentions : attentions // ignore: cast_nullable_to_non_nullable
as int,null == cateName ? _self.cateName : cateName // ignore: cast_nullable_to_non_nullable
as String,null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as int,null == liveTime ? _self.liveTime : liveTime // ignore: cast_nullable_to_non_nullable
as String,null == rankIndex ? _self.rankIndex : rankIndex // ignore: cast_nullable_to_non_nullable
as int,null == rankOffset ? _self.rankOffset : rankOffset // ignore: cast_nullable_to_non_nullable
as int,null == roomid ? _self.roomid : roomid // ignore: cast_nullable_to_non_nullable
as int,null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,null == uface ? _self.uface : uface // ignore: cast_nullable_to_non_nullable
as String,null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as HtmlTitle,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get uname {
  
  return $HtmlTitleCopyWith<$Res>(_self.uname, (value) {
    return _then(_self.copyWith(uname: value));
  });
}
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class NetworkVideoSearchResult implements NetworkSearchResult {
  const NetworkVideoSearchResult(this.type, this.id, this.author, this.mid, this.typeid, this.typename, this.arcurl, this.aid, this.bvid, this.title, this.description, this.pic, this.play, this.favorites, this.tag, this.review, this.pubdate, this.senddate, this.duration, this.badgepay, this.isUnionVideo, this.like, this.upic, this.corner, this.cover, this.desc, this.url, this.danmaku);
  factory NetworkVideoSearchResult.fromJson(Map<String, dynamic> json) => _$NetworkVideoSearchResultFromJson(json);

@override final  SearchResultType type;
 final  int id;
 final  String author;
 final  int mid;
 final  String typeid;
 final  String typename;
 final  String arcurl;
 final  int aid;
 final  String bvid;
 final  HtmlTitle title;
 final  String description;
 final  String pic;
 final  int play;
 final  int favorites;
 final  String tag;
 final  int review;
 final  int pubdate;
 final  int senddate;
 final  String duration;
 final  bool badgepay;
 final  int isUnionVideo;
 final  int like;
 final  String upic;
 final  String corner;
 final  String cover;
 final  String desc;
 final  String url;
 final  int danmaku;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkVideoSearchResultCopyWith<NetworkVideoSearchResult> get copyWith => _$NetworkVideoSearchResultCopyWithImpl<NetworkVideoSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkVideoSearchResult&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.typeid, typeid) || other.typeid == typeid)&&(identical(other.typename, typename) || other.typename == typename)&&(identical(other.arcurl, arcurl) || other.arcurl == arcurl)&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.pic, pic) || other.pic == pic)&&(identical(other.play, play) || other.play == play)&&(identical(other.favorites, favorites) || other.favorites == favorites)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.review, review) || other.review == review)&&(identical(other.pubdate, pubdate) || other.pubdate == pubdate)&&(identical(other.senddate, senddate) || other.senddate == senddate)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.badgepay, badgepay) || other.badgepay == badgepay)&&(identical(other.isUnionVideo, isUnionVideo) || other.isUnionVideo == isUnionVideo)&&(identical(other.like, like) || other.like == like)&&(identical(other.upic, upic) || other.upic == upic)&&(identical(other.corner, corner) || other.corner == corner)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.url, url) || other.url == url)&&(identical(other.danmaku, danmaku) || other.danmaku == danmaku));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,type,id,author,mid,typeid,typename,arcurl,aid,bvid,title,description,pic,play,favorites,tag,review,pubdate,senddate,duration,badgepay,isUnionVideo,like,upic,corner,cover,desc,url,danmaku]);

@override
String toString() {
  return 'NetworkSearchResult.video(type: $type, id: $id, author: $author, mid: $mid, typeid: $typeid, typename: $typename, arcurl: $arcurl, aid: $aid, bvid: $bvid, title: $title, description: $description, pic: $pic, play: $play, favorites: $favorites, tag: $tag, review: $review, pubdate: $pubdate, senddate: $senddate, duration: $duration, badgepay: $badgepay, isUnionVideo: $isUnionVideo, like: $like, upic: $upic, corner: $corner, cover: $cover, desc: $desc, url: $url, danmaku: $danmaku)';
}


}

/// @nodoc
abstract mixin class $NetworkVideoSearchResultCopyWith<$Res> implements $NetworkSearchResultCopyWith<$Res> {
  factory $NetworkVideoSearchResultCopyWith(NetworkVideoSearchResult value, $Res Function(NetworkVideoSearchResult) _then) = _$NetworkVideoSearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type, int id, String author, int mid, String typeid, String typename, String arcurl, int aid, String bvid, HtmlTitle title, String description, String pic, int play, int favorites, String tag, int review, int pubdate, int senddate, String duration, bool badgepay, int isUnionVideo, int like, String upic, String corner, String cover, String desc, String url, int danmaku
});


$HtmlTitleCopyWith<$Res> get title;

}
/// @nodoc
class _$NetworkVideoSearchResultCopyWithImpl<$Res>
    implements $NetworkVideoSearchResultCopyWith<$Res> {
  _$NetworkVideoSearchResultCopyWithImpl(this._self, this._then);

  final NetworkVideoSearchResult _self;
  final $Res Function(NetworkVideoSearchResult) _then;

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = null,Object? author = null,Object? mid = null,Object? typeid = null,Object? typename = null,Object? arcurl = null,Object? aid = null,Object? bvid = null,Object? title = null,Object? description = null,Object? pic = null,Object? play = null,Object? favorites = null,Object? tag = null,Object? review = null,Object? pubdate = null,Object? senddate = null,Object? duration = null,Object? badgepay = null,Object? isUnionVideo = null,Object? like = null,Object? upic = null,Object? corner = null,Object? cover = null,Object? desc = null,Object? url = null,Object? danmaku = null,}) {
  return _then(NetworkVideoSearchResult(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,null == typeid ? _self.typeid : typeid // ignore: cast_nullable_to_non_nullable
as String,null == typename ? _self.typename : typename // ignore: cast_nullable_to_non_nullable
as String,null == arcurl ? _self.arcurl : arcurl // ignore: cast_nullable_to_non_nullable
as String,null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as HtmlTitle,null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,null == pic ? _self.pic : pic // ignore: cast_nullable_to_non_nullable
as String,null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as int,null == favorites ? _self.favorites : favorites // ignore: cast_nullable_to_non_nullable
as int,null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as int,null == pubdate ? _self.pubdate : pubdate // ignore: cast_nullable_to_non_nullable
as int,null == senddate ? _self.senddate : senddate // ignore: cast_nullable_to_non_nullable
as int,null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,null == badgepay ? _self.badgepay : badgepay // ignore: cast_nullable_to_non_nullable
as bool,null == isUnionVideo ? _self.isUnionVideo : isUnionVideo // ignore: cast_nullable_to_non_nullable
as int,null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as int,null == upic ? _self.upic : upic // ignore: cast_nullable_to_non_nullable
as String,null == corner ? _self.corner : corner // ignore: cast_nullable_to_non_nullable
as String,null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,null == danmaku ? _self.danmaku : danmaku // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of NetworkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<$Res> get title {
  
  return $HtmlTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

/// @nodoc
mixin _$HtmlTitle {

 String get text;
/// Create a copy of HtmlTitle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HtmlTitleCopyWith<HtmlTitle> get copyWith => _$HtmlTitleCopyWithImpl<HtmlTitle>(this as HtmlTitle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HtmlTitle&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'HtmlTitle(text: $text)';
}


}

/// @nodoc
abstract mixin class $HtmlTitleCopyWith<$Res>  {
  factory $HtmlTitleCopyWith(HtmlTitle value, $Res Function(HtmlTitle) _then) = _$HtmlTitleCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$HtmlTitleCopyWithImpl<$Res>
    implements $HtmlTitleCopyWith<$Res> {
  _$HtmlTitleCopyWithImpl(this._self, this._then);

  final HtmlTitle _self;
  final $Res Function(HtmlTitle) _then;

/// Create a copy of HtmlTitle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



/// @nodoc


class _HtmlTitle extends HtmlTitle {
  const _HtmlTitle(this.text): super._();
  

@override final  String text;

/// Create a copy of HtmlTitle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HtmlTitleCopyWith<_HtmlTitle> get copyWith => __$HtmlTitleCopyWithImpl<_HtmlTitle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HtmlTitle&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'HtmlTitle(text: $text)';
}


}

/// @nodoc
abstract mixin class _$HtmlTitleCopyWith<$Res> implements $HtmlTitleCopyWith<$Res> {
  factory _$HtmlTitleCopyWith(_HtmlTitle value, $Res Function(_HtmlTitle) _then) = __$HtmlTitleCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class __$HtmlTitleCopyWithImpl<$Res>
    implements _$HtmlTitleCopyWith<$Res> {
  __$HtmlTitleCopyWithImpl(this._self, this._then);

  final _HtmlTitle _self;
  final $Res Function(_HtmlTitle) _then;

/// Create a copy of HtmlTitle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_HtmlTitle(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


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

@JsonSerializable(fieldRename: FieldRename.snake)
class _NetworkMediaScore implements NetworkMediaScore {
  const _NetworkMediaScore(this.score, this.userCount);
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
null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,null == userCount ? _self.userCount : userCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NetworkBiliUserRes {

 int get aid; String get bvid; String get title; int get pubdate; String get arcurl; String get pic; String get play; int get dm; int get coin; int get fav; String get desc; String get duration; int get isPay; int get isUnionVideo; int get isChargeVideo; int get vt; int get enableVt; String get vtDisplay;
/// Create a copy of NetworkBiliUserRes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkBiliUserResCopyWith<NetworkBiliUserRes> get copyWith => _$NetworkBiliUserResCopyWithImpl<NetworkBiliUserRes>(this as NetworkBiliUserRes, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkBiliUserRes&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.pubdate, pubdate) || other.pubdate == pubdate)&&(identical(other.arcurl, arcurl) || other.arcurl == arcurl)&&(identical(other.pic, pic) || other.pic == pic)&&(identical(other.play, play) || other.play == play)&&(identical(other.dm, dm) || other.dm == dm)&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.fav, fav) || other.fav == fav)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isPay, isPay) || other.isPay == isPay)&&(identical(other.isUnionVideo, isUnionVideo) || other.isUnionVideo == isUnionVideo)&&(identical(other.isChargeVideo, isChargeVideo) || other.isChargeVideo == isChargeVideo)&&(identical(other.vt, vt) || other.vt == vt)&&(identical(other.enableVt, enableVt) || other.enableVt == enableVt)&&(identical(other.vtDisplay, vtDisplay) || other.vtDisplay == vtDisplay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aid,bvid,title,pubdate,arcurl,pic,play,dm,coin,fav,desc,duration,isPay,isUnionVideo,isChargeVideo,vt,enableVt,vtDisplay);

@override
String toString() {
  return 'NetworkBiliUserRes(aid: $aid, bvid: $bvid, title: $title, pubdate: $pubdate, arcurl: $arcurl, pic: $pic, play: $play, dm: $dm, coin: $coin, fav: $fav, desc: $desc, duration: $duration, isPay: $isPay, isUnionVideo: $isUnionVideo, isChargeVideo: $isChargeVideo, vt: $vt, enableVt: $enableVt, vtDisplay: $vtDisplay)';
}


}

/// @nodoc
abstract mixin class $NetworkBiliUserResCopyWith<$Res>  {
  factory $NetworkBiliUserResCopyWith(NetworkBiliUserRes value, $Res Function(NetworkBiliUserRes) _then) = _$NetworkBiliUserResCopyWithImpl;
@useResult
$Res call({
 int aid, String bvid, String title, int pubdate, String arcurl, String pic, String play, int dm, int coin, int fav, String desc, String duration, int isPay, int isUnionVideo, int isChargeVideo, int vt, int enableVt, String vtDisplay
});




}
/// @nodoc
class _$NetworkBiliUserResCopyWithImpl<$Res>
    implements $NetworkBiliUserResCopyWith<$Res> {
  _$NetworkBiliUserResCopyWithImpl(this._self, this._then);

  final NetworkBiliUserRes _self;
  final $Res Function(NetworkBiliUserRes) _then;

/// Create a copy of NetworkBiliUserRes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? pubdate = null,Object? arcurl = null,Object? pic = null,Object? play = null,Object? dm = null,Object? coin = null,Object? fav = null,Object? desc = null,Object? duration = null,Object? isPay = null,Object? isUnionVideo = null,Object? isChargeVideo = null,Object? vt = null,Object? enableVt = null,Object? vtDisplay = null,}) {
  return _then(_self.copyWith(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,pubdate: null == pubdate ? _self.pubdate : pubdate // ignore: cast_nullable_to_non_nullable
as int,arcurl: null == arcurl ? _self.arcurl : arcurl // ignore: cast_nullable_to_non_nullable
as String,pic: null == pic ? _self.pic : pic // ignore: cast_nullable_to_non_nullable
as String,play: null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as String,dm: null == dm ? _self.dm : dm // ignore: cast_nullable_to_non_nullable
as int,coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as int,fav: null == fav ? _self.fav : fav // ignore: cast_nullable_to_non_nullable
as int,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,isPay: null == isPay ? _self.isPay : isPay // ignore: cast_nullable_to_non_nullable
as int,isUnionVideo: null == isUnionVideo ? _self.isUnionVideo : isUnionVideo // ignore: cast_nullable_to_non_nullable
as int,isChargeVideo: null == isChargeVideo ? _self.isChargeVideo : isChargeVideo // ignore: cast_nullable_to_non_nullable
as int,vt: null == vt ? _self.vt : vt // ignore: cast_nullable_to_non_nullable
as int,enableVt: null == enableVt ? _self.enableVt : enableVt // ignore: cast_nullable_to_non_nullable
as int,vtDisplay: null == vtDisplay ? _self.vtDisplay : vtDisplay // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _NetworkBiliUserRes implements NetworkBiliUserRes {
  const _NetworkBiliUserRes(this.aid, this.bvid, this.title, this.pubdate, this.arcurl, this.pic, this.play, this.dm, this.coin, this.fav, this.desc, this.duration, this.isPay, this.isUnionVideo, this.isChargeVideo, this.vt, this.enableVt, this.vtDisplay);
  factory _NetworkBiliUserRes.fromJson(Map<String, dynamic> json) => _$NetworkBiliUserResFromJson(json);

@override final  int aid;
@override final  String bvid;
@override final  String title;
@override final  int pubdate;
@override final  String arcurl;
@override final  String pic;
@override final  String play;
@override final  int dm;
@override final  int coin;
@override final  int fav;
@override final  String desc;
@override final  String duration;
@override final  int isPay;
@override final  int isUnionVideo;
@override final  int isChargeVideo;
@override final  int vt;
@override final  int enableVt;
@override final  String vtDisplay;

/// Create a copy of NetworkBiliUserRes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkBiliUserResCopyWith<_NetworkBiliUserRes> get copyWith => __$NetworkBiliUserResCopyWithImpl<_NetworkBiliUserRes>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkBiliUserRes&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.pubdate, pubdate) || other.pubdate == pubdate)&&(identical(other.arcurl, arcurl) || other.arcurl == arcurl)&&(identical(other.pic, pic) || other.pic == pic)&&(identical(other.play, play) || other.play == play)&&(identical(other.dm, dm) || other.dm == dm)&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.fav, fav) || other.fav == fav)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.isPay, isPay) || other.isPay == isPay)&&(identical(other.isUnionVideo, isUnionVideo) || other.isUnionVideo == isUnionVideo)&&(identical(other.isChargeVideo, isChargeVideo) || other.isChargeVideo == isChargeVideo)&&(identical(other.vt, vt) || other.vt == vt)&&(identical(other.enableVt, enableVt) || other.enableVt == enableVt)&&(identical(other.vtDisplay, vtDisplay) || other.vtDisplay == vtDisplay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aid,bvid,title,pubdate,arcurl,pic,play,dm,coin,fav,desc,duration,isPay,isUnionVideo,isChargeVideo,vt,enableVt,vtDisplay);

@override
String toString() {
  return 'NetworkBiliUserRes(aid: $aid, bvid: $bvid, title: $title, pubdate: $pubdate, arcurl: $arcurl, pic: $pic, play: $play, dm: $dm, coin: $coin, fav: $fav, desc: $desc, duration: $duration, isPay: $isPay, isUnionVideo: $isUnionVideo, isChargeVideo: $isChargeVideo, vt: $vt, enableVt: $enableVt, vtDisplay: $vtDisplay)';
}


}

/// @nodoc
abstract mixin class _$NetworkBiliUserResCopyWith<$Res> implements $NetworkBiliUserResCopyWith<$Res> {
  factory _$NetworkBiliUserResCopyWith(_NetworkBiliUserRes value, $Res Function(_NetworkBiliUserRes) _then) = __$NetworkBiliUserResCopyWithImpl;
@override @useResult
$Res call({
 int aid, String bvid, String title, int pubdate, String arcurl, String pic, String play, int dm, int coin, int fav, String desc, String duration, int isPay, int isUnionVideo, int isChargeVideo, int vt, int enableVt, String vtDisplay
});




}
/// @nodoc
class __$NetworkBiliUserResCopyWithImpl<$Res>
    implements _$NetworkBiliUserResCopyWith<$Res> {
  __$NetworkBiliUserResCopyWithImpl(this._self, this._then);

  final _NetworkBiliUserRes _self;
  final $Res Function(_NetworkBiliUserRes) _then;

/// Create a copy of NetworkBiliUserRes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? pubdate = null,Object? arcurl = null,Object? pic = null,Object? play = null,Object? dm = null,Object? coin = null,Object? fav = null,Object? desc = null,Object? duration = null,Object? isPay = null,Object? isUnionVideo = null,Object? isChargeVideo = null,Object? vt = null,Object? enableVt = null,Object? vtDisplay = null,}) {
  return _then(_NetworkBiliUserRes(
null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,null == pubdate ? _self.pubdate : pubdate // ignore: cast_nullable_to_non_nullable
as int,null == arcurl ? _self.arcurl : arcurl // ignore: cast_nullable_to_non_nullable
as String,null == pic ? _self.pic : pic // ignore: cast_nullable_to_non_nullable
as String,null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as String,null == dm ? _self.dm : dm // ignore: cast_nullable_to_non_nullable
as int,null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as int,null == fav ? _self.fav : fav // ignore: cast_nullable_to_non_nullable
as int,null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,null == isPay ? _self.isPay : isPay // ignore: cast_nullable_to_non_nullable
as int,null == isUnionVideo ? _self.isUnionVideo : isUnionVideo // ignore: cast_nullable_to_non_nullable
as int,null == isChargeVideo ? _self.isChargeVideo : isChargeVideo // ignore: cast_nullable_to_non_nullable
as int,null == vt ? _self.vt : vt // ignore: cast_nullable_to_non_nullable
as int,null == enableVt ? _self.enableVt : enableVt // ignore: cast_nullable_to_non_nullable
as int,null == vtDisplay ? _self.vtDisplay : vtDisplay // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
