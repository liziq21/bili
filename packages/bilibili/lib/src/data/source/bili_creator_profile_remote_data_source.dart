import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/creator_profile.dart';
import 'bili_remote_data_source.dart';
import 'bili_result.dart';

/// 按 mid 取创作者资料。
///
/// 走名片接口 `/x/web-interface/card`，与搜索端点分开：搜索端点与搜索页共用
/// 风控额度，一被限流资料页就整页失败；名片接口一次只取一个人，也不会因为
/// 昵称与 mid 不一致而查不到。
final class const BiliCreatorProfileRemoteDataSource({
  required final NetworkUserDataSource _network,
}) extends CreatorProfileRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<CreatorProfile, Exception>> getProfile(String id) {
    final mid = int.tryParse(id);
    if (mid == null || mid <= 0) {
      return Future.value(Result.error(Exception('Invalid creator id: $id')));
    }
    return _network
        .getUserCard(mid: mid)
        .then((it) => it.asModel())
        .toBiliResult();
  }
}
