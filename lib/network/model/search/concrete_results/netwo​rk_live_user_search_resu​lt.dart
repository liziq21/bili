import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../bili/search_result_type.dart';
import '../common/html_title.dart';

part 'network_live_user_search_result.freezed.dart';
part 'network_live_user_search_result.g.dart';

@Freezed
class NetworkLiveUserSearchResult with _$NetworkLiveUserSearchResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkLiveUserSearchResult({
    required int area,
    required int areaV2Id,
    required int attentions,
    required String cateName,
    required int id,
    required bool isLive,
    required int liveStatus,
    required String liveTime,
    required int rankIndex,
    required int rankOffset,
    required int roomid,
    required String tags,
    required String uface,
    required int uid,
    required HtmlTitle uname,
  }) = _NetworkLiveUserSearchResult;

  factory NetworkLiveUserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveUserSearchResultFromJson(json);
}