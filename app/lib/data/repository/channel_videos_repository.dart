import 'package:data/data.dart';
import 'package:model/model.dart';

/// 频道页投稿视频分页能力。
///
/// 与订阅 Feed 的增量落库不同，频道页按用户当前查看的频道直接翻页，
/// 不产生本地持久化副作用。
abstract interface class ChannelVideosRepository() {
  Future<Result<Page<VideoModel>, Exception>> fetchVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  });
}

final class AppChannelVideosRepository(final UserVideosRemoteDataSource _remote)
    implements ChannelVideosRepository {
  @override
  Future<Result<Page<VideoModel>, Exception>> fetchVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) => _remote.fetchUserVideos(
    channelId: channelId,
    page: page,
    pageSize: pageSize,
  );
}
