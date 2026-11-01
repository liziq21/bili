import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/video_model.dart';
import 'bili_remote_data_source.dart';

/// B 站用户投稿视频分页桥接：`NetworkUserDataSource.getUserVideos` →
/// [UserVideosRemoteDataSource]，按新到旧（order=pubdate）分页。
final class BiliUserVideosRemoteDataSource extends UserVideosRemoteDataSource
    with BiliRemoteDataSource {
  const BiliUserVideosRemoteDataSource({required this._network});

  final NetworkUserDataSource _network;

  @override
  Future<Result<Page<VideoModel>, Exception>> fetchUserVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) {
    final mid = int.tryParse(channelId);
    if (mid == null) {
      return Future.value(
        Result.error(Exception('channelId must be an integer id: $channelId')),
      );
    }
    return _network
        .getUserVideos(
          mid: mid,
          page: page,
          pageSize: pageSize,
          order: 'pubdate',
        )
        .then((response) {
          final list = response.list;
          final items = list?.vlist ?? const <NetworkBiliUserVideoItem>[];
          final count = response.page?.count;
          final totalPages = count == null
              ? (items.length < pageSize ? page : page + 1)
              : ((count / pageSize).ceil()).clamp(page, 1 << 30);
          return Page<VideoModel>(
            number: page,
            totalPages: totalPages,
            data: items.map((item) => item.asModel()).toList(),
          );
        })
        .toResult();
  }
}
