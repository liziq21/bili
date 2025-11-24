import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:html/parser.dart' show parse;

import 'package:f_biuli/bili/search_result_type.dart';
import 'package:f_biuli/network/model/user/network_user_official_verify.dart';

part 'network_search_result.freezed.dart';
part 'network_search_result.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class NetworkSearchResult with _$NetworkSearchResult {

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.article(
    SearchResultType type,
    int categoryId,
    String categoryName,
    String commentUrl,
    String desc,
    int id,
    List<String> imageUrls,
    int isComment,
    bool isFold,
    bool isRk1,
    int like,
    int mid,
    int pubTime,
    int rankIndex,
    int rankOffset,
    int reply,
    int spreadId,
    int subType,
    int templateId,
    HtmlTitle title,
    String version,
    int view,
  ) = NetworkArticleSearchResult;
  
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.biliUser(
    SearchResultType type,
    int mid,
    String uname,
    String usign,
    int fans,
    int videos,
    String upic,
    int faceNft,
    int faceNftType,
    String verifyInfo,
    int level,
    int gender,
    int isUpuser,
    int isLive,
    int roomId,
    List<NetworkBiliUserRes> res,
    NetworkUserOfficialVerify officialVerify,
    int isSeniorMember,
  ) = NetworkBiliUserSearchResult;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.mediaBangumi(
    SearchResultType type,
    int mediaId,
    HtmlTitle title,
    String orgTitle,
    int mediaType,
    String cv,
    String staff,
    int seasonId,
    bool isAvid,
    String hitEpids,
    int seasonType,
    String seasonTypeName,
    String url,
    String buttonText,
    int isSelection,
    String? cover,
    String areas,
    String styles,
    String gotoUrl,
    String desc,
    int pubtime,
    int mediaMode,
    NetworkMediaScore mediaScore,
    String indexShow,
  ) = NetworkMediaBangumiSearchResult;
  
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.mediaFt(
    SearchResultType type,
    int mediaId,
    HtmlTitle title,
    String orgTitle,
    int mediaType,
    String cv,
    String staff,
    int seasonId,
    bool isAvid,
    String hitEpids,
    int seasonType,
    String seasonTypeName,
    String url,
    String buttonText,
    int isFollow,
    String cover,
    String areas,
    String styles,
    String gotoUrl,
    String desc,
    int pubtime,
    int mediaMode,
    NetworkMediaScore mediaScore,
    String indexShow,
  ) = NetworkMediaFtSearchResult;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.liveRoom(
    SearchResultType type,
    int area,
    int attentions,
    String cateName,
    String cover,
    int isLiveRoomInline,
    int liveStatus,
    String liveTime,
    int online,
    int rankIndex,
    int rankOffset,
    int roomid,
    int shortId,
    int style,
    String tags,
    HtmlTitle title,
    String uface,
    int uid,
    String uname,
    String userCover,
  ) = NetworkLiveRoomSearchResult;
  
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.liveUser(
    SearchResultType type,
    int area,
    int areaV2Id,
    int attentions,
    String cateName,
    int id,
    bool isLive,
    int liveStatus,
    String liveTime,
    int rankIndex,
    int rankOffset,
    int roomid,
    String tags,
    String uface,
    int uid,
    HtmlTitle uname,
  ) = NetworkLiveUserSearchResult;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.video(
    SearchResultType type,
    int id,
    String author,
    int mid,
    String typeid,
    String typename,
    String arcurl,
    int aid,
    String bvid,
    HtmlTitle title,
    String description,
    String pic,
    int play,
    int favorites,
    String tag,
    int review,
    int pubdate,
    int senddate,
    String duration,
    bool badgepay,
    int isUnionVideo,
    int like,
    String upic,
    String corner,
    String cover,
    String desc,
    String url,
    int danmaku,
  ) = NetworkVideoSearchResult;

  factory NetworkSearchResult.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchResultFromJson(json);
}

@freezed
abstract class HtmlTitle with _$HtmlTitle {
  const factory HtmlTitle(String text) = _HtmlTitle;
  
  factory HtmlTitle.fromJson(String title) => HtmlTitle(title);
  
  get title => parse(text).body?.text ?? text;
}

@freezed
abstract class NetworkMediaScore with _$NetworkMediaScore{
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkMediaScore(
    int score,
    int userCount,
  ) = _NetworkMediaScore;
  
  factory NetworkMediaScore.fromJson(Map<String, dynamic> json)
    => _$NetworkMediaScoreFromJson(json);
}

@freezed
abstract class NetworkBiliUserRes with _$NetworkBiliUserRes {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkBiliUserRes(
    int aid,
    String bvid,
    String title,
    int pubdate,
    String arcurl,
    String pic,
    String play,
    int dm,
    int coin,
    int fav,
    String desc,
    String duration,
    int isPay,
    int isUnionVideo,
    int isChargeVideo,
    int vt,
    int enableVt,
    String vtDisplay,
  ) = _NetworkBiliUserRes;
  
  factory NetworkBiliUserRes.fromJson(Map<String, dynamic> json)
    => _$NetworkBiliUserResFromJson(json);
}

