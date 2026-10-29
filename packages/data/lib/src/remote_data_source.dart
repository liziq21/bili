import 'package:model/model.dart';

import 'search_query.dart';

import 'model/creator_profile_model.dart';
import 'model/danmaku.dart';
import 'model/filter_group.dart';
import 'model/live_room_model.dart';
import 'model/media_stream.dart';
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
  Future<Result<AggregateSearchPage, Exception>> searchAll(
    String query, {
    int? pageKey,
  });
}

/// UP主/创作者搜索远程数据源能力接口
abstract class const CreatorProfileSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索创作者个人信息
  Future<Result<Page<CreatorProfile>, Exception>> searchCreatorProfile(
    String query, {
    int? pageKey,
  });
}

/// 直播间搜索远程数据源能力接口
abstract class const LiveRoomSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索直播间信息
  Future<Result<Page<LiveRoomModel>, Exception>> searchLiveRoom(
    String query, {
    int? pageKey,
  });
}

/// 视频搜索远程数据源能力接口
abstract class const VideoSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  /// 分页搜索视频
  ///
  /// The source owns the interpretation of the neutral [SearchQuery] filters
  /// and sort option. Unsupported options are not an app-layer concern.
  Future<Result<Page<VideoModel>, Exception>> searchVideo(SearchQuery query);
}

/// 搜索联想/建议远程数据源能力接口
abstract class const SearchSuggestRemoteDataSource() extends RemoteDataSource {
  /// 获取搜索关键词补全/联想建议列表
  Future<Result<List<String>, Exception>> getSuggests(String query);
}

/// 视频详情及互动可选能力接口
abstract class const VideoDetailRemoteDataSource() extends RemoteDataSource {
  /// 获取指定 ID 视频的详细信息
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id);

  /// 切换点赞状态
  ///
  /// 默认实现报失败而非回一个看似成功的翻转值：本能力是可选的，数据源未实现时
  /// 「操作已生效」是假的，调用方（VideoBloc）会据此回滚乐观更新并提示用户。
  /// 实现该能力的数据源覆写本方法。
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('当前数据源不支持点赞'));

  /// 切换收藏状态
  ///
  /// 覆写理由同 [toggleLike]。
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('当前数据源不支持收藏'));

  /// 切换关注创作者状态
  ///
  /// 覆写理由同 [toggleLike]。
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('当前数据源不支持关注创作者'));
}

/// 媒体流可选能力接口
///
/// 提供「把一个媒体标识解析为可播放地址」的能力。各源在此消解自身对
/// 地址、清晰度与鉴权头的差异，返回中立的 [MediaStream]；播放层不认识
/// 具体服务。
abstract class const MediaStreamRemoteDataSource() extends RemoteDataSource {
  /// 解析指定媒体的播放地址
  ///
  /// [videoId] 为该源体系内的媒体标识。[preferStreamId] 为记住的清晰度 id，
  /// 源按它精确匹配，取不到时退回 [preferHeight] 就近选取；两者都为 null 时
  /// 由源取默认档。
  Future<Result<MediaStream, Exception>> getMediaStream(
    String videoId, {
    int? preferHeight,
    int? preferStreamId,
  });
}

/// 视频评论可选能力接口
abstract class const VideoCommentRemoteDataSource() extends RemoteDataSource {
  /// 分页获取指定视频的评论列表
  Future<Result<Page<VideoComment>, Exception>> getVideoComments(
    String videoId, {
    int page = 1,
    int pageSize = 20,
  });
}

/// 视频评论回复可选能力接口。
///
/// 服务源可以独立实现评论列表和评论回复；app 只依赖这个中立能力接口，
/// 不通过具体服务源类型判断回复是否可用。
abstract class const VideoCommentRepliesRemoteDataSource()
    extends RemoteDataSource {
  /// 分页获取指定视频评论的二级回复列表
  Future<Result<Page<VideoComment>, Exception>> getVideoCommentReplies(
    String videoId,
    String rootCommentId, {
    int page = 1,
    int pageSize = 20,
  });
}

/// Timed danmaku capability.
abstract class const DanmakuRemoteDataSource() extends RemoteDataSource {
  /// Gets comments for the source-specific video identifier.
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(String videoId);
}

/// 推荐Feed/流数据源泛型能力接口
abstract class const FeedRemoteDataSource<T>() extends RemoteDataSource {
  /// Feed 流标识
  String get id;

  /// Feed 流标题
  String get title;

  /// 分页拉取 Feed 列表数据
  Future<Result<Page<T>, Exception>> fetchFeed({int? pageKey});
}

/// 视频推荐 Feed 数据源接口
abstract class const VideoFeedRemoteDataSource()
    extends FeedRemoteDataSource<VideoModel>;

/// 直播推荐 Feed 数据源接口
abstract class const LiveRoomFeedRemoteDataSource()
    extends FeedRemoteDataSource<LiveRoomModel>;
