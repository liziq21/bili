import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/network_bili_user_res.dart';

part 'network_bili_user_search_result.freezed.dart';

@freezed
abstract class BiliUserSearchResult with _$BiliUserSearchResult {
  const factory BiliUserSearchResult({
    required int mid,
    required String uname,
    required String usign,
    required int fans,
    required int videos,
    required String upic,
    required int isLive,
    required List<BiliUserRes> res,
  }) = _BiliUserSearchResult;
}

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  BiliUserSearchResult asModel() => BiliUserSearchResult(
    mid: mid,
    uname: uname,
    usign: usign,
    fans: fans,
    videos: videos,
    upic: upic,
    isLive: isLive,
    res: res,
  );
}