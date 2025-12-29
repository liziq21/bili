import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/network_bili_user_res.dart';

part 'user_search_result.freezed.dart';

@freezed
abstract class UserSearchResult with _$UserSearchResult {
  const factory UserSearchResult({
    required int mid,
    required String uname,
    required String usign,
    required int fans,
    required int videos,
    required String upic,
    required int isLive,
    required List<UserRes> res,
  }) = _UserSearchResult;
}

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  UserSearchResult asModel() => UserSearchResult(
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