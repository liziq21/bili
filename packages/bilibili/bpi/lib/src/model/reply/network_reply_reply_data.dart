import 'package:json_annotation/json_annotation.dart';
import 'network_reply_data.dart';

part 'network_reply_reply_data.g.dart';

/// 二级评论列表数据响应模型 (/x/v2/reply/reply)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyReplyData({
  final NetworkReplyPage? page,
  final NetworkReplyItem? root,
  final List<NetworkReplyItem>? replies,
  final NetworkReplyUpper? upper,
}) {
  factory NetworkReplyReplyData.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyReplyDataFromJson(json);
}

/// 简单的分页信息模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkReplyPage({
  final int? num,
  final int? size,
  final int? count,
}) {
  factory NetworkReplyPage.fromJson(Map<String, dynamic> json) =>
      _$NetworkReplyPageFromJson(json);
}
