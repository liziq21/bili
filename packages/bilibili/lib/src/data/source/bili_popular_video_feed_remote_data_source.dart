import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/video_model.dart';
import 'bili_remote_data_source.dart';

final class const BiliPopularVideoFeedRemoteDataSource({
  required final NetworkBiliFeedDataSource _network,
}) extends VideoFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'popular';

  @override
  String get title => '热门视频';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) {
    final page = pageKey ?? 1;
    return Future.sync(() => _network.getPopular(page: page, pageSize: 20))
        .then(
          (response) => Page<VideoModel>(
            number: page,
            totalPages: response.data.noMore ? page : page + 1,
            data: response.data.list.map((video) => video.asModel()).toList(),
          ),
        )
        .toResult();
  }
}
