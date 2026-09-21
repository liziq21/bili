import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/search_results.dart';
import 'bili_remote_data_source.dart';

final class const BiliRecommendVideoFeedRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends VideoFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'recommend';

  @override
  String get title => '推荐视频';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) {
    return _network
        .searchVideo('推荐', page: pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }
}

final class const BiliTop100VideoFeedRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends VideoFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'top100';

  @override
  String get title => '前 100 榜单';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) {
    return _network
        .searchVideo('热门榜单', page: pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }
}

final class const BiliHotVideoFeedRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends VideoFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'hot';

  @override
  String get title => '时下热门';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) {
    return _network
        .searchVideo('时下热门', page: pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }
}

final class const BiliRecommendLiveRoomFeedRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends LiveRoomFeedRemoteDataSource with BiliRemoteDataSource {
  @override
  String get id => 'recommend_live';

  @override
  String get title => '推荐直播';

  @override
  Future<Result<Page<LiveRoomModel>>> fetchFeed({int? pageKey}) {
    return _network
        .searchLiveRoom('直播', page: pageKey)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }
}
