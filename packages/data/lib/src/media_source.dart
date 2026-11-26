import 'remote_data_source.dart';

abstract class const MediaSource() {
  String get id;
  String get name;

  AggregateSearchRemoteDataSource? get aggregateSearchDataSource => null;
  CreatorProfileSearchRemoteDataSource? get creatorProfileSearchDataSource =>
      null;

  /// 按 ID 精确取创作者资料的能力（可选）。
  ///
  /// 与 [creatorProfileSearchDataSource] 分开：资料页只需要一个人，不该借道
  /// 搜索端点，后者与搜索页共用风控额度。
  CreatorProfileRemoteDataSource? get creatorProfileDataSource => null;

  LiveRoomSearchRemoteDataSource? get liveRoomSearchDataSource => null;
  VideoSearchRemoteDataSource? get videoSearchDataSource => null;
  SearchSuggestRemoteDataSource? get searchSuggestDataSource => null;

  VideoDetailRemoteDataSource? get videoDetailDataSource => null;
  VideoCommentRemoteDataSource? get videoCommentDataSource => null;
  VideoCommentRepliesRemoteDataSource? get videoCommentRepliesDataSource =>
      null;
  DanmakuRemoteDataSource? get danmakuDataSource => null;
  LiveDanmakuRemoteDataSource? get liveDanmakuDataSource => null;
  MediaStreamRemoteDataSource? get mediaStreamDataSource => null;

  /// 直播间详情与直播流地址能力（可选）。
  LiveRoomDetailRemoteDataSource? get liveRoomDetailDataSource => null;

  /// 频道投稿视频分页能力（订阅 Feed 消费用，可选）。
  UserVideosRemoteDataSource? get userVideosDataSource => null;

  /// 频道专栏文章分页能力（订阅 Feed 消费用，可选）。
  UserArticlesRemoteDataSource? get userArticlesDataSource => null;

  /// 远端播放列表内容能力（可选）。
  PlaylistContentRemoteDataSource? get playlistContentDataSource => null;

  /// 频道页合集列表能力（可选）。
  ChannelPlaylistsRemoteDataSource? get channelPlaylistsDataSource => null;

  List<VideoFeedRemoteDataSource> get videoFeedDataSources => const [];
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => const [];

  Future<void> close() async {}
}
