import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import 'bili_remote_data_source.dart';

final class const BiliRankingVideoFeedRemoteDataSource({
  required final NetworkBiliFeedDataSource _network,
}) extends VideoFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'ranking';

  @override
  String get title => '排行榜';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) {
    return Future.sync(_network.getRanking)
        .then(
          (response) => Page<VideoModel>(
            number: 1,
            totalPages: 1,
            data: response.data.list.map((video) => video.asModel()).toList(),
          ),
        )
        .toResult();
  }
}

extension NetworkBiliRankingVideoX on NetworkBiliRankingVideo {
  VideoModel asModel() => VideoModel(
    id: bvid,
    title: title ?? bvid,
    url: 'https://www.bilibili.com/video/$bvid',
    thumbnailUrl: _normalizeBiliUrl(pic),
    viewCount: stat?.view,
    uploadDate: pubdate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(pubdate! * 1000),
    duration: duration,
    creatorProfileName: owner?.name,
    creatorProfileId: owner?.mid?.toString(),
  );
}

String? _normalizeBiliUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  return value.startsWith('http://') ? 'https://${value.substring(7)}' : value;
}
