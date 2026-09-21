import 'package:model/model.dart';

import 'model/creator_profile_model.dart';
import 'model/filter_group.dart';
import 'model/live_room_model.dart';
import 'model/paged_result.dart';
import 'model/search_results.dart';
import 'model/sort_option.dart';
import 'model/video_comment_model.dart';
import 'model/video_detail_model.dart';
import 'model/video_model.dart';

/// 远程数据源基础抽象接口
///
/// 定义数据源的基本属性标识 [sourceId]。
abstract class const RemoteDataSource() {
  /// 数据源的唯一标识符（如 'bilibili', 'youtube'）
  String get sourceId;
}

/// 具备搜索功能的远程数据源基类
abstract class const SearchRemoteDataSource() extends RemoteDataSource {
  /// 当前数据源支持的筛选条件列表
  List<FilterGroup> get filters => const [];

  /// 当前数据源支持的排序选项列表
  List<SortOption> get sortOptions => const [];
}

/// 综合搜索远程数据源能力接口
abstract class const AggregateSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 执行综合搜索并返回聚合搜索结果页面
  Future<Result<AggregateSearchPage>> searchAll(String query, {int? pageKey});
}

/// UP主/创作者搜索远程数据源能力接口
abstract class const CreatorProfileSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索创作者个人信息
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  });
}

/// 直播间搜索远程数据源能力接口
abstract class const LiveRoomSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索直播间信息
  Future<Result<Page<LiveRoomModel>>> searchLiveRoom(
    String query, {
    int? pageKey,
  });
}

/// 视频搜索远程数据源能力接口
abstract class const VideoSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索视频
  Future<Result<Page<VideoModel>>> searchVideo(String query, {int? pageKey});
}

/// 搜索联想/建议远程数据源能力接口
abstract class const SearchSuggestRemoteDataSource() extends RemoteDataSource {
  /// 获取搜索关键词补全/联想建议列表
  Future<Result<List<String>>> getSuggests(String query);
}

/// 视频详情及互动可选能力接口
abstract class const VideoDetailRemoteDataSource() extends RemoteDataSource {
  /// 获取指定 ID 视频的详细信息
  Future<Result<VideoDetail>> getVideoDetail(String id);

  /// 切换点赞状态
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.ok(!isLiked);

  /// 切换收藏状态
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.ok(!isFavorited);

  /// 切换关注创作者状态
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.ok(!isSubscribed);
}

/// 视频评论可选能力接口
abstract class const VideoCommentRemoteDataSource() extends RemoteDataSource {
  /// 分页获取指定视频的评论列表
  Future<Result<Page<VideoComment>>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  });
}

/// 推荐Feed/流数据源泛型能力接口
abstract class const FeedRemoteDataSource<T>() extends RemoteDataSource {
  /// Feed 流标识
  String get id;

  /// Feed 流标题
  String get title;

  /// 分页拉取 Feed 列表数据
  Future<Result<Page<T>>> fetchFeed({int? pageKey});
}

/// 视频推荐 Feed 数据源接口
abstract class const VideoFeedRemoteDataSource()
    extends FeedRemoteDataSource<VideoModel> {}

/// 直播推荐 Feed 数据源接口
abstract class const LiveRoomFeedRemoteDataSource()
    extends FeedRemoteDataSource<LiveRoomModel> {}
