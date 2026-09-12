import 'package:json_annotation/json_annotation.dart';

part 'network_reply_data.g.dart';

/// 评论区主列表数据响应模型 (/x/v2/reply/main 或 /x/v2/reply)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyData({
  final NetworkReplyCursor? cursor,
  final List<NetworkReplyItem>? replies,
  final NetworkReplyTop? top,
  final List<NetworkReplyItem>? topReplies,
  final NetworkReplyUpper? upper,
}) {
  factory NetworkReplyData.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyDataFromJson(json);
}

/// 游标/翻页信息模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyCursor({
  final bool? isEnd,
  final int? next,
  final int? prev,
  final int? allCount,
  final int? mode,
  final String? paginationStr,
}) {
  factory NetworkReplyCursor.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyCursorFromJson(json);
}

/// 顶置评论组合模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyTop({
  final NetworkReplyItem? admin,
  final NetworkReplyItem? upper,
  final NetworkReplyItem? vote,
}) {
  factory NetworkReplyTop.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyTopFromJson(json);
}

/// UP主自身信息结构
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyUpper({
  final int? mid,
  final String? name,
  final String? face,
}) {
  factory NetworkReplyUpper.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyUpperFromJson(json);
}

/// 对应一条评论项
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyItem({
  required final int rpid,
  required final int oid,
  required final int type,
  required final int mid,
  final int? root,
  final int? parent,
  final int? dialog,
  final int? count,
  final int? rcount,
  final int? state,
  final int? ctime,
  final int? like,
  final int? action,
  final NetworkReplyMember? member,
  final NetworkReplyContent? content,
  final List<NetworkReplyItem>? replies,
  final NetworkUpAction? upAction,
}) {
  factory NetworkReplyItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyItemFromJson(json);
}

/// 发评人成员信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyMember({
  required final String mid,
  required final String uname,
  required final String sex,
  required final String sign,
  required final String avatar,
}) {
  factory NetworkReplyMember.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyMemberFromJson(json);
}

/// 评论内容文本及富文本、表情信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyContent({
  required final String message,
  final int? plat,
  final int? device,
  final Map<String, dynamic>? emote,
}) {
  factory NetworkReplyContent.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyContentFromJson(json);
}

/// UP主的互动状态 (例如 UP主点赞/回复标志)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkUpAction({
  final bool? like,
  final bool? reply,
}) {
  factory NetworkUpAction.fromJson(Map<String, dynamic> json) =>
      _$NetworkUpActionFromJson(json);
}
